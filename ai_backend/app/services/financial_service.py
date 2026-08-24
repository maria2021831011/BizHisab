"""Pure financial summary computation.

All numeric calculations live here. The LLM is NEVER asked to do math —
it only interprets these numbers in natural language.

PII hygiene: only aggregate fields are returned. Customer / supplier names
and contact information are stripped before any data leaves this module.
"""

from __future__ import annotations

import logging
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Any

from . import firestore_service

logger = logging.getLogger(__name__)


@dataclass
class FinancialSummary:
    period_days: int
    currency: str

    # Current period
    income_total: float = 0.0
    expense_total: float = 0.0
    profit: float = 0.0
    transaction_count: int = 0

    # Previous equivalent period (same length, ending one minute before current start)
    previous_income_total: float = 0.0
    previous_expense_total: float = 0.0
    previous_profit: float = 0.0
    previous_transaction_count: int = 0

    # Aggregations
    top_income_categories: dict[str, float] = field(default_factory=dict)
    top_expense_categories: dict[str, float] = field(default_factory=dict)

    # Customer / supplier outstanding
    customer_due_total: float = 0.0
    customer_due_count: int = 0
    supplier_due_total: float = 0.0
    supplier_due_count: int = 0

    # Deltas vs previous period (percent)
    income_change_pct: float = 0.0
    expense_change_pct: float = 0.0
    profit_change_pct: float = 0.0

    insufficient_data: bool = False

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        return d


def compute_summary(
    uid: str, business_id: str, period_days: int = 30
) -> FinancialSummary:
    """Compute the canonical financial summary for a business.

    The 'current period' is the most recent `period_days` days. The
    'previous period' is the `period_days` window immediately before that.
    """
    period_days = max(1, min(period_days, 365))
    summary = FinancialSummary(period_days=period_days, currency="BDT")

    now = datetime.now(timezone.utc)
    current_start = now - _days(period_days)
    previous_end = current_start
    previous_start = previous_end - _days(period_days)

    try:
        transactions = firestore_service.list_transactions(
            uid, business_id, since=previous_start
        )
    except firestore_service.UnauthorizedBusinessError:
        # Re-raise — caller decides HTTP status.
        raise

    income_by_cat: dict[str, float] = defaultdict(float)
    expense_by_cat: dict[str, float] = defaultdict(float)

    for tx in transactions:
        tx_date = _tx_date(tx)
        amount = _safe_float(tx.get("amount"))
        tx_type = (tx.get("type") or "").lower()
        category = (tx.get("category") or "Other") or "Other"
        if tx_type == "income":
            category = (tx.get("category") or "General") or "General"

        if tx_date is None:
            # Skip malformed records; we never want the LLM to invent.
            continue

        if tx_date >= current_start:
            summary.transaction_count += 1
            if tx_type == "income":
                summary.income_total += amount
                income_by_cat[category] += amount
            elif tx_type == "expense":
                summary.expense_total += amount
                expense_by_cat[category] += amount
        elif tx_date >= previous_start and tx_date < previous_end:
            summary.previous_transaction_count += 1
            if tx_type == "income":
                summary.previous_income_total += amount
            elif tx_type == "expense":
                summary.previous_expense_total += amount

    summary.profit = summary.income_total - summary.expense_total
    summary.previous_profit = (
        summary.previous_income_total - summary.previous_expense_total
    )

    summary.top_income_categories = dict(
        sorted(income_by_cat.items(), key=lambda kv: kv[1], reverse=True)[:5]
    )
    summary.top_expense_categories = dict(
        sorted(expense_by_cat.items(), key=lambda kv: kv[1], reverse=True)[:5]
    )

    summary.income_change_pct = _pct(summary.income_total, summary.previous_income_total)
    summary.expense_change_pct = _pct(summary.expense_total, summary.previous_expense_total)
    summary.profit_change_pct = _pct(summary.profit, summary.previous_profit)

    summary.customer_due_total, summary.customer_due_count = _due_totals(
        firestore_service.list_customers(uid, business_id)
    )
    summary.supplier_due_total, summary.supplier_due_count = _due_totals(
        firestore_service.list_suppliers(uid, business_id)
    )

    if summary.transaction_count == 0:
        summary.insufficient_data = True

    return summary


def _due_totals(parties: list[dict[str, Any]]) -> tuple[float, int]:
    total = 0.0
    count = 0
    for p in parties:
        # Canonical fields on Customer/Supplier: totalPurchase, totalPaid,
        # totalDue. Fall back to deriving totalDue from purchase - paid.
        purchase = _safe_float(p.get("totalPurchase"))
        paid = _safe_float(p.get("totalPaid"))
        due = p.get("totalDue")
        if due is None:
            due = max(0.0, purchase - paid)
        due = _safe_float(due)
        if due > 0.5:  # ignore negligible rounding residuals
            total += due
            count += 1
    return round(total, 2), count


def _safe_float(v: Any) -> float:
    if v is None or v == "":
        return 0.0
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0


def _tx_date(tx: dict[str, Any]) -> datetime | None:
    raw = tx.get("date")
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return _ensure_utc(raw)
    # Firestore Timestamp — duck-typed to avoid extra import.
    if hasattr(raw, "timestamp"):
        try:
            return datetime.fromtimestamp(float(raw.timestamp()), tz=timezone.utc)
        except Exception:
            return None
    if isinstance(raw, (int, float)):
        return datetime.fromtimestamp(float(raw), tz=timezone.utc)
    if isinstance(raw, str):
        try:
            return datetime.fromisoformat(raw.replace("Z", "+00:00"))
        except ValueError:
            return None
    return None


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _days(n: int):
    from datetime import timedelta

    return timedelta(days=n)


def _pct(current: float, previous: float) -> float:
    if previous <= 0:
        return 0.0
    return round(((current - previous) / previous) * 100.0, 2)


def summary_to_compact_dict(summary: FinancialSummary) -> dict[str, Any]:
    """Convert a summary to a JSON-friendly dict for prompts and responses.

    Strips PII implicitly because the summary only holds aggregates.
    """
    return summary.to_dict()