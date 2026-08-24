import '../../../models/transaction.dart';

/// The four report periods the user can pick from.
enum ReportPeriod { daily, weekly, monthly, custom }

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReportPeriod.daily:
        return 'Today';
      case ReportPeriod.weekly:
        return 'Last 7 days';
      case ReportPeriod.monthly:
        return 'This month';
      case ReportPeriod.custom:
        return 'Custom range';
    }
  }
}

/// One category row in the breakdown lists (Sales, Rent, etc.).
class ReportCategoryTotal {
  final String category;
  final double amount;
  final int count;

  const ReportCategoryTotal({
    required this.category,
    required this.amount,
    required this.count,
  });
}

/// One day bucket used by the Profit-Trend line chart.
///
/// `label` is the day's midnight (local time); income/expense are sums of all
/// transactions that fall on that date.
class ReportBucket {
  final DateTime label;
  final double income;
  final double expense;

  const ReportBucket({
    required this.label,
    required this.income,
    required this.expense,
  });

  double get netProfit => income - expense;
}

/// Immutable snapshot of everything a reports screen needs to render one
/// frame. Built by [ReportAggregator] (pure) and consumed by the widgets.
///
/// `selectedCategory` doubles as the active filter — `null` means "show
/// everything". When set, breakdowns/donut render that single category while
/// totals still reflect the unfiltered window so the summary stays stable.
class ReportData {
  final ReportPeriod period;
  final DateTime start;
  final DateTime end;
  final double totalIncome;
  final double totalExpense;
  final double customerDue;
  final double supplierDue;
  final List<ReportCategoryTotal> incomeByCategory;
  final List<ReportCategoryTotal> expenseByCategory;
  final List<ReportBucket> trendBuckets;
  final String? selectedCategory;
  final List<String> categoryOptions;
  final int totalTransactionCount;

  const ReportData({
    required this.period,
    required this.start,
    required this.end,
    required this.totalIncome,
    required this.totalExpense,
    required this.customerDue,
    required this.supplierDue,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.trendBuckets,
    required this.selectedCategory,
    required this.categoryOptions,
    required this.totalTransactionCount,
  });

  double get netProfit => totalIncome - totalExpense;

  /// Profit margin as a percentage of total income. Returns 0 when income is 0
  /// (avoids divide-by-zero and keeps the UI from showing "NaN%").
  double get profitMargin =>
      totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

  bool get isEmpty =>
      totalIncome == 0 &&
      totalExpense == 0 &&
      totalTransactionCount == 0;

  bool get hasIncome => totalIncome > 0;
  bool get hasExpense => totalExpense > 0;
  bool get hasAnyData => hasIncome || hasExpense;

  /// Income/expense breakdowns already filtered to the active category when
  /// one is selected. The provider is responsible for shaping these.
  List<ReportCategoryTotal> get filteredIncomeByCategory {
    if (selectedCategory == null) return incomeByCategory;
    return incomeByCategory
        .where((c) => c.category == selectedCategory)
        .toList(growable: false);
  }

  List<ReportCategoryTotal> get filteredExpenseByCategory {
    if (selectedCategory == null) return expenseByCategory;
    return expenseByCategory
        .where((c) => c.category == selectedCategory)
        .toList(growable: false);
  }

  /// Convenience: the visible (filtered) income and expense totals for a
  /// single category. Used to recompute the "Filtered" preview chip on the
  /// filter chips row.
  double get filteredIncomeAmount => filteredIncomeByCategory.fold<double>(
        0,
        (sum, c) => sum + c.amount,
      );

  double get filteredExpenseAmount => filteredExpenseByCategory.fold<double>(
        0,
        (sum, c) => sum + c.amount,
      );

  /// Number of days between start and end (inclusive). Used by widgets that
  /// want to render bucket labels without re-deriving the math.
  int get dayCount => end.difference(start).inDays + 1;
}

/// Marker for "no data available" reports — the screen renders an
/// `EmptyWidget` when this is produced.
class EmptyReportData extends ReportData {
  const EmptyReportData({
    required super.period,
    required super.start,
    required super.end,
  }) : super(
          totalIncome: 0,
          totalExpense: 0,
          customerDue: 0,
          supplierDue: 0,
          incomeByCategory: const [],
          expenseByCategory: const [],
          trendBuckets: const [],
          selectedCategory: null,
          categoryOptions: const [],
          totalTransactionCount: 0,
        );
}

/// Filter expression passed to the aggregator. Keeps the signature
/// future-proof — we can add payment-method / customer-id filters later
/// without breaking callers.
class ReportFilter {
  final String? category;
  final TransactionType? type;

  const ReportFilter({this.category, this.type});

  static const ReportFilter none = ReportFilter();

  bool get isActive => category != null || type != null;

  ReportFilter copyWith({String? category, TransactionType? type, bool clearCategory = false, bool clearType = false}) {
    return ReportFilter(
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
    );
  }
}
