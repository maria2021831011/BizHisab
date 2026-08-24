import 'package:flutter/material.dart';

import '../models/ai_insight.dart';
import '../repositories/ai_repository.dart';

/// Provider powering the AI Insights screen and AI Chat screen.
///
/// State is intentionally minimal — structured [AiResult] for the latest
/// insight, a chat history, plus loading / error flags. Errors are
/// captured as friendly messages so the rest of the app keeps working
/// when the backend is offline.
class AiProvider extends ChangeNotifier {
  final AiRepository _repository;

  AiProvider({AiRepository? repository})
      : _repository = repository ?? AiRepository();

  // ----- Insight view state -----
  bool _isLoading = false;
  String? _errorMessage;
  AiResult? _lastInsight;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AiResult? get lastInsight => _lastInsight;
  bool get hasInsight => _lastInsight != null && !_lastInsight!.isEmpty;

  // ----- Chat view state -----
  final List<ChatTurn> _chatHistory = [];
  bool _isChatLoading = false;
  String? _chatErrorMessage;
  String? _lastChatQuestion;
  String? _lastChatBusinessId;

  List<ChatTurn> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isChatLoading => _isChatLoading;
  String? get chatErrorMessage => _chatErrorMessage;
  String? get lastChatQuestion => _lastChatQuestion;
  String? get lastChatBusinessId => _lastChatBusinessId;

  // ----- History view state -----
  List<AiInsight> _cachedInsights = [];
  bool _isHistoryLoading = false;
  String? _historyError;

  List<AiInsight> get cachedInsights => _cachedInsights;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;

  // ----- Backend connectivity state -----
  /// Result of the most recent backend ping. `null` = not yet probed.
  bool? _backendReachable;
  bool? get backendReachable => _backendReachable;

  /// Diag snapshot from /api/ai/diag. Lets the UI tell the user exactly
  /// what's missing (Groq key / Firebase creds) without exposing it.
  Map<String, dynamic>? _backendDiag;
  Map<String, dynamic>? get backendDiag => _backendDiag;

  // ---------------------------------------------------------------------------
  // Actions.
  // ---------------------------------------------------------------------------

  Future<void> loadCachedInsights(String businessId, {int limit = 10}) async {
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      _cachedInsights =
          await _repository.getRecentInsights(businessId, limit: limit);
    } catch (e) {
      _historyError = 'Could not load saved insights.';
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<AiResult?> generateInsight({
    required String businessId,
    required AiInsightType type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.generateInsight(
        businessId: businessId,
        type: type,
      );
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _lastInsight = result;
        return null;
      }
      _lastInsight = result;
      return result;
    } catch (e) {
      _errorMessage = 'AI analysis failed. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AiResult?> askChat({
    required String businessId,
    required String question,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return null;

    _chatHistory.add(ChatTurn(role: ChatRole.user, text: trimmed));
    _lastChatQuestion = trimmed;
    _lastChatBusinessId = businessId;
    _isChatLoading = true;
    _chatErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.askChat(
        businessId: businessId,
        question: trimmed,
      );
      if (result.hasError) {
        // Pop the just-added user bubble and surface the error —
        // matches the "failed message, please retry" UX of chat apps.
        if (_chatHistory.isNotEmpty &&
            _chatHistory.last.role == ChatRole.user &&
            _chatHistory.last.text == trimmed) {
          _chatHistory.removeLast();
        }
        _chatErrorMessage = result.errorMessage;
        return null;
      }
      _chatHistory.add(
        ChatTurn(
          role: ChatRole.assistant,
          text: result.summary,
          insights: result,
        ),
      );
      return result;
    } catch (e) {
      // Service contract says it never throws, but defend the boundary
      // anyway so the screen stays stable.
      if (_chatHistory.isNotEmpty &&
          _chatHistory.last.role == ChatRole.user &&
          _chatHistory.last.text == trimmed) {
        _chatHistory.removeLast();
      }
      _chatErrorMessage = 'AI chat failed. Please try again.';
      return null;
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearChatError() {
    _chatErrorMessage = null;
    notifyListeners();
  }

  void clearChat() {
    _chatHistory.clear();
    _chatErrorMessage = null;
    _lastChatQuestion = null;
    _lastChatBusinessId = null;
    notifyListeners();
  }

  /// Re-run the most recent chat question against the backend. Used by
  /// the chat screen's Retry button when a previous attempt errored.
  Future<AiResult?> retryLastChat() async {
    final question = _lastChatQuestion;
    final businessId = _lastChatBusinessId;
    if (question == null || businessId == null) return null;
    return askChat(businessId: businessId, question: question);
  }

  // ---------------------------------------------------------------------------
  // Backend connectivity probes.
  // ---------------------------------------------------------------------------

  /// Probe the backend and update [backendReachable]. Safe to call at
  /// app start; never throws.
  Future<void> probeBackend() async {
    final ok = await _repository.ping();
    if (_backendReachable != ok) {
      _backendReachable = ok;
      notifyListeners();
    }
  }

  /// Fetch the self-check JSON from `/api/ai/diag`. The result exposes
  /// `groq_configured`, `firebase_configured`, etc. — useful for the
  /// diagnostics card the AI screens can show when something is wrong.
  Future<Map<String, dynamic>> fetchDiag() async {
    final map = await _repository.fetchDiag();
    _backendDiag = map;
    notifyListeners();
    return map;
  }
}

/// Lightweight chat turn used by the UI.
class ChatTurn {
  final ChatRole role;
  final String text;
  final AiResult? insights;

  const ChatTurn({
    required this.role,
    required this.text,
    this.insights,
  });
}

enum ChatRole { user, assistant }
