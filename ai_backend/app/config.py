"""Application configuration loaded from environment / .env file.

All values are read once at import time. Override locally by editing `.env`
in the `ai_backend/` directory.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

from dotenv import load_dotenv

# Load .env if present. Safe to call multiple times. `override=True`
# guarantees the value from `.env` wins over any stale shell export,
# so a typo or shell `export GROQ_MODEL=...` from an older session
# cannot silently point at a deprecated model name.
_BACKEND_DIR = Path(__file__).resolve().parent.parent
load_dotenv(_BACKEND_DIR / ".env", override=True)

logger = logging.getLogger(__name__)


class Settings:
    """Lightweight settings container. Avoids extra deps like pydantic-settings."""

    # Groq
    groq_api_key: str = os.getenv("GROQ_API_KEY", "").strip()
    # Default is the model the operator's API key actually has access to.
    # Override via GROQ_MODEL in ai_backend/.env.
    groq_model: str = os.getenv("GROQ_MODEL", "openai/gpt-oss-20b").strip()

    # Firebase Admin SDK
    firebase_credentials_path: str = os.getenv(
        "FIREBASE_CREDENTIALS_PATH", "./service-account.json"
    ).strip()

    # Rate limiting (per authenticated user)
    rate_limit_requests: int = int(os.getenv("AI_RATE_LIMIT_REQUESTS", "20"))
    rate_limit_window_seconds: int = int(
        os.getenv("AI_RATE_LIMIT_WINDOW_SECONDS", "60")
    )

    # CORS — comma-separated origins, "*" for dev
    cors_origins: tuple[str, ...] = tuple(
        o.strip()
        for o in os.getenv("AI_CORS_ORIGINS", "*").split(",")
        if o.strip()
    )

    # API metadata
    api_title: str = "BizHisab AI Backend"
    api_version: str = "1.0.0"

    def has_groq_key(self) -> bool:
        return bool(self.groq_api_key) and self.groq_api_key != "your_groq_api_key_here"

    def has_firebase_credentials(self) -> bool:
        path = Path(self.firebase_credentials_path)
        if not path.is_absolute():
            path = _BACKEND_DIR / path
        return path.exists()


settings = Settings()

# Safe startup log. We deliberately log the MODEL name (not the key) and
# whether the key is present (not its value).
logger.info(
    "Groq model: %s | api_key_present=%s",
    settings.groq_model,
    settings.has_groq_key(),
)