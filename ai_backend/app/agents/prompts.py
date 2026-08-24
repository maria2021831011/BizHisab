"""Prompt templates for the LangGraph workflow.

All prompts include the financial summary computed by Python so the LLM
never has to do arithmetic. The LLM is asked to return JSON only.
"""

from __future__ import annotations

import json
from typing import Any

SYSTEM_PROMPT = """You are BizHisab AI, a financial assistant for small Bangladeshi businesses.
You ONLY analyse the numeric summary provided by the system. You never fabricate amounts.

Rules:
1. Every number you mention MUST come from the provided Financial Summary. If a value is 0 or missing, say so honestly.
2. If `insufficient_data` is true, return a low-confidence response explaining that there is not enough data for a reliable comparison. Do NOT invent trends.
3. Respond in the same language and script as the user (Bangla, Banglish, or English). Mirror the user's writing system.
4. Be concise. No filler. No greetings.
5. Output STRICT JSON only — no prose around it, no code fences, no Markdown.

JSON schema (output exactly this shape):
{{
  "summary": string,           // 1-3 sentence plain-language answer / observation
  "keyFindings": string[],     // up to 5 short bullets, each grounded in the summary
  "recommendations": string[], // up to 5 short, actionable suggestions in the user's language
  "confidence": "high"|"medium"|"low"
}}

Choose confidence:
- "high"   when the user has at least 5 transactions and previous-period data exists.
- "medium" when data exists but is limited (1-4 transactions) or comparison is partial.
- "low"    when there is no data, or the user asks something the summary cannot answer.
"""

FEATURE_INSTRUCTIONS: dict[str, str] = {
    "financial_analyst": (
        "Provide a holistic financial analysis for the requested period: "
        "income vs expense, profit, trends vs previous period, top categories, "
        "and outstanding customer/supplier dues."
    ),
    "expense_analyzer": (
        "Focus on EXPENSES only. Identify the top expense categories, "
        "compare against the previous period, and suggest ways to reduce "
        "unnecessary spending."
    ),
    "profit_analyzer": (
        "Focus on PROFIT. Explain why profit changed vs the previous period, "
        "highlight which categories drove the change, and suggest concrete "
        "actions to improve profitability."
    ),
    "revenue_analyzer": (
        "Focus on INCOME / revenue. Compare the current period with the "
        "previous one, identify top income sources, and suggest ways to "
        "grow revenue."
    ),
    "recommendation": (
        "Produce 3-5 specific, actionable business recommendations grounded "
        "in the financial summary. Each recommendation must reference at "
        "least one numeric field."
    ),
    "chatbot": (
        "Answer the user's question using ONLY the financial summary. "
        "If the question cannot be answered from the summary, return "
        "confidence=low and explain what data is missing."
    ),
}


def build_user_prompt(state: dict[str, Any]) -> str:
    """Compose the user-role prompt the LLM sees."""
    summary = state.get("financial_summary") or {}
    request_type = state.get("request_type") or "chatbot"
    feature_text = FEATURE_INSTRUCTIONS.get(
        request_type, FEATURE_INSTRUCTIONS["chatbot"]
    )
    question = (state.get("question") or "").strip()

    parts: list[str] = []
    parts.append("Feature: " + request_type)
    parts.append("Instruction: " + feature_text)
    parts.append("Financial Summary (JSON):")
    parts.append(json.dumps(summary, ensure_ascii=False, indent=2))

    if request_type == "chatbot":
        parts.append("User question:")
        parts.append(question or "Give me a general overview of my business.")

    return "\n\n".join(parts)


def detect_language_hint(text: str) -> str:
    """Heuristically detect Bangla / English / mixed language. Used only as a hint."""
    if not text:
        return "en"
    has_bangla = any("\u0980" <= ch <= "\u09FF" for ch in text)
    ascii_letters = sum(1 for ch in text if ch.isascii() and ch.isalpha())
    if has_bangla and ascii_letters > len(text) * 0.1:
        return "mixed"
    if has_bangla:
        return "bn"
    return "en"