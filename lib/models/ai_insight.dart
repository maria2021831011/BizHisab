import 'package:cloud_firestore/cloud_firestore.dart';

/// AI feature requested from the FastAPI backend.
enum AiInsightType {
  daily,
  weekly,
  monthly,
  expenseAnalysis,
  profitAnalysis,
  revenueTrend,
  recommendation,
  chatbot,
}

extension AiInsightTypeX on AiInsightType {
  /// The string the FastAPI backend expects in `AiRequest.requestType`.
  String get backendKey {
    switch (this) {
      case AiInsightType.daily:
      case AiInsightType.weekly:
      case AiInsightType.monthly:
        return 'financial_analyst';
      case AiInsightType.expenseAnalysis:
        return 'expense_analyzer';
      case AiInsightType.profitAnalysis:
        return 'profit_analyzer';
      case AiInsightType.revenueTrend:
        return 'revenue_analyzer';
      case AiInsightType.recommendation:
        return 'recommendation';
      case AiInsightType.chatbot:
        return 'chatbot';
    }
  }

  /// Human-friendly label used in the UI.
  String get displayLabel {
    switch (this) {
      case AiInsightType.daily:
        return 'Daily insight';
      case AiInsightType.weekly:
        return 'Weekly insight';
      case AiInsightType.monthly:
        return 'Monthly insight';
      case AiInsightType.expenseAnalysis:
        return 'Expense analysis';
      case AiInsightType.profitAnalysis:
        return 'Profit analysis';
      case AiInsightType.revenueTrend:
        return 'Revenue trend';
      case AiInsightType.recommendation:
        return 'Business recommendations';
      case AiInsightType.chatbot:
        return 'AI chat';
    }
  }
}

/// Structured response delivered by FastAPI and stored in Firestore.
class AiInsight {
  final String id;
  final String businessId;
  final AiInsightType type;
  final String title;

  /// Concise plain-language answer (1–3 sentences).
  final String summary;

  /// Optional legacy free-text content for backwards compatibility with
  /// insights saved by the previous Flutter-side AI code path. New
  /// insights populate [summary] / [keyFindings] / [recommendations]
  /// instead.
  final String? content;

  final List<String> keyFindings;
  final List<String> recommendations;

  /// "high" | "medium" | "low".
  final String confidence;

  /// The user question that produced this insight (chat only).
  final String? question;

  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AiInsight({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    required this.summary,
    this.content,
    this.keyFindings = const [],
    this.recommendations = const [],
    this.confidence = 'low',
    this.question,
    this.metadata,
    required this.createdAt,
  });

  /// Human-readable summary suitable for chat bubbles / fallback views.
  String get displayText {
    if (summary.isNotEmpty) return summary;
    if (content != null && content!.isNotEmpty) return content!;
    if (keyFindings.isNotEmpty) return keyFindings.join(' • ');
    return '';
  }

  factory AiInsight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final summary = (data['summary'] as String?)?.trim() ?? '';
    final content = (data['content'] as String?)?.trim();
    final fallbackText =
        (content == null || content.isEmpty)
            ? (data['title'] as String? ?? '')
            : content;

    return AiInsight(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      type: _parseType(data['type']),
      title: data['title'] ?? '',
      summary: summary.isNotEmpty ? summary : fallbackText,
      content: content,
      keyFindings: _stringList(data['keyFindings']),
      recommendations: _stringList(data['recommendations']),
      confidence: _parseConfidence(data['confidence']),
      question: data['question'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'type': type.backendKey,
      'title': title,
      'summary': summary,
      // Keep legacy column populated for older clients that read it.
      'content': content ?? summary,
      'keyFindings': keyFindings,
      'recommendations': recommendations,
      'confidence': confidence,
      'question': question,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static AiInsightType _parseType(dynamic type) {
    switch (type) {
      case 'daily':
        return AiInsightType.daily;
      case 'weekly':
        return AiInsightType.weekly;
      case 'monthly':
        return AiInsightType.monthly;
      // Legacy / new aliases all map onto the same enum.
      case 'expenseAnalysis':
      case 'expense_analyzer':
        return AiInsightType.expenseAnalysis;
      case 'profitAnalysis':
      case 'profit_analyzer':
        return AiInsightType.profitAnalysis;
      case 'revenueTrend':
      case 'revenue_analyzer':
        return AiInsightType.revenueTrend;
      case 'recommendation':
        return AiInsightType.recommendation;
      case 'chatbot':
        return AiInsightType.chatbot;
      default:
        return AiInsightType.monthly;
    }
  }

  static String _parseConfidence(dynamic raw) {
    final s = (raw as String? ?? '').toLowerCase();
    if (s == 'high' || s == 'medium' || s == 'low') return s;
    return 'low';
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

/// Lightweight result returned by the AI service to the UI.
///
/// Soft-failure model: instead of throwing on offline / quota / auth
/// errors, the service returns an [AiResult] with [errorCode] set and
/// a friendly [errorMessage]. The UI distinguishes success vs
/// failure by reading [hasError], never by try/catch — this keeps
/// `flutter` from logging scary "Unhandled Exception" traces when the
/// backend is unreachable.
class AiResult {
  final AiInsightType type;
  final String summary;
  final List<String> keyFindings;
  final List<String> recommendations;
  final String confidence;
  final String? question;

  /// Stable error code from the backend or the client. `null` means
  /// success.
  final String? errorCode;

  /// Human-friendly error message. `null` on success.
  final String? errorMessage;

  const AiResult({
    required this.type,
    required this.summary,
    this.keyFindings = const [],
    this.recommendations = const [],
    this.confidence = 'low',
    this.question,
    this.errorCode,
    this.errorMessage,
  });

  bool get isEmpty => summary.trim().isEmpty;
  bool get hasError => errorCode != null;

  /// Empty failure result used when the AI couldn't be reached.
  factory AiResult.failure({
    required AiInsightType type,
    required String code,
    required String message,
    String? question,
  }) {
    return AiResult(
      type: type,
      summary: '',
      confidence: 'low',
      errorCode: code,
      errorMessage: message,
      question: question,
    );
  }
}
