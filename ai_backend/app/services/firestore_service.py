"""Firestore admin access with strict per-user isolation.

Every read in this module is bounded by `uid` — the Firebase UID decoded
from the ID token. Cross-user access is not possible by construction.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Iterable

from google.cloud.firestore_v1.base_query import FieldFilter

from ..firebase import firestore_client

logger = logging.getLogger(__name__)


class UnauthorizedBusinessError(Exception):
    """Raised when a businessId does not belong to the given uid."""


def _business_ref(uid: str, business_id: str):
    return (
        firestore_client()
        .collection("users")
        .document(uid)
        .collection("businesses")
        .document(business_id)
    )


def verify_business_ownership(uid: str, business_id: str) -> None:
    """Confirm that the business document exists for the given uid.

    Looks at three ownership paths (returns as soon as one confirms):

    1. ``users/{uid}/businesses/{businessId}`` subcollection — used by
       the Flutter business-setup flow that creates a sub-doc per user.
    2. ``businesses/{businessId}`` global doc, owned when one of the
       canonical fields equals the uid. The Flutter client uses
       ``userId``; older admin scripts may have written ``ownerUid`` or
       ``uid`` so we accept any of them.
    3. ``users/{uid}`` parent doc with a ``businessIds`` array that
       contains ``businessId`` — used by users who prefer a flat list.

    Raises:
        UnauthorizedBusinessError: if no path confirms ownership.
    """
    if not uid or not business_id:
        raise UnauthorizedBusinessError("Missing uid or businessId")

    checked: dict[str, str] = {}

    # Path 1: dedicated ownership subcollection.
    try:
        doc = _business_ref(uid, business_id).get()
        if doc.exists:
            return
        checked["path1_subdoc"] = "missing"
    except Exception as exc:  # pragma: no cover
        checked["path1_subdoc"] = f"error:{type(exc).__name__}"

    # Path 2: global businesses collection owned via a uid field.
    try:
        global_doc = (
            firestore_client().collection("businesses").document(business_id).get()
        )
        if global_doc.exists:
            data = global_doc.to_dict() or {}
            for key in ("userId", "ownerUid", "uid"):
                if data.get(key) == uid:
                    return
            checked["path2_match"] = (
                f"none (fields={[k for k in ('userId','ownerUid','uid') if k in data]})"
            )
        else:
            checked["path2_match"] = "global_doc_missing"
    except Exception as exc:  # pragma: no cover
        checked["path2_match"] = f"error:{type(exc).__name__}"

    # Path 3: parent user doc with a businessIds array.
    try:
        user_doc = firestore_client().collection("users").document(uid).get()
        if user_doc.exists:
            data = user_doc.to_dict() or {}
            ids = data.get("businessIds")
            if isinstance(ids, list) and business_id in ids:
                return
            checked["path3_user_doc"] = (
                f"businessIds={[x for x in ids] if isinstance(ids, list) else 'absent'}"
            )
        else:
            checked["path3_user_doc"] = "user_doc_missing"
    except Exception as exc:  # pragma: no cover
        checked["path3_user_doc"] = f"error:{type(exc).__name__}"

    logger.warning(
        "AI ownership check FAILED -> 403: uid=%s businessId=%s details=%s",
        uid,
        business_id,
        checked,
    )
    raise UnauthorizedBusinessError(
        f"Business {business_id!r} does not belong to authenticated user."
    )


def list_transactions(
    uid: str, business_id: str, since: datetime | None = None
) -> list[dict[str, Any]]:
    """Return transactions for the business, optionally filtered by date."""
    verify_business_ownership(uid, business_id)
    col = (
        firestore_client()
        .collection("businesses")
        .document(business_id)
        .collection("transactions")
    )

    if since is not None:
        col = col.where(
            filter=FieldFilter("date", ">=", _to_fs_timestamp(since))
        )

    docs = col.stream()
    rows: list[dict[str, Any]] = []
    for d in docs:
        data = d.to_dict() or {}
        data["id"] = d.id
        rows.append(data)
    return rows


def list_customers(
    uid: str, business_id: str
) -> list[dict[str, Any]]:
    verify_business_ownership(uid, business_id)
    col = (
        firestore_client()
        .collection("businesses")
        .document(business_id)
        .collection("customers")
    )
    rows: list[dict[str, Any]] = []
    for d in col.stream():
        data = d.to_dict() or {}
        data["id"] = d.id
        rows.append(data)
    return rows


def list_suppliers(
    uid: str, business_id: str
) -> list[dict[str, Any]]:
    verify_business_ownership(uid, business_id)
    col = (
        firestore_client()
        .collection("businesses")
        .document(business_id)
        .collection("suppliers")
    )
    rows: list[dict[str, Any]] = []
    for d in col.stream():
        data = d.to_dict() or {}
        data["id"] = d.id
        rows.append(data)
    return rows


def save_ai_insight(
    uid: str,
    business_id: str,
    insight: dict[str, Any],
) -> str:
    """Persist an insight under `businesses/{businessId}/ai_insights`.

    The caller must already be authorised for this business.
    """
    verify_business_ownership(uid, business_id)
    insight = dict(insight)
    insight["ownerUid"] = uid
    insight.setdefault("createdAt", _now())
    doc_ref = (
        firestore_client()
        .collection("businesses")
        .document(business_id)
        .collection("ai_insights")
        .document()
    )
    doc_ref.set(insight)
    return doc_ref.id


def _to_fs_timestamp(dt: datetime):
    try:
        from google.cloud.firestore import SERVER_TIMESTAMP  # noqa: F401
        from google.cloud.firestore_v1.types import Timestamp
    except Exception:  # pragma: no cover
        return dt
    return Timestamp.from_datetime(_ensure_utc(dt))


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _now() -> "google.cloud.firestore.SERVER_TIMESTAMP":  # type: ignore[name-defined]
    """Return a Firestore SERVER_TIMESTAMP sentinel."""
    from google.cloud.firestore import SERVER_TIMESTAMP

    return SERVER_TIMESTAMP
