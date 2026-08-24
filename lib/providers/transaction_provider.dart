import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../services/due_recalculation_coordinator.dart';

/// Active filter snapshot for the Transaction History screen.
///
/// Date range is inclusive on both ends. [type] is `null` for "All".
/// [category] is `null` for "All". The provider treats this object as
/// immutable; call [TransactionProvider.applyHistoryFilter] to swap it.
@immutable
class HistoryFilter {
  final DateTime startDate;
  final DateTime endDate;
  final TransactionType? type;
  final String? category;

  const HistoryFilter({
    required this.startDate,
    required this.endDate,
    this.type,
    this.category,
  });

  /// Default window: first-of-month → today. Captured at the call-site so a
  /// long-lived provider doesn't drift while the user keeps the app open.
  factory HistoryFilter.defaultRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day);
    return HistoryFilter(startDate: start, endDate: end);
  }

  HistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? category,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return HistoryFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryFilter &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.type == type &&
          other.category == category);

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, type, category);
}

/// Converts raw [Exception] / [Error] objects thrown by the Firestore stack
/// into friendly English strings safe to show to the user. Used by the
/// strongly-typed income mutators below so error SnackBars never surface
/// raw stack traces.
String _userFacingTransactionError(Object error, String action) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('networkerror') ||
      raw.contains('failed host lookup') ||
      raw.contains('no address associated with hostname')) {
    return 'Network error. Please check your internet connection and try again.';
  }
  if (raw.contains('permission-denied') || raw.contains('permission_denied')) {
    return 'You do not have permission to $action this transaction.';
  }
  if (raw.contains('timeout')) {
    return 'The request timed out. Please try again.';
  }
  return 'Failed to $action the transaction. Please try again.';
}

/// Owns the view-state of the Transactions features and routes all writes
/// through [TransactionRepository]. Income flows go through the strongly-typed
/// helpers ([addIncome], [updateIncomeModel], [deleteIncome]) which enforce
/// field requirements + duplicate-submit protection.
class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  /// True while a **submit** is in flight (add / update / delete). Lets the
  /// form button lock while a tap is still being processed by Firestore so
  /// rapid double-taps can't create duplicate records.
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _searchQuery;
  TransactionType? _typeFilter;
  String? _categoryFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  /// Cached income-only list produced by [loadIncome]. The income list
  /// screen reads from here so refreshes propagate without re-fetching.
  List<TransactionModel> _incomeList = [];

  /// Cached expense-only list produced by [loadExpense]. The expense list
  /// screen reads from here so refreshes propagate without re-fetching.
  List<TransactionModel> _expenseList = [];

  /// Coordinator that updates customer / supplier outstanding-due totals after
  /// a transaction is added, edited or deleted. Holds a [DueRecalculationCoordinator]
  /// so callers (forms, tests) can inject a custom coordinator if needed.
  final DueRecalculationCoordinator _dueCoordinator;
  List<TransactionModel> get expenseList => _expenseList;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  TransactionType? get typeFilter => _typeFilter;

  /// Public, in-memory, search/filter-aware view of the transactions loaded
  /// via [setTransactions]. The transaction list screen binds to this getter.
  List<TransactionModel> get transactions {
    final filtered = List<TransactionModel>.from(_transactions);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered.retainWhere((t) =>
          t.category.toLowerCase().contains(query) ||
          (t.note?.toLowerCase().contains(query) ?? false));
    }

    if (_typeFilter != null) {
      filtered.retainWhere((t) => t.type == _typeFilter);
    }

    if (_categoryFilter != null && _categoryFilter!.isNotEmpty) {
      filtered.retainWhere((t) => t.category == _categoryFilter);
    }

    if (_startDate != null) {
      filtered.retainWhere((t) => t.date.isAfter(_startDate!));
    }

    if (_endDate != null) {
      filtered.retainWhere(
          (t) => t.date.isBefore(_endDate!.add(const Duration(days: 1))));
    }

    return filtered;
  }

  TransactionProvider({
    TransactionRepository? repository,
    DueRecalculationCoordinator? dueCoordinator,
  })  : _repository = repository ?? TransactionRepository(),
        _dueCoordinator = dueCoordinator ?? DueRecalculationCoordinator();

  /// Returns the most recently streamed version of [transaction] from the
  /// cached income/expense list, or `null` if it has never been observed.
  /// Used to supply the [DueRecalculationCoordinator.recompute] call with a
  /// "previous" snapshot so it can fix up the old customer/supplier when the
  /// user reassigns a transaction.
  TransactionModel? _existingSnapshotOf(TransactionModel transaction) {
    final id = transaction.id;
    if (id.isEmpty) return null;
    if (transaction.type == TransactionType.income) {
      for (final t in _incomeList) {
        if (t.id == id) return t;
      }
    } else {
      for (final t in _expenseList) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  /// Public passthrough that lets callers (e.g. record-payment flows) force
  /// a customer-due recompute without touching any transaction.
  Future<void> recomputeCustomerDue({
    required String businessId,
    required String customerId,
  }) {
    return _dueCoordinator.recomputeCustomer(
      businessId: businessId,
      customerId: customerId,
    );
  }

  /// Public passthrough that lets callers force a supplier-due recompute.
  Future<void> recomputeSupplierDue({
    required String businessId,
    required String supplierId,
  }) {
    return _dueCoordinator.recomputeSupplier(
      businessId: businessId,
      supplierId: supplierId,
    );
  }

  Stream<List<TransactionModel>> watchTransactions(String businessId) {
    return _repository.streamTransactions(businessId);
  }

  /// Replaces the in-memory list backing [transactions] / [transactions].
  /// Called by the existing list screen after a snapshot is delivered.
  void setTransactions(List<TransactionModel> transactions) {
    _transactions = transactions;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clears the last error message so the user can retry without seeing the
  /// previous failure on top of the new SnackBar.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _typeFilter = null;
    _categoryFilter = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  /// ----------------------------- INCOME FLOW -----------------------------

  /// Loads all income transactions into [_incomeList]. Used by the income
  /// list screen on first open. The screen then subscribes to
  /// [watchIncome] for live updates so we keep both paths.
  Future<void> loadIncome(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _repository.getTransactions(
        businessId,
        type: 'income',
      );
      list.sort((a, b) => b.date.compareTo(a.date));
      _incomeList = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'load');
      notifyListeners();
    }
  }

  /// Live stream of income transactions ordered by date desc. The income
  /// list screen subscribes via a StreamBuilder, and we also update the
  /// cached [_incomeList] so the screen refreshes in-place.
  Stream<List<TransactionModel>> watchIncome(String businessId) {
    return _repository.streamTransactionsByType(
      businessId,
      TransactionType.income,
    );
  }

  /// Strongly-typed income create. Returns the new Firestore id or `null`
  /// on failure (check [errorMessage] for the reason). Guards against
  /// duplicate submission via [_isSubmitting].
  Future<String?> addIncome(TransactionModel transaction) async {
    if (_isSubmitting) return null;
    if (transaction.type != TransactionType.income) {
      _errorMessage = 'Only income transactions can be added through this flow.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _repository.addTransaction(transaction);
      _isSubmitting = false;
      _isLoading = false;
      // Fire-and-forget: refresh customer / supplier due totals in the
      // background after the income row has been persisted. We don't await
      // because the user has already confirmed the form and we don't want to
      // block their next tap.
      _dueCoordinator.recompute(newTransaction: transaction);
      notifyListeners();
      return id;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'add');
      notifyListeners();
      return null;
    }
  }

  /// Strongly-typed income update. Performs an extra ownership check before
  /// letting the Firestore write proceed so the user gets a friendlier
  /// message than a permission-denied error.
  Future<bool> updateIncomeModel(
    TransactionModel updated, {
    required String currentUserId,
  }) async {
    if (_isSubmitting) return false;
    if (updated.type != TransactionType.income) {
      _errorMessage = 'Only income transactions can be updated through this flow.';
      notifyListeners();
      return false;
    }
    if (updated.userId != currentUserId) {
      _errorMessage = 'You can only edit your own transactions.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final previous = _existingSnapshotOf(updated);
      final patched = updated.copyWith(updatedAt: DateTime.now());
      final data = patched.toMap();
      // toMap already encodes timestamps; the repository layer will append
      // its own updatedAt if missing, but we keep ours for consistency.
      data['updatedAt'] = Timestamp.fromDate(patched.updatedAt);
      await _repository.updateTransaction(
        patched.businessId,
        patched.id,
        data,
      );
      _isSubmitting = false;
      _isLoading = false;
      // Recalc the affected customer / supplier so any change in amount,
      // category, payment method or customerId reflects immediately.
      _dueCoordinator.recompute(
        newTransaction: patched,
        previousTransaction: previous,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'update');
      notifyListeners();
      return false;
    }
  }

  /// Strongly-typed income delete. Refuses if the transaction wasn't owned
  /// by the caller. Firestore rules already enforce this, but the
  /// pre-check produces a friendlier error message.
  Future<bool> deleteIncome(
    TransactionModel transaction, {
    required String currentUserId,
  }) async {
    if (_isSubmitting) return false;
    if (transaction.userId != currentUserId) {
      _errorMessage = 'You can only delete your own transactions.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteTransaction(
        transaction.businessId,
        transaction.id,
      );
      _isSubmitting = false;
      _isLoading = false;
      // Recalc the affected customer / supplier so deleting a credit sale
      // drops the customer's due balance immediately.
      _dueCoordinator.recomputeAfterDelete(transaction);
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'delete');
      notifyListeners();
      return false;
    }
  }

/// Replaces [incomeList] in-place. Used by the income list screen when
  /// it receives a new snapshot so the cached list stays in sync.
  void setIncomeList(List<TransactionModel> list) {
    final sorted = List<TransactionModel>.from(list)
      ..sort((a, b) => b.date.compareTo(a.date));
    _incomeList = sorted;
    notifyListeners();
  }

  /// ----------------------------- EXPENSE FLOW ------------------------------

  /// Loads all expense transactions into [_expenseList]. Used by the expense
  /// list screen on first open. The screen then subscribes to
  /// [watchExpense] for live updates so we keep both paths.
  Future<void> loadExpense(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _repository.getTransactions(
        businessId,
        type: 'expense',
      );
      list.sort((a, b) => b.date.compareTo(a.date));
      _expenseList = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'load');
      notifyListeners();
    }
  }

  /// Live stream of expense transactions ordered by date desc. The expense
  /// list screen subscribes via a StreamBuilder, and we also update the
  /// cached [_expenseList] so the screen refreshes in-place.
  Stream<List<TransactionModel>> watchExpense(String businessId) {
    return _repository.streamTransactionsByType(
      businessId,
      TransactionType.expense,
    );
  }

  /// Strongly-typed expense create. Returns the new Firestore id or `null`
  /// on failure (check [errorMessage] for the reason). Guards against
  /// duplicate submission via [_isSubmitting].
  Future<String?> addExpense(TransactionModel transaction) async {
    if (_isSubmitting) return null;
    if (transaction.type != TransactionType.expense) {
      _errorMessage =
          'Only expense transactions can be added through this flow.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _repository.addTransaction(transaction);
      _isSubmitting = false;
      _isLoading = false;
      _dueCoordinator.recompute(newTransaction: transaction);
      notifyListeners();
      return id;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'add');
      notifyListeners();
      return null;
    }
  }

  /// Strongly-typed expense update. Performs an extra ownership check before
  /// letting the Firestore write proceed so the user gets a friendlier
  /// message than a permission-denied error.
  Future<bool> updateExpenseModel(
    TransactionModel updated, {
    required String currentUserId,
  }) async {
    if (_isSubmitting) return false;
    if (updated.type != TransactionType.expense) {
      _errorMessage =
          'Only expense transactions can be updated through this flow.';
      notifyListeners();
      return false;
    }
    if (updated.userId != currentUserId) {
      _errorMessage = 'You can only edit your own transactions.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final previous = _existingSnapshotOf(updated);
      final patched = updated.copyWith(updatedAt: DateTime.now());
      final data = patched.toMap();
      // toMap already encodes timestamps; the repository layer will append
      // its own updatedAt if missing, but we keep ours for consistency.
      data['updatedAt'] = Timestamp.fromDate(patched.updatedAt);
      await _repository.updateTransaction(
        patched.businessId,
        patched.id,
        data,
      );
      _isSubmitting = false;
      _isLoading = false;
      _dueCoordinator.recompute(
        newTransaction: patched,
        previousTransaction: previous,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'update');
      notifyListeners();
      return false;
    }
  }

  /// Strongly-typed expense delete. Refuses if the transaction wasn't owned
  /// by the caller. Firestore rules already enforce this, but the
  /// pre-check produces a friendlier error message.
  Future<bool> deleteExpense(
    TransactionModel transaction, {
    required String currentUserId,
  }) async {
    if (_isSubmitting) return false;
    if (transaction.userId != currentUserId) {
      _errorMessage = 'You can only delete your own transactions.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteTransaction(
        transaction.businessId,
        transaction.id,
      );
      _isSubmitting = false;
      _isLoading = false;
      _dueCoordinator.recomputeAfterDelete(transaction);
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'delete');
      notifyListeners();
      return false;
    }
  }

  /// Replaces [expenseList] in-place. Used by the expense list screen when
  /// it receives a new snapshot so the cached list stays in sync.
  void setExpenseList(List<TransactionModel> list) {
    final sorted = List<TransactionModel>.from(list)
      ..sort((a, b) => b.date.compareTo(a.date));
    _expenseList = sorted;
    notifyListeners();
  }

  /// ----------------------- HISTORY (TransactionsScreen) ---------------------

  /// Default page size. Picked to be small enough to feel snappy on cold
  /// networks yet large enough that two pages cover a typical month of
  /// small-business activity.
  static const int _historyPageSize = 25;

  final List<TransactionModel> _historyItems = [];
  HistoryFilter? _historyFilter;
  String _historySearch = '';
  DocumentSnapshot? _historyCursor;
  bool _historyHasMore = false;
  bool _historyLoadingFirstPage = false;
  bool _historyLoadingMore = false;
  String? _historyErrorMessage;
  ({double totalIncome, double totalExpense, int count}) _historySummary =
      (totalIncome: 0, totalExpense: 0, count: 0);

  /// Visible page (search + category-filtered). The provider always returns
  /// this so the screen never has to duplicate the filter logic.
  List<TransactionModel> get history => _applyHistorySearch(
        _applyHistoryCategory(_historyItems),
      );

  HistoryFilter? get historyFilter => _historyFilter;
  String get historySearch => _historySearch;
  bool get historyHasMore => _historyHasMore;
  bool get historyLoadingFirstPage => _historyLoadingFirstPage;
  bool get historyLoadingMore => _historyLoadingMore;
  String? get historyErrorMessage => _historyErrorMessage;
  ({double totalIncome, double totalExpense, int count})
      get historySummary => _historySummary;

  List<TransactionModel> _applyHistoryCategory(List<TransactionModel> items) {
    final cat = _historyFilter?.category;
    if (cat == null || cat.isEmpty) return items;
    return items.where((t) => t.category == cat).toList();
  }

  List<TransactionModel> _applyHistorySearch(List<TransactionModel> items) {
    final q = _historySearch.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((t) {
      final category = t.category.toLowerCase();
      final note = (t.note ?? '').toLowerCase();
      final payment = t.paymentMethod.toLowerCase();
      // Per spec: search by category + note. We additionally match payment
      // method to make the search box feel useful without an extra button.
      return category.contains(q) ||
          note.contains(q) ||
          payment.contains(q);
    }).toList();
  }

  /// First page of the active filter. Replaces the in-memory page list and
  /// resets the cursor. Safe to call repeatedly — each call wipes state.
  Future<void> loadFirstHistoryPage(String businessId) async {
    if (_historyLoadingFirstPage) return;

    final filter = _historyFilter ?? HistoryFilter.defaultRange();
    _historyFilter = filter;
    _historyLoadingFirstPage = true;
    _historyErrorMessage = null;
    _historyItems.clear();
    _historyCursor = null;
    _historyHasMore = false;
    notifyListeners();

    try {
      final page = await _repository.fetchTransactionsPage(
        businessId: businessId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        type: filter.type,
        pageSize: _historyPageSize,
      );
      _historyItems
        ..clear()
        ..addAll(page.items);
      _historyCursor = page.lastDocument;
      _historyHasMore = page.items.length >= _historyPageSize;
      await _refreshHistorySummary(businessId, filter);
      _historyLoadingFirstPage = false;
      notifyListeners();
    } catch (e) {
      _historyLoadingFirstPage = false;
      _historyErrorMessage = _userFacingTransactionError(e, 'load');
      notifyListeners();
    }
  }

  /// Loads the next slice using the cached cursor. No-op when:
  ///   * there is no filter (must call loadFirstHistoryPage first),
  ///   * we already know there are no more pages,
  ///   * a page load is currently in flight.
  Future<void> loadNextHistoryPage(String businessId) async {
    final filter = _historyFilter;
    if (filter == null) return;
    if (_historyLoadingMore || _historyLoadingFirstPage) return;
    if (!_historyHasMore || _historyCursor == null) return;

    _historyLoadingMore = true;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.fetchTransactionsPage(
        businessId: businessId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        type: filter.type,
        pageSize: _historyPageSize,
        startAfter: _historyCursor,
      );
      _historyItems.addAll(page.items);
      _historyCursor = page.lastDocument;
      // A short page (fewer than pageSize) means there were no more results.
      _historyHasMore = page.items.length >= _historyPageSize;
      _historyLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _historyLoadingMore = false;
      _historyErrorMessage = _userFacingTransactionError(e, 'load more');
      notifyListeners();
    }
  }

  /// Restarts pagination with a new filter — equivalent to
  /// `loadFirstHistoryPage` after applying the filter.
  Future<void> applyHistoryFilter(
    String businessId, {
    required HistoryFilter filter,
  }) async {
    _historyFilter = filter;
    _historySearch = '';
    await loadFirstHistoryPage(businessId);
  }

  /// Updates the search query. Client-side only — server-side full-text
  /// search needs an external index and a small in-page filter keeps UX
  /// instant.
  void setHistorySearch(String? query) {
    final next = (query ?? '').trim();
    if (next == _historySearch) return;
    _historySearch = next;
    notifyListeners();
  }

  /// Clears every history filter, search and pagination cursor. The caller
  /// is responsible for re-issuing `loadFirstHistoryPage` afterwards.
  void resetHistory() {
    _historyItems.clear();
    _historyFilter = null;
    _historySearch = '';
    _historyCursor = null;
    _historyHasMore = false;
    _historyErrorMessage = null;
    _historySummary =
        (totalIncome: 0, totalExpense: 0, count: 0);
    notifyListeners();
  }

  Future<void> _refreshHistorySummary(
    String businessId,
    HistoryFilter filter,
  ) async {
    try {
      final summary = await _repository.summarizeWindow(
        businessId: businessId,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
      _historySummary = summary;
    } catch (_) {
      // Summary is decorative — don't propagate its failure as a hard error.
      _historySummary =
          (totalIncome: 0, totalExpense: 0, count: 0);
    }
  }

  /// -------------- Legacy untyped methods (kept for compatibility) --------------

  Future<String?> addTransaction(TransactionModel transaction) async {
    try {
      _isLoading = true;
      notifyListeners();
      final id = await _repository.addTransaction(transaction);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'save');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTransaction(
      String businessId, String transactionId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.updateTransaction(businessId, transactionId, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'update');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(
      String businessId, String transactionId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _repository.deleteTransaction(businessId, transactionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingTransactionError(e, 'delete');
      notifyListeners();
      return false;
    }
  }
}
