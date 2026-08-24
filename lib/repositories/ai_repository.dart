import '../models/ai_insight.dart';
import '../services/ai_service.dart';

/// Thin layer between the AI provider and the [AiService]. Keeps the UI
/// unaware of HTTP, Firebase tokens, and persistence.
class AiRepository {
  final AiService _service;

  AiRepository({AiService? service}) : _service = service ?? AiService();

  /// Run a structured analysis (financial_analyst, expense_analyzer, …).
  Future<AiResult> generateInsight({
    required String businessId,
    required AiInsightType type,
  }) {
    return _service.generateInsight(businessId: businessId, type: type);
  }

  /// Send a free-form question to the chatbot endpoint.
  Future<AiResult> askChat({
    required String businessId,
    required String question,
  }) {
    return _service.chat(businessId: businessId, question: question);
  }

  /// History of previously generated insights (cached in Firestore).
  Future<List<AiInsight>> getRecentInsights(
    String businessId, {
    int limit = 10,
  }) {
    return _service.getRecentInsights(businessId, limit: limit);
  }

  /// Cheap connectivity probe — never throws.
  Future<bool> ping() => _service.ping();

  /// Self-check JSON from the backend (groq_configured, etc.).
  Future<Map<String, dynamic>> fetchDiag() => _service.fetchDiag();
}
