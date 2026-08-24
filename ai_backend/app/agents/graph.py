"""LangGraph workflow assembly.

Linear graph — explicit START→END as the spec asks. We use `add_node` +
`add_edge` so the graph is easy to follow and easy to test.
"""

from __future__ import annotations

import logging
from typing import Any

from langgraph.graph import END, START, StateGraph

from .nodes import (
    NodeError,
    analyze_request,
    authenticate,
    groq_call,
    load_data,
    validate_response,
)
from .state import AiState

logger = logging.getLogger(__name__)


def build_graph():
    """Build and compile the LangGraph workflow."""
    builder = StateGraph(AiState)
    builder.add_node("authenticate", authenticate)
    builder.add_node("load_data", load_data)
    builder.add_node("analyze_request", analyze_request)
    builder.add_node("groq_call", groq_call)
    builder.add_node("validate_response", validate_response)

    builder.add_edge(START, "authenticate")
    builder.add_edge("authenticate", "load_data")
    builder.add_edge("load_data", "analyze_request")
    builder.add_edge("analyze_request", "groq_call")
    builder.add_edge("groq_call", "validate_response")
    builder.add_edge("validate_response", END)

    return builder.compile()


# A single compiled graph instance is reused across requests.
_graph = build_graph()


def run_workflow(initial_state: dict[str, Any]) -> dict[str, Any]:
    """Invoke the workflow and translate NodeError into state error fields.

    The outer ``except Exception`` is the LAST line of defence. It logs the
    full Python traceback (via ``logger.exception``) so the operator can see
    exactly which step failed. We deliberately do NOT leak the raw exception
    text to the client — only ``error_code`` and a generic
    ``error_message`` travel back through ``_run_for_user``.
    """  
    state: dict[str, Any] = dict(initial_state)
    try:
        result = _graph.invoke(state)
        return result
    except NodeError as exc:
        # Expected, structured error from a node. Logged inside the node.
        state["error_code"] = exc.code
        state["error_message"] = exc.message
        return state
    except Exception as exc:  # pragma: no cover - defensive
        # Unexpected exception — log full traceback + safe state context.
        # State keys only (no values) so we never leak the prompt or
        # financial summary into the log line.
        logger.exception(
            "AI LangGraph unexpected failure exc=%s: %s | state_keys=%s",
            type(exc).__name__,
            exc,
            sorted(state.keys()),
        )
        state["error_code"] = "internal"
        state["error_message"] = (
            "Unexpected error while processing AI request. "
            "Please try again."
        )
        return state