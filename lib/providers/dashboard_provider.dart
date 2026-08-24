import 'package:flutter/foundation.dart';

import '../models/business.dart';
import '../models/transaction.dart';
import '../repositories/dashboard_repository.dart';

/// Snapshot of everything the dashboard needs to render in one frame.
class DashboardData {
  final double todaySales;
  final double todayExpense;
  final double todayProfit;
  final double monthIncome;
  final double monthExpense;
  final double monthProfit;
  final double customerDue;
  final double supplierDue;
  final List<TransactionModel> recentTransactions;
  final Business? business;

  const DashboardData({
    this.todaySales = 0,
    this.todayExpense = 0,
    this.todayProfit = 0,
    this.monthIncome = 0,
    this.monthExpense = 0,
    this.monthProfit = 0,
    this.customerDue = 0,
    this.supplierDue = 0,
    this.recentTransactions = const [],
    this.business,
  });

  DashboardData copyWith({
    double? todaySales,
    double? todayExpense,
    double? todayProfit,
    double? monthIncome,
    double? monthExpense,
    double? monthProfit,
    double? customerDue,
    double? supplierDue,
    List<TransactionModel>? recentTransactions,
    Business? business,
  }) {
    return DashboardData(
      todaySales: todaySales ?? this.todaySales,
      todayExpense: todayExpense ?? this.todayExpense,
      todayProfit: todayProfit ?? this.todayProfit,
      monthIncome: monthIncome ?? this.monthIncome,
      monthExpense: monthExpense ?? this.monthExpense,
      monthProfit: monthProfit ?? this.monthProfit,
      customerDue: customerDue ?? this.customerDue,
      supplierDue: supplierDue ?? this.supplierDue,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      business: business ?? this.business,
    );
  }
}

/// Owns the dashboard's view-state and triggers data loads through
/// [DashboardRepository]. The screen never touches Firestore directly.
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardData _data = const DashboardData();
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _userFacingError;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _userFacingError;
  DashboardData get data => _data;

  DashboardProvider({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository();

  Future<void> loadDashboard(String? businessId) async {
    if (businessId == null || businessId.isEmpty) {
      _data = const DashboardData();
      _userFacingError = null;
      notifyListeners();
      return;
    }

    final isFirstLoad = !_isLoading && _data == const DashboardData();
    if (isFirstLoad) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    _userFacingError = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _repository.getBusiness(businessId),
        _repository.getTransactionsInRange(
          businessId,
          start: _startOfMonth(),
          end: _endOfMonth(),
        ),
        _repository.getTotalCustomerDue(businessId),
        _repository.getTotalSupplierDue(businessId),
      ]);

      final business = results[0] as Business?;
      final monthTransactions =
          (results[1] as List<TransactionModel>?) ?? const <TransactionModel>[];
      final customerDue = (results[2] as num?)?.toDouble() ?? 0;
      final supplierDue = (results[3] as num?)?.toDouble() ?? 0;

      final startOfDay = _startOfDay();
      final endOfDay = _endOfDay();
      double todaySales = 0;
      double todayExpense = 0;
      double monthIncome = 0;
      double monthExpense = 0;

      for (final t in monthTransactions) {
        if (t.type == TransactionType.income) {
          monthIncome += t.amount;
          if (!t.date.isBefore(startOfDay) && !t.date.isAfter(endOfDay)) {
            todaySales += t.amount;
          }
        } else {
          monthExpense += t.amount;
          if (!t.date.isBefore(startOfDay) && !t.date.isAfter(endOfDay)) {
            todayExpense += t.amount;
          }
        }
      }

      final sorted = List<TransactionModel>.from(monthTransactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      final recent = sorted.take(10).toList(growable: false);

      _data = DashboardData(
        todaySales: todaySales,
        todayExpense: todayExpense,
        todayProfit: todaySales - todayExpense,
        monthIncome: monthIncome,
        monthExpense: monthExpense,
        monthProfit: monthIncome - monthExpense,
        customerDue: customerDue,
        supplierDue: supplierDue,
        recentTransactions: recent,
        business: business,
      );
      _userFacingError = null;
    } catch (e, st) {
      debugPrint('DashboardProvider.loadDashboard error: $e\n$st');
      _userFacingError =
          "We couldn't load your dashboard right now. Please try again.";
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String? businessId) async {
    await loadDashboard(businessId);
  }

  void clearError() {
    if (_userFacingError == null) return;
    _userFacingError = null;
    notifyListeners();
  }

  static DateTime _startOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _endOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  static DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime _endOfMonth() {
    final now = DateTime.now();
    final nextMonth = (now.month == 12)
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
}
