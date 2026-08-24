"""FastAPI application entry point.

Run locally with:

    python -m uvicorn app.main:app --reload --port 8000
"""

from __future__ import annotations

import logging
import uuid

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .config import settings
from .firebase import init_firebase
from .routes import ai_routes

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s :: %(message)s",
)

app = FastAPI(title=settings.api_title, version=settings.api_version)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins) or ["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "X-Request-ID"],
)


@app.middleware("http")
async def _request_id_middleware(request: Request, call_next):
    """Stamp every request with an `X-Request-ID` and echo it in the log.

    Lets you correlate a failing Flutter request with the matching
    FastAPI log line: grep one id on both sides.
    """
    rid = request.headers.get("X-Request-ID") or uuid.uuid4().hex[:12]
    request.state.request_id = rid
    logging.getLogger(__name__).info(
        "→ %s %s rid=%s", request.method, request.url.path, rid,
    )
    response = await call_next(request)
    response.headers["X-Request-ID"] = rid
    logging.getLogger(__name__).info(
        "← %s %s status=%s rid=%s",
        request.method,
        request.url.path,
        response.status_code,
        rid,
    )
    return response


@app.on_event("startup")
def _startup() -> None:
    # Best-effort — the app still boots without credentials so /health works.
    init_firebase()


@app.exception_handler(Exception)
async def _unhandled_exc(_, exc):  # pragma: no cover
    logging.getLogger(__name__).exception("Unhandled error: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"code": "internal", "message": "Internal server error."},
    )


app.include_router(ai_routes.router)


@app.get("/health", tags=["meta"])
def health_root() -> dict[str, str]:
    """Cheap liveness probe at the root path.

    Returns ``{"status": "ok"}`` so a Flutter client (or `curl`) can
    verify the FastAPI process is reachable before attempting heavier
    calls like ``/api/ai/auth-test`` or ``/api/ai/chat``. This endpoint
    never touches Groq or Firestore.
    """
    return {"status": "ok"}


@app.get("/", include_in_schema=False)
def root() -> dict[str, str]:
    return {
        "name": settings.api_title,
        "version": settings.api_version,
        "docs": "/docs",
    }