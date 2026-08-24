import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../repositories/reports_repository.dart';
import '../features/reports/models/report_data.dart';
import '../features/reports/utils/date_range_resolver.dart';
import '../features/reports/utils/report_aggregator.dart';

/// State machine for the Reports screen.
///
/// Lives one step away from Firestore: it asks the [ReportsRepository] for the
/// raw inputs and runs them through [ReportAggregator]. Caches the last-fetched
/// transactions so category-filter changes don't re-hit Firestore.
class ReportsProvider extends ChangeNotifier {
  ReportsProvider({ReportsRepository? repository})
      : _repository = repository ?? ReportsRepository();

  final ReportsRepository _repository;

  // ----- Active filter state -----
  ReportPeriod _period = ReportPeriod.monthly;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _selectedCategory;

  // ----- Cached inputs (so filter changes don't refetch) -----
  List<TransactionModel>? _cachedTransactions;
  DateTime? _cachedStart;
  DateTime? _cachedEnd;

  // ----- Render state -----
  ReportData _data = EmptyReportData(
    period: ReportPeriod.monthly,
    start: DateTime.now(),
    end: DateTime.now(),
  );
  double _customerDueCache = 0;
  double _supplierDueCache = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _activeBusinessId;

  // ----- Public read API -----
  ReportPeriod get period => _period;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;
  String? get selectedCategory => _selectedCategory;
  ReportData get data => _data;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  /// Read-only view of the last-fetched transactions for the current window.
  /// The screen uses this to render the "transactions in this period" list
  /// without re-hitting Firestore.
  List<TransactionModel> get cachedTransactions =>
      _cachedTransactions ?? const <TransactionModel>[];

  // ----- Mutations -----

  /// Initial (or post-logout) load. Pulls data for the current month.
  Future<void> load(String? businessId) async {
    _activeBusinessId = businessId;
    if (businessId == null || businessId.isEmpty) {
      _data = _emptyForPeriod(_period);
      _errorMessage = null;
      notifyListeners();
      return;
    }
    await _fetch(businessId, isInitial: true);
  }

  /// Refresh-on-pull. Re-runs the same window without showing the full-screen
  /// loading skeleton.
  Future<void> refresh(String? businessId) async {
    _activeBusinessId = businessId ?? _activeBusinessId;
    final id = _activeBusinessId;
    if (id == null || id.isEmpty) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final source = await _repository.aggregate(id,
          start: _currentStart(), end: _currentEnd());
      _cacheSource(source);
      _rebuildData();
    } catch (e) {
      _errorMessage = _humanize(e);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Switches to one of the four built-in periods.
  ///
  /// If the user has previously picked a custom range, it's discarded — going
  /// back to a preset is a clear intent to "snap to default".
  Future<void> selectPeriod(ReportPeriod period) async {
    if (_period == period) return;
    _period = period;
    _customStart = null;
    _customEnd = null;
    await _refetchWindow();
  }

  /// Replaces the current period with a free-form date range.
  Future<void> selectCustomRange(DateTime start, DateTime end) async {
    _period = ReportPeriod.custom;
    final normalized = DateRangeResolver.resolve(
      ReportPeriod.custom,
      now: DateTime.now(),
      customStart: start,
      customEnd: end,
    );
    _customStart = normalized.$1;
    _customEnd = normalized.$2;
    await _refetchWindow();
  }

  /// Applies a category filter. Reuses the cached transactions — no Firestore
  /// trip.
  void selectCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    if (_cachedTransactions != null) {
      _rebuildData();
    } else {
      // We don't have a cache yet (no fetch has completed). Trigger a load
      // so the screen eventually has data; the filter is preserved.
      final id = _activeBusinessId;
      if (id != null && id.isNotEmpty) {
        _refetchWindow();
        return;
      }
    }
    notifyListeners();
  }

  /// Clears any active error without reloading.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ----- Internals -----

  Future<void> _refetchWindow() async {
    final id = _activeBusinessId;
    if (id == null || id.isEmpty) {
      _data = _emptyForPeriod(_period);
      notifyListeners();
      return;
    }
    await _fetch(id);
  }

  Future<void> _fetch(String businessId, {bool isInitial = false}) async {
    if (isInitial) {
      _isLoading = true;
    } else {
      // Switching periods shouldn't show the full-screen loading skeleton if
      // we already have data; treat it as a refresh so the user keeps seeing
      // the previous chart underneath.
      if (_data.isEmpty) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final source = await _repository.aggregate(
        businessId,
        start: _currentStart(),
        end: _currentEnd(),
      );
      _cacheSource(source);
      _rebuildData();
    } catch (e) {
      _errorMessage = _humanize(e);
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _cacheSource(ReportAggregateSource source) {
    _cachedTransactions = source.transactions;
    _cachedStart = _currentStart();
    _cachedEnd = _currentEnd();
    _customerDueCache = source.customerDue;
    _supplierDueCache = source.supplierDue;
  }

  void _rebuildData() {
    final txs = _cachedTransactions ?? const <TransactionModel>[];
    final start = _cachedStart ?? _currentStart();
    final end = _cachedEnd ?? _currentEnd();
    _data = ReportAggregator.aggregate(
      period: _period,
      start: start,
      end: end,
      transactions: txs,
      customerDue: _customerDueCache,
      supplierDue: _supplierDueCache,
      selectedCategory: _selectedCategory,
    );
  }

  (DateTime, DateTime) _currentRange() {
    return DateRangeResolver.resolve(
      _period,
      now: DateTime.now(),
      customStart: _customStart,
      customEnd: _customEnd,
    );
  }

  DateTime _currentStart() => _currentRange().$1;
  DateTime _currentEnd() => _currentRange().$2;

  EmptyReportData _emptyForPeriod(ReportPeriod period) {
    final range = DateRangeResolver.resolve(
      period,
      now: DateTime.now(),
      customStart: _customStart,
      customEnd: _customEnd,
    );
    return EmptyReportData(
      period: period,
      start: range.$1,
      end: range.$2,
    );
  }

  String _humanize(Object error) {
    final raw = error.toString();
    if (raw.contains('permission-denied') ||
        raw.contains('PERMISSION_DENIED')) {
      return 'You don\u2019t have access to this report.';
    }
    if (raw.contains('unavailable') || raw.contains('UNAVAILABLE')) {
      return 'Network unavailable. Check your connection and try again.';
    }
    return 'Something went wrong loading the report. Please try again.';
  }
}