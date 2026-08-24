"""Firebase Admin SDK initialisation and helpers for token verification.

`init_firebase()` is idempotent — safe to call from FastAPI startup and tests.
"""

from __future__ import annotations

import logging
from functools import lru_cache
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import auth as fb_auth
from firebase_admin import credentials

from .config import settings

logger = logging.getLogger(__name__)

_initialised: bool = False


def init_firebase() -> None:
    """Initialise the Firebase Admin SDK exactly once per process."""
    global _initialised
    if _initialised:
        return

    cred_path = Path(settings.firebase_credentials_path)
    if not cred_path.is_absolute():
        cred_path = Path(__file__).resolve().parent.parent / cred_path

    if not cred_path.exists():
        logger.warning(
            "Firebase credentials file not found at %s — token verification "
            "and Firestore admin access will fail until this is provided.",
            cred_path,
        )
        # Still mark as initialised so we don't retry every call; callers
        # should surface a clear 500 with code 'internal'.
        _initialised = True
        return

    try:
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        _initialised = True
        logger.info("Firebase Admin initialised from %s", cred_path)
    except ValueError:
        # Already initialised (e.g. tests or reloads).
        _initialised = True
    except Exception as exc:  # pragma: no cover - defensive
        logger.exception("Failed to initialise Firebase Admin: %s", exc)
        _initialised = True


def verify_id_token(id_token: str) -> dict[str, Any]:
    """Verify a Firebase ID token and return its decoded claims.

    Raises firebase_admin.auth.InvalidIdTokenError or ExpiredIdTokenError
    on bad/expired tokens. Catches verify_authentication_time errors as well.
    """
    if not _initialised:
        init_firebase()
    # Will raise if _initialised couldn't load credentials.
    decoded = fb_auth.verify_id_token(id_token)
    return decoded  # type: ignore[return-value]


@lru_cache(maxsize=1)
def firestore_client():
    """Return a cached Firestore client. Used by services to read business data."""
    if not _initialised:
        init_firebase()
    # Lazy import: firebase_admin.firestore pulls in google.cloud libs.
    from firebase_admin import firestore

    return firestore.client()
