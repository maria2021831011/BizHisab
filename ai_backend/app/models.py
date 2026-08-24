"""Pydantic models for request / response payloads.

Kept separate from `agents.state` which is the LangGraph internal state.
"""

from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field

RequestType = Literal[
    "financial_analyst",
    "expense_analyzer",
    "profit_analyzer",
    "revenue_analyzer",
    "recommendation",
    "chatbot",
]

Confidence = Literal["high", "medium", "low"]


class AiRequest(BaseModel):
    """Body for POST /api/ai/chat and POST /api/ai/insight."""

    businessId: str = Field(..., min_length=1, max_length=128)
    question: Optional[str] = Field(
        default=None,
        max_length=2000,
        description="User question. Required for chatbot, ignored otherwise.",
    )
    requestType: RequestType = Field(..., description="AI feature to invoke")
    periodDays: Optional[int] = Field(
        default=None,
        ge=1,
        le=365,
        description="Optional override for the analysis window in days.",
    )


class AiInsightResponse(BaseModel):
    """Structured response every endpoint returns on success."""

    summary: str = Field(..., min_length=1, max_length=2000)
    keyFindings: list[str] = Field(default_factory=list, max_length=20)
    recommendations: list[str] = Field(default_factory=list, max_length=20)
    confidence: Confidence = "low"


class AiError(BaseModel):
    code: Literal[
        "unauthorized",
        "forbidden",
        "rate_limited",
        "quota_exceeded",
        "upstream_error",
        "bad_request",
        "internal",
    ]
    message: str