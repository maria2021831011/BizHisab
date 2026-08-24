"""LangGraph state definition.

The state travels through every node. Nodes mutate it and the graph
fans it out linearly to keep the workflow predictable.
"""

from __future__ import annotations

from typing import Any, Optional

from typing_extensions import TypedDict


class AiState(TypedDict, total=False):
    # Auth
    uid: str
    business_id: str

    # Input request
    request_type: str
    question: Optional[str]
    period_days: Optional[int]

    # Loaded data
    financial_summary: dict[str, Any]

    # Internal
    language_hint: str  # "bn" | "en" | "mixed"
    prompt: str

    # Groq raw response (already parsed JSON dict on success)
    groq_response: dict[str, Any]
    raw_text: str

    # Errors
    error_code: Optional[str]
    error_message: Optional[str]

    # Final response (matches models.AiInsightResponse)
    response: dict[str, Any]