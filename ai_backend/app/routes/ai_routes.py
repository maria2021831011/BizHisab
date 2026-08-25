"""FastAPI routes for the AI layer.

Both endpoints accept the same `AiRequest` body but expose different
semantics:
* POST /api/ai/chat    — open-ended Q&A (requestType="chatbot")
* POST /api/ai/insight — one of the canned analyses

Authentication: `Authorization: Bearer <Firebase ID token>`.
"""

from __future__ import annotations

import logging
import threading
import time
from collections import deque
from typing import Any, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from firebase_admin import auth as fb_auth

from ..agents import graph as ai_graph
from ..config import settings as app_settings
from ..firebase import init_firebase
from ..models import AiError, AiInsightResponse, AiRequest
from ..services import firestore_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["ai"])


# ---- Request logging helpers ---------------------------------------------


def _redact_token(auth_header: Optional[str]) -> str:
    """Return a safe representation of the Authorization header.

    Never log the actual Firebase ID token — only its presence and length.
    """
    if not auth_header:
        return "<missing>"
    parts = auth_header.split(" ", 1)
    scheme = parts[0]
    token = parts[1] if len(parts) == 2 else ""
    return f"{scheme} <redacted len={len(token)}>"


def _log_request_received(
    path: str, method: str, business_id: Optional[str], auth_header: Optional[str]
) -> None:
    logger.info(
        "AI request received method=%s path=%s businessId=%s auth=%s",
        method,
        path,
        business_id or "<none>",
        _redact_token(auth_header),
    )


# ---- Rate limiter -----------------------------------------------------------


class InMemoryRateLimiter:
    """Tiny per-user sliding-window rate limiter. Process-local.

    The spec asks for a per-user request limit to avoid unlimited Groq
    calls. This implementation is intentionally simple — good enough for
    the free tier. Replace with Redis in production.
    """

    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._buckets: dict[str, deque[float]] = {}
        self._lock = threading.Lock()

    def check(self, key: str) -> tuple[bool, Optional[int]]:
        """Return (allowed, retry_after_seconds)."""
        now = time.monotonic()
        with self._lock:
            bucket = self._buckets.setdefault(key, deque())
            cutoff = now - self.window_seconds
            while bucket and bucket[0] < cutoff:
                bucket.popleft()
            if len(bucket) >= self.max_requests:
                retry_after = int(self.window_seconds - (now - bucket[0])) + 1
                return False, max(retry_after, 1)
            bucket.append(now)
            return True, None


limiter = InMemoryRateLimiter(
    max_requests=app_settings.rate_limit_requests,
    window_seconds=app_settings.rate_limit_window_seconds,
)


# ---- Auth dependency --------------------------------------------------------


def _extract_bearer(auth_header: Optional[str]) -> str:
    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=AiError(
                code="unauthorized", message="Missing Bearer token."
            ).model_dump(),
        )
    return auth_header.split(" ", 1)[1].strip()


def authenticate_uid(
    authorization: Optional[str] = Header(default=None),
) -> str:
    """Verify the Firebase ID token and return the decoded uid."""
    token = _extract_bearer(authorization)
    try:
        init_firebase()
        decoded = fb_auth.verify_id_token(token)
    except fb_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=AiError(
                code="unauthorized", message="Firebase ID token has expired."
            ).model_dump(),
        )
    except fb_auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=AiError(
                code="unauthorized", message="Invalid Firebase ID token."
            ).model_dump(),
        )
    except Exception as exc:  # pragma: no cover - defensive
        logger.exception("Token verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=AiError(
                code="internal",
                message="Failed to verify Firebase ID token.",
            ).model_dump(),
        )
    uid = decoded.get("uid") or decoded.get("user_id")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=AiError(
                code="unauthorized", message="Token missing uid claim."
            ).model_dump(),
        )
    logger.info("AI auth OK: uid=%s token_present=true", uid)
    return str(uid)


def rate_limit(uid: str) -> None:
    allowed, retry_after = limiter.check(uid)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=AiError(
                code="rate_limited",
                message=(
                    f"You are sending requests too quickly. "
                    f"Try again in {retry_after} seconds."
                ),
            ).model_dump(),
            headers={"Retry-After": str(retry_after or 1)},
        )


# ---- Shared runner ---------------------------------------------------------


def _run_for_user(
    uid: str, payload: AiRequest, *, question: Optional[str]
) -> AiInsightResponse:
    """Run the LangGraph workflow and persist the result.

    Auth flow (defence-in-depth):
      1. `authenticate_uid` (FastAPI dependency) already verified the
         Firebase ID token and produced `uid` from the token claims.
         A client-supplied UID is NEVER trusted — only the verified
         one is used here.
      2. We then call `verify_business_ownership` against Firestore to
         confirm `payload.businessId` is actually owned by `uid`.
         If not, we return 403 (not 500) with code `forbidden` and
         write a structured warning log so the failure is debuggable.
      3. The same check runs again inside the LangGraph `load_data`
         node before any business data is read.

    Error visibility contract:
      * Every error_code is logged with structured context BEFORE the
        HTTPException is raised, so a developer can grep the FastAPI
        log for `AI LangGraph FAILED` and see uid + businessId + rid.
      * The HTTPException detail NEVER includes a Python traceback.
      * Unknown exceptions are mapped to HTTP 500 with code=internal
        and a generic message.
    """
    rate_limit(uid)

    # --- Authoritative business ownership check (server-side only). ---
    try:
        firestore_service.verify_business_ownership(
            uid=uid, business_id=payload.businessId
        )
    except firestore_service.UnauthorizedBusinessError as exc:
        logger.warning(
            "AI /api/ai request DENIED 403: uid=%s businessId=%s reason=%s",
            uid,
            payload.businessId,
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=AiError(
                code="forbidden",
                message=(
                    f"You do not have access to business "
                    f"{payload.businessId!r}."
                ),
            ).model_dump(),
        )
    except Exception as exc:  # pragma: no cover - defensive
        logger.exception(
            "Ownership check raised unexpected error uid=%s businessId=%s: %s",
            uid,
            payload.businessId,
            exc,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=AiError(
                code="internal",
                message="Could not verify business ownership.",
            ).model_dump(),
        )

    state: dict[str, Any] = {
        "uid": uid,
        "business_id": payload.businessId,
        "request_type": payload.requestType,
        "question": question,
        "period_days": payload.periodDays or 30,
    }

    logger.info(
        "AI LangGraph START: uid=%s businessId=%s requestType=%s periodDays=%s",
        uid,
        payload.businessId,
        payload.requestType,
        payload.periodDays or 30,
    )

    # --- Top-level safety net. Even if a node swallows its own exception
    # and turns it into error_code="internal", we want the operator to
    # see WHERE it failed (which node) and WHAT (exception class + msg).
    # The traceback itself is already logged inside the catching layer.
    try:
        final = ai_graph.run_workflow(state)
    except Exception as exc:  # pragma: no cover - safety net
        logger.exception(
            "AI LangGraph CRASHED uid=%s businessId=%s requestType=%s exc=%s: %s",
            uid,
            payload.businessId,
            payload.requestType,
            type(exc).__name__,
            exc,
        )
        final = {
            "error_code": "internal",
            "error_message": "AI request failed unexpectedly.",
        }

    logger.info(
        "AI LangGraph COMPLETE: uid=%s businessId=%s error=%s",
        uid,
        payload.businessId,
        final.get("error_code") or "none",
    )

    if final.get("error_code"):
        code = final["error_code"]
        message = final.get("error_message") or "AI request failed."
        # Single, structured log line so the operator can grep it and
        # see exactly which code was raised for this request.
        logger.warning(
            "AI LangGraph FAILED uid=%s businessId=%s requestType=%s "
            "code=%s message=%s",
            uid,
            payload.businessId,
            payload.requestType,
            code,
            message,
        )
        http_status = {
            "unauthorized": status.HTTP_401_UNAUTHORIZED,
            "forbidden": status.HTTP_403_FORBIDDEN,
            "rate_limited": status.HTTP_429_TOO_MANY_REQUESTS,
            "quota_exceeded": status.HTTP_429_TOO_MANY_REQUESTS,
            "upstream_error": status.HTTP_502_BAD_GATEWAY,
            "internal": status.HTTP_500_INTERNAL_SERVER_ERROR,
            "bad_request": status.HTTP_400_BAD_REQUEST,
        }.get(code, status.HTTP_500_INTERNAL_SERVER_ERROR)
        raise HTTPException(
            status_code=http_status,
            detail=AiError(code=code, message=message).model_dump(),
        )

    response = AiInsightResponse.model_validate(final["response"])

    # Persist insight to Firestore (best-effort; do not fail user request).
    try:
        firestore_service.save_ai_insight(
            uid=uid,
            business_id=payload.businessId,
            insight={
                "type": payload.requestType,
                "period": "monthly" if (payload.periodDays or 30) >= 28 else "custom",
                "periodDays": payload.periodDays or 30,
                "summary": response.summary,
                "keyFindings": response.keyFindings,
                "recommendations": response.recommendations,
                "confidence": response.confidence,
                "question": question,
            },
        )
    except Exception as exc:  # pragma: no cover
        logger.warning("Failed to save AI insight: %s", exc)

    return response


# ---- Routes -----------------------------------------------------------------


def _method_not_allowed_response(path: str) -> HTTPException:
    """Self-describing 405 for GET on POST-only AI endpoints.

    Some monitors / link-prefetchers / browser address-bar pastes hit
    these URLs with GET. FastAPI's default 405 carries no JSON body,
    which makes Render's access log ambiguous. Returning a structured
    AiError keeps the response shape consistent and the log greppable.
    """
    logger.warning(
        "AI method-not-allowed on %s: only POST is supported", path
    )
    return HTTPException(
        status_code=status.HTTP_405_METHOD_NOT_ALLOWED,
        detail=AiError(
            code="method_not_allowed",
            message=(
                f"{path} only accepts POST with "
                "`Authorization: Bearer <Firebase ID token>` and a JSON "
                "body of `{businessId, requestType, ...}`."
            ),
        ).model_dump(),
        headers={"Allow": "POST, OPTIONS"},
    )


@router.get(
    "/chat",
    response_model=None,
    responses={405: {"model": AiError}},
)
def chat_get() -> None:
    """Defensive GET handler — returns a self-describing 405."""
    raise _method_not_allowed_response("/api/ai/chat")


@router.post(
    "/chat",
    response_model=AiInsightResponse,
    responses={
        401: {"model": AiError},
        403: {"model": AiError},
        429: {"model": AiError},
        500: {"model": AiError},
    },
)
def chat(payload: AiRequest, uid: str = Depends(authenticate_uid)) -> AiInsightResponse:
    """Chat-style endpoint. `requestType` should be "chatbot"."""
    _log_request_received(
        path="/api/ai/chat",
        method="POST",
        business_id=payload.businessId,
        auth_header=None,  # uid already verified; we don't re-log the header
    )
    logger.info(
        "AI /chat authenticated: uid=%s businessId=%s requestType=%s",
        uid,
        payload.businessId,
        payload.requestType,
    )
    if not payload.question or not payload.question.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=AiError(
                code="bad_request",
                message="`question` is required for /api/ai/chat.",
            ).model_dump(),
        )
    return _run_for_user(uid, payload, question=payload.question)


@router.get(
    "/insight",
    response_model=None,
    responses={405: {"model": AiError}},
)
def insight_get() -> None:
    """Defensive GET handler — returns a self-describing 405."""
    raise _method_not_allowed_response("/api/ai/insight")


@router.post(
    "/insight",
    response_model=AiInsightResponse,
    responses={
        401: {"model": AiError},
        403: {"model": AiError},
        429: {"model": AiError},
        500: {"model": AiError},
    },
)
def insight(
    payload: AiRequest, uid: str = Depends(authenticate_uid)
) -> AiInsightResponse:
    """Generate a structured insight. `question` is ignored here."""
    _log_request_received(
        path="/api/ai/insight",
        method="POST",
        business_id=payload.businessId,
        auth_header=None,
    )
    logger.info(
        "AI /insight authenticated: uid=%s businessId=%s requestType=%s",
        uid,
        payload.businessId,
        payload.requestType,
    )
    return _run_for_user(uid, payload, question=None)


@router.get(
    "/auth-test",
    response_model=None,
    responses={
        401: {"model": AiError},
    },
)
def auth_test(uid: str = Depends(authenticate_uid)) -> dict[str, Any]:
    """Smoke-test endpoint: returns 200 with the verified uid.

    Useful from the Flutter side to verify that Firebase ID token auth
    reaches FastAPI correctly, without invoking the LangGraph pipeline.
    """
    logger.info("AI /auth-test OK: uid=%s", uid)
    return {
        "authenticated": True,
        "uid": uid,
        "endpoint": "/api/ai/auth-test",
    }


@router.get("/diag-ownership")
def diag_ownership(
    businessId: str,
    uid: str = Depends(authenticate_uid),
) -> dict[str, Any]:
    """Temporary diagnostic: report which ownership path matched.

    Requires the same Firebase Bearer token as the real endpoints.
    Returns a structured dict for the three paths; never raises.
    """
    report = firestore_service.diagnose_business_ownership(uid, businessId)
    logger.info("AI /diag-ownership: uid=%s businessId=%s any_matched=%s",
                uid, businessId, report.get("any_matched"))
    return report


@router.get("/health", include_in_schema=False)
def health() -> dict[str, Any]:
    """Cheap liveness probe — never touches Groq or Firestore."""
    return {
        "status": "ok",
        "groq_configured": app_settings.has_groq_key(),
        "firebase_configured": app_settings.has_firebase_credentials(),
    }


@router.get("/diag", include_in_schema=False)
def diag() -> dict[str, Any]:
    """Startup / debugging self-check.

    Returns everything `curl` would need to verify the backend is fully
    wired up. Never touches Groq (no API quota spent) but DOES touch
    Firebase once to confirm credentials load + ID-token verification
    code-path is importable. Useful from the Flutter side when the chat
    keeps failing — the diag response shows exactly what's broken.

    Example:
        $ curl http://127.0.0.1:8000/api/ai/diag
        {
          "status": "ready",
          "groq_configured": true,
          "firebase_configured": true,
          "firebase_admin_loaded": true,
          "model": "openai/gpt-oss-20b",
          "rate_limit": "20 req / 60s per uid",
          "gcp_project": "bizhisab-XXXX",
          "credentials_path": ".../service-account.json",
          "credentials_exists": true,
          "version": "1.0.0"
        }
    """
    info: dict[str, Any] = {
        "service": "bizhisab-ai-backend",
        "groq_configured": app_settings.has_groq_key(),
        "firebase_configured": app_settings.has_firebase_credentials(),
        "firebase_admin_loaded": False,
        "gcp_project": None,
        "credentials_path": app_settings.firebase_credentials_path,
        "credentials_exists": app_settings.has_firebase_credentials(),
        "model": app_settings.groq_model,
        "rate_limit": (
            f"{app_settings.rate_limit_requests} req / "
            f"{app_settings.rate_limit_window_seconds}s per uid"
        ),
        "version": app_settings.api_version,
    }

    # Probe Firebase admin to surface the real reason if init failed.
    try:
        init_firebase()
        from firebase_admin import get_app  # local import — keeps startup cheap
        try:
            app = get_app()
            info["firebase_admin_loaded"] = True
            info["gcp_project"] = getattr(app, "project_id", None)
        except ValueError:
            info["firebase_admin_loaded"] = False
    except Exception as exc:  # pragma: no cover
        info["firebase_admin_error"] = f"{type(exc).__name__}: {exc}"

    if not info["groq_configured"]:
        info["hint_groq"] = (
            "GROQ_API_KEY is missing or unset. "
            "Set it in ai_backend/.env (e.g. GROQ_API_KEY=gsk_...) "
            "and restart uvicorn."
        )
    if not info["firebase_configured"]:
        info["hint_firebase"] = (
            "FIREBASE_CREDENTIALS_PATH points to a file that doesn't exist. "
            "Either drop your service-account.json at that path or set "
            "FIREBASE_CREDENTIALS_PATH in ai_backend/.env."
        )

    info["status"] = (
        "ready"
        if info["groq_configured"]
        and info["firebase_admin_loaded"]
        else "degraded"
    )
    return info