import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/ai_insight.dart';

/// Calls the FastAPI AI backend. **No API keys live on the client** — the
/// backend authenticates the request with the Firebase ID token and
/// keeps the Groq key on the server.
///
/// Design contract: the public methods never throw. They always return
/// an [AiResult] — on failure the result carries [AiResult.errorCode]
/// and [AiResult.errorMessage]. This keeps the rest of the app
/// functional when the backend is offline and avoids the noisy
/// "Unhandled Exception" log lines.
class AiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final http.Client _http;

  /// Tracks in-flight requests so callers can dedupe concurrent calls.
  final Map<String, Future<AiResult>> _inflight = {};

  AiService({http.Client? client}) : _http = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // High-level API used by the UI layer.
  // ---------------------------------------------------------------------------

  /// Run a canned analysis (financial_analyst, expense_analyzer, …).
  /// Never throws — wraps every failure in an [AiResult].
  Future<AiResult> generateInsight({
    required String businessId,
    required AiInsightType type,
  }) {
    final key = 'insight:${type.backendKey}';
    final existing = _inflight[key];
    if (existing != null) return existing;

    final fut = _safeRun(type, () => _doGenerateInsight(businessId, type));
    _inflight[key] = fut;
    fut.whenComplete(() => _inflight.remove(key));
    return fut;
  }

  /// Send a free-text question to the chatbot endpoint. Never throws.
  Future<AiResult> chat({
    required String businessId,
    required String question,
  }) {
    final trimmed = question.trim();
    final key = 'chat:$trimmed';
    final existing = _inflight[key];
    if (existing != null) return existing;

    final fut = _safeRun(
      AiInsightType.chatbot,
      () => _doChat(businessId, trimmed),
      question: trimmed,
    );
    _inflight[key] = fut;
    fut.whenComplete(() => _inflight.remove(key));
    return fut;
  }

  /// History of insights saved by previous runs. Best-effort — returns
  /// an empty list on failure (never throws).
  Future<List<AiInsight>> getRecentInsights(
    String businessId, {
    int limit = 10,
  }) async {
    try {
      final snap = await _firestore
          .collection('businesses/$businessId/ai_insights')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(AiInsight.fromFirestore).toList();
    } catch (e, st) {
      debugPrint('AiService.getRecentInsights failed: $e');
      debugPrintStack(stackTrace: st, maxFrames: 4);
      return const <AiInsight>[];
    }
  }

  // ---------------------------------------------------------------------------
  // Internals.
  // ---------------------------------------------------------------------------

  Future<AiResult> _safeRun(
    AiInsightType type,
    Future<AiResult> Function() body, {
    String? question,
  }) async {
    try {
      return await body();
    } on AiException catch (e) {
      debugPrint('AiService: ${e.code} — ${e.message}');
      return AiResult.failure(
        type: type,
        code: e.code,
        message: e.message,
        question: question,
      );
    } catch (e, st) {
      // Catches anything else (FirebaseException, FormatException,
      // PlatformException, etc.) so the UI never sees a thrown error.
      debugPrint('AiService: unexpected error $e');
      debugPrintStack(stackTrace: st, maxFrames: 4);
      return AiResult.failure(
        type: type,
        code: 'internal_error',
        message: 'Something went wrong with AI. Please try again.',
        question: question,
      );
    }
  }

  Future<AiResult> _doGenerateInsight(
    String businessId,
    AiInsightType type,
  ) async {
    final token = await _idToken();
    if (token == null) {
      throw const AiException(
        code: 'unauthenticated',
        message: 'Please sign in again to use AI features.',
      );
    }

    final uri = Uri.parse('${AppConstants.aiBaseUrl}/api/ai/insight');
    final res = await _send(
      uri: uri,
      token: token,
      body: {
        'businessId': businessId,
        'requestType': type.backendKey,
      },
    );

    final result = AiResult(
      type: type,
      summary: (res['summary'] as String?) ?? '',
      keyFindings: _stringList(res['keyFindings']),
      recommendations: _stringList(res['recommendations']),
      confidence: (res['confidence'] as String?) ?? 'low',
    );

    // Save to Firestore (best-effort; never fail the call over this).
    await _persistInsight(businessId: businessId, result: result);
    return result;
  }

  Future<AiResult> _doChat(String businessId, String question) async {
    final token = await _idToken();
    if (token == null) {
      throw const AiException(
        code: 'unauthenticated',
        message: 'Please sign in again to use AI features.',
      );
    }

    final uri = Uri.parse('${AppConstants.aiBaseUrl}/api/ai/chat');
    final res = await _send(
      uri: uri,
      token: token,
      body: {
        'businessId': businessId,
        'requestType': 'chatbot',
        'question': question,
      },
    );

    return AiResult(
      type: AiInsightType.chatbot,
      summary: (res['summary'] as String?) ?? '',
      keyFindings: _stringList(res['keyFindings']),
      recommendations: _stringList(res['recommendations']),
      confidence: (res['confidence'] as String?) ?? 'low',
      question: question,
    );
  }

  Future<String?> _idToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken(true);
      // Log only the *presence* of the token — never its value.
      debugPrint('AiService: Firebase ID token obtained (len=${token?.length ?? 0})');
      return token;
    } catch (e) {
      debugPrint('AiService._idToken failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Connectivity probes.
  //
  // These are lightweight calls used by the UI to distinguish:
  //   - "backend not reachable"  (host down / wrong URL / firewall)
  //   - "backend reachable but says I'm unauthenticated" (token problem)
  //   - "backend reachable and auth works"
  // ---------------------------------------------------------------------------

  /// `GET /health` — never authenticated. Returns `true` if FastAPI is
  /// up at all. Used by the chat screen to differentiate "offline" from
  /// real auth/HTTP errors.
  Future<bool> ping() async {
    final uri = Uri.parse('${AppConstants.aiBaseUrl}/health');
    final rid = _newRequestId();
    debugPrint('AiService.ping[$rid] → GET $uri');
    try {
      final res = await _http
          .get(uri, headers: {'X-Request-ID': rid})
          .timeout(const Duration(seconds: 4));
      final ridEcho = res.headers['x-request-id'] ?? '<none>';
      final ok = res.statusCode == 200;
      debugPrint(
        'AiService.ping[$rid] ← status=${res.statusCode} '
        'reachable=$ok rid_echo=$ridEcho',
      );
      return ok;
    } on TimeoutException {
      debugPrint('AiService.ping[$rid]: timeout');
      return false;
    } on SocketException catch (e) {
      debugPrint('AiService.ping[$rid]: socket error '
          '(${e.osError?.message ?? e.message})');
      return false;
    } on http.ClientException catch (e) {
      debugPrint('AiService.ping[$rid]: client error (${e.message})');
      return false;
    } catch (e) {
      debugPrint('AiService.ping[$rid]: error ($e)');
      return false;
    }
  }

  /// `GET /api/ai/diag` — backend self-check. Returns the parsed JSON
  /// (or an empty map if unreachable). Never throws.
  Future<Map<String, dynamic>> fetchDiag() async {
    final uri = Uri.parse('${AppConstants.aiBaseUrl}/api/ai/diag');
    final rid = _newRequestId();
    debugPrint('AiService.diag[$rid] → GET $uri');
    try {
      final res = await _http
          .get(uri, headers: {'X-Request-ID': rid})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) return json;
        return {'status': 'unknown', 'raw': res.body};
      }
      debugPrint(
        'AiService.diag[$rid] ← status=${res.statusCode} body=${res.body}',
      );
      return {
        'status': 'http_${res.statusCode}',
        'message': res.body,
      };
    } on TimeoutException {
      debugPrint('AiService.diag[$rid]: timeout');
      return {'status': 'offline', 'message': 'timeout'};
    } on SocketException catch (e) {
      debugPrint('AiService.diag[$rid]: socket error '
          '(${e.osError?.message ?? e.message})');
      return {'status': 'offline', 'message': 'socket error'};
    } on http.ClientException catch (e) {
      debugPrint('AiService.diag[$rid]: client error (${e.message})');
      return {'status': 'offline', 'message': e.message};
    } catch (e) {
      debugPrint('AiService.diag[$rid]: error ($e)');
      return {'status': 'offline', 'message': '$e'};
    }
  }

  /// Generates a short hex id used to correlate logs across
  /// Flutter and FastAPI. The backend echoes the same id back in the
  /// `X-Request-ID` response header.
  String _newRequestId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final tail = (ms & 0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'f$tail';
  }

  /// `GET /api/ai/auth-test` — returns the verified uid if the Firebase
  /// ID token makes it through. Lets the UI distinguish a token problem
  /// from a network problem without invoking the LangGraph pipeline.
  Future<AiResult> authTest() async {
    final uri = Uri.parse('${AppConstants.aiBaseUrl}/api/ai/auth-test');
    final rid = _newRequestId();
    debugPrint('AiService.authTest[$rid] → GET $uri');
    final token = await _idToken();
    if (token == null) {
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: 'unauthenticated',
        message: 'Please sign in again to use AI features.',
      );
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Request-ID': rid,
    };
    try {
      final res = await _http
          .get(uri, headers: headers)
          .timeout(AppConstants.aiRequestTimeout);
      debugPrint(
        'AiService.authTest[$rid] ← status=${res.statusCode} '
        'rid_echo=${res.headers['x-request-id'] ?? '<none>'}',
      );
      if (res.statusCode == 200) {
        return AiResult(
          type: AiInsightType.chatbot,
          summary: 'Auth OK',
          keyFindings: const [],
          recommendations: const [],
          confidence: 'high',
        );
      }
      String code = 'http_${res.statusCode}';
      String message = 'Auth test failed (${res.statusCode}).';
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        code = (json['code'] as String?) ?? code;
        message = (json['message'] as String?) ?? message;
      } catch (_) {/* body wasn't JSON, keep defaults */}
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: code,
        message: message,
      );
    } on TimeoutException {
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: 'offline',
        message: 'AI service did not respond in time.',
      );
    } on SocketException {
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: 'offline',
        message: 'AI service is unavailable.',
      );
    } on http.ClientException catch (e) {
      // Connection refused / DNS / etc — classic "server not reachable".
      final lower = e.message.toLowerCase();
      final isOffline = lower.contains('refused') ||
          lower.contains('failed host lookup') ||
          lower.contains('network is unreachable') ||
          lower.contains('connection closed');
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: isOffline ? 'offline' : 'transport_error',
        message: isOffline
            ? 'AI service is unavailable.'
            : 'Could not reach AI service: ${e.message}',
      );
    } catch (e) {
      return AiResult.failure(
        type: AiInsightType.chatbot,
        code: 'transport_error',
        message: 'Could not reach AI service: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _send({
    required Uri uri,
    required String? token,
    required Map<String, dynamic> body,
  }) async {
    final rid = _newRequestId();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Request-ID': rid,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    debugPrint(
      'AiService._send[$rid] → POST $uri body=${_safeBody(body)}',
    );
    final http.Response res;
    try {
      res = await _http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(AppConstants.aiRequestTimeout);
    } on TimeoutException {
      debugPrint('AiService._send[$rid]: timeout (offline)');
      throw _offlineError();
    } on SocketException catch (e) {
      debugPrint(
        'AiService._send[$rid]: socket error (offline): '
        '${e.osError?.message ?? e.message}',
      );
      throw _offlineError();
    } on http.ClientException catch (e) {
      final lower = e.message.toLowerCase();
      final isOffline = lower.contains('refused') ||
          lower.contains('failed host lookup') ||
          lower.contains('network is unreachable') ||
          lower.contains('connection closed');
      debugPrint(
        'AiService._send[$rid]: client error (offline=$isOffline): ${e.message}',
      );
      if (isOffline) {
        throw _offlineError();
      }
      throw AiException(
        code: 'transport_error',
        message: 'Could not reach AI service: ${e.message}',
      );
    } on HandshakeException catch (e) {
      debugPrint('AiService._send[$rid]: handshake error (offline): ${e.message}');
      throw _offlineError();
    } catch (e, st) {
      debugPrint('AiService._send[$rid]: unexpected transport error $e');
      debugPrintStack(stackTrace: st, maxFrames: 4);
      // Unknown transport-layer failure: treat as offline so the UI
      // shows a Retry button instead of an opaque crash.
      throw _offlineError();
    }

    final status = res.statusCode;
    final ridEcho = res.headers['x-request-id'] ?? '<none>';
    debugPrint(
      'AiService._send[$rid] ← status=$status bytes=${res.body.length} '
      'rid_echo=$ridEcho',
    );
    final raw = res.body.isEmpty ? '{}' : res.body;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      throw _serverFriendlyError(
        'The AI service returned an unexpected response. Please try again.',
      );
    }

    if (status >= 200 && status < 300) {
      return json;
    }

    final code = (json['code'] as String?) ?? _defaultCodeForStatus(status);
    final message = (json['message'] as String?) ?? _defaultMessageForStatus(status);
    debugPrint(
      'AiService._send: HTTP error status=$status code=$code message=$message',
    );
    throw AiException(message: message, code: code, statusCode: status);
  }

  /// Returns a body representation safe for debugPrint: redacts any
  /// field that smells like a secret. The current body shapes
  /// (`businessId`, `requestType`, `question`, `periodDays`) are all
  /// safe to log verbatim, but this helper exists so future fields
  /// don't accidentally leak credentials.
  String _safeBody(Map<String, dynamic> body) {
    const secretKeys = {'token', 'password', 'apiKey', 'authorization'};
    final out = <String, dynamic>{};
    body.forEach((k, v) {
      out[k] = secretKeys.contains(k.toLowerCase()) ? '<redacted>' : v;
    });
    return out.toString();
  }

  String _defaultCodeForStatus(int status) {
    switch (status) {
      case 400:
        return 'bad_request';
      case 401:
        return 'unauthorized';
      case 403:
        return 'forbidden';
      case 404:
        return 'not_found';
      case 422:
        return 'unprocessable';
      case 429:
        return 'rate_limited';
      case 502:
      case 503:
      case 504:
        return 'upstream_error';
      default:
        return 'http_$status';
    }
  }

  String _defaultMessageForStatus(int status) {
    switch (status) {
      case 400:
        return 'The request was rejected by the AI service.';
      case 401:
        return 'Please sign in again to use AI features.';
      case 403:
        return 'You do not have access to this business.';
      case 404:
        return 'The AI endpoint was not found.';
      case 422:
        return 'The AI service could not process this request.';
      case 429:
        return 'You are sending requests too quickly. Try again shortly.';
      case 502:
      case 503:
      case 504:
        return 'The AI service is temporarily unavailable.';
      default:
        return 'The AI service is unavailable.';
    }
  }

  AiException _offlineError() => const AiException(
        code: 'offline',
        message:
            'AI service is unavailable. Your other features still work — try again when the AI server is online.',
      );

  AiException _serverFriendlyError(String message) =>
      AiException(code: 'upstream_error', message: message);

  Future<void> _persistInsight({
    required String businessId,
    required AiResult result,
  }) async {
    if (result.hasError) return; // don't persist failures
    try {
      final insight = AiInsight(
        id: '',
        businessId: businessId,
        type: result.type,
        title: result.type.displayLabel,
        summary: result.summary,
        keyFindings: result.keyFindings,
        recommendations: result.recommendations,
        confidence: result.confidence,
        question: result.question,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('businesses/$businessId/ai_insights')
          .add(insight.toMap());
    } catch (e) {
      debugPrint('AiService._persistInsight failed (non-fatal): $e');
    }
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

/// Internal exception used between service internals. Always caught and
/// converted into an [AiResult] before reaching the UI.
class AiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AiException($code): $message';
}
