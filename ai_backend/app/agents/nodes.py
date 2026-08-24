"""Individual LangGraph nodes.

Each node is a small pure-ish function. They mutate `AiState` in place and
return it so the graph can chain them.
"""

from __future__ import annotations

import json
import logging
import re
from typing import Any

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_groq import ChatGroq

from ..config import settings
from ..services import financial_service
from ..services import firestore_service
from . import prompts

logger = logging.getLogger(__name__)

# ---- Domain errors ----------------------------------------------------------


class NodeError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message


# ---- Node: authenticate -----------------------------------------------------
# Auth has already happened in the FastAPI layer (token verified there).
# This node validates the in-state uid/business_id are present.


def authenticate(state: dict[str, Any]) -> dict[str, Any]:
    uid = state.get("uid")
    business_id = state.get("business_id")
    if not uid or not business_id:
        raise NodeError(
            "unauthorized", "Missing authenticated user or businessId."
        )
    return state


# ---- Node: load financial summary -------------------------------------------


def load_data(state: dict[str, Any]) -> dict[str, Any]:
    uid = str(state.get("uid") or "")
    business_id = str(state.get("business_id") or "")
    period_days = int(state.get("period_days") or 30)
    try:
        summary = financial_service.compute_summary(
            uid=uid,
            business_id=business_id,
            period_days=period_days,
        )
    except firestore_service.UnauthorizedBusinessError as exc:
        # Authoritative: the verified Firebase UID does NOT own this
        # businessId. Surface as forbidden — caller maps to HTTP 403.
        logger.warning(
            "AI authorization denied: uid=%s businessId=%s reason=%s",
            uid,
            business_id,
            exc,
        )
        raise NodeError("forbidden", str(exc)) from exc
    except Exception as exc:  # pragma: no cover - defensive
        # Log the FULL Python traceback + the exception class + message.
        # This is the single most important log line when debugging
        # "AI LangGraph COMPLETE: error=internal" — it tells the operator
        # exactly which Firestore query / aggregator step failed.
        logger.exception(
            "AI load_data FAILED uid=%s businessId=%s periodDays=%s exc=%s: %s",
            uid,
            business_id,
            period_days,
            type(exc).__name__,
            exc,
        )
        raise NodeError(
            "internal",
            "Failed to load financial data for the AI pipeline.",
        ) from exc

    state["financial_summary"] = financial_service.summary_to_compact_dict(summary)
    state["language_hint"] = prompts.detect_language_hint(state.get("question") or "")
    return state


# ---- Node: analyze request --------------------------------------------------
# Compose the prompt that will be sent to Groq.


def analyze_request(state: dict[str, Any]) -> dict[str, Any]:
    state["prompt"] = prompts.build_user_prompt(state)
    return state


# ---- Node: Groq call --------------------------------------------------------


# Module-level client cache keyed by API key.
_client_cache: dict[str, ChatGroq] = {}


def _get_client() -> ChatGroq:
    if not settings.has_groq_key():
        # Operator fix: edit ai_backend/.env and set GROQ_API_KEY=gsk_...
        # We raise upstream_error (HTTP 502) rather than internal (HTTP 500)
        # because this is a backend-config issue, not a server bug.
        logger.error(
            "GROQ_API_KEY missing or still set to placeholder. "
            "Set it in ai_backend/.env (e.g. GROQ_API_KEY=gsk_...) "
            "and restart uvicorn."
        )
        raise NodeError(
            "upstream_error",
            "AI service is not configured on the server. "
            "Contact the backend operator.",
        )
    if settings.groq_api_key not in _client_cache:
        try:
            _client_cache[settings.groq_api_key] = ChatGroq(
                model=settings.groq_model,
                api_key=settings.groq_api_key,
                temperature=0.4,
                max_tokens=900,
            )
        except Exception as exc:  # pragma: no cover - defensive
            # ChatGroq constructor validates the model name; surface that
            # immediately so the operator sees the exact reason instead of a
            # generic 500.
            logger.exception(
                "ChatGroq init failed model=%s: %s",
                settings.groq_model,
                exc,
            )
            raise NodeError(
                "upstream_error",
                f"AI model {settings.groq_model!r} could not be initialized. "
                f"Reason: {type(exc).__name__}.",
            ) from exc
    return _client_cache[settings.groq_api_key]


def groq_call(state: dict[str, Any]) -> dict[str, Any]:
    client = _get_client()
    try:
        msg = client.invoke(
            [
                SystemMessage(content=prompts.SYSTEM_PROMPT),
                HumanMessage(content=state.get("prompt") or ""),
            ]
        )
    except Exception as exc:
        text = str(exc).lower()
        # Friendly quota / rate-limit handling — no paid fallback.
        if any(
            token in text
            for token in (
                "rate limit",
                "rate_limit",
                "quota",
                "tokens per minute",
                "tpm",
                "429",
            )
        ):
            raise NodeError(
                "quota_exceeded",
                "AI service limit reached. Please try again later.",
            ) from exc
        if "api key" in text or "unauthorized" in text or "401" in text:
            raise NodeError(
                "internal",
                "Groq rejected the request. Check GROQ_API_KEY in .env.",
            ) from exc
        logger.exception("Groq call failed: %s", exc)
        raise NodeError("upstream_error", "AI service is unavailable.") from exc

    raw = (msg.content or "").strip()
    state["raw_text"] = raw

    parsed = _safe_parse_json(raw)
    if parsed is None:
        # The LLM sometimes wraps JSON in code fences. Strip and retry once.
        cleaned = _strip_code_fences(raw)
        parsed = _safe_parse_json(cleaned)
    if parsed is None:
        raise NodeError(
            "upstream_error",
            "AI returned a malformed response. Please try again.",
        )
    state["groq_response"] = parsed
    return state


# ---- Node: validate response ------------------------------------------------


def validate_response(state: dict[str, Any]) -> dict[str, Any]:
    parsed = state.get("groq_response") or {}
    summary_text = (parsed.get("summary") or "").strip()
    if not summary_text:
        # Some models omit `summary` if they think the question was trivial.
        # Fall back to a short string assembled from findings.
        findings = parsed.get("keyFindings") or []
        summary_text = "; ".join(findings[:3]) if findings else "No response."
        parsed["summary"] = summary_text

    findings = parsed.get("keyFindings") or []
    recos = parsed.get("recommendations") or []
    confidence = (parsed.get("confidence") or "low").lower()
    if confidence not in {"high", "medium", "low"}:
        confidence = "low"

    # If we already know the summary is insufficient, force low confidence.
    summary_obj = state.get("financial_summary") or {}
    if summary_obj.get("insufficient_data"):
        confidence = "low"

    state["response"] = {
        "summary": summary_text,
        "keyFindings": [str(x) for x in findings][:10],
        "recommendations": [str(x) for x in recos][:10],
        "confidence": confidence,
    }
    return state


# ---- Helpers ----------------------------------------------------------------


def _safe_parse_json(text: str) -> dict[str, Any] | None:
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try to extract the first {...} block.
        m = re.search(r"\{[\s\S]*\}", text)
        if not m:
            return None
        try:
            return json.loads(m.group(0))
        except json.JSONDecodeError:
            return None


def _strip_code_fences(text: str) -> str:
    return re.sub(r"^```(?:json)?\s*|\s*```$", "", text.strip(), flags=re.IGNORECASE)