import '../../../models/transaction.dart';
import '../models/report_data.dart';

/// Pure, side-effect-free aggregation logic for the Reports screen.
///
/// Kept separate from the provider so it can be unit-tested with hand-built
/// transaction fixtures. The provider calls this once per (period, range,
/// filter) change; the screen never mutates transactions itself.
class ReportAggregator {
  const ReportAggregator._();

  /// Builds a [ReportData] snapshot from raw inputs.
  ///
  /// [transactions] is the full fetched set for the window — this method
  /// filters in-memory rather than refetching when the active category filter
  /// changes.
  ///
  /// [customerDue] / [supplierDue] are the business's outstanding totals as of
  /// "now" (the existing repos already compute these). The aggregator just
  /// passes them through; filtering doesn't affect them.
  static ReportData aggregate({
    required ReportPeriod period,
    required DateTime start,
    required DateTime end,
    required List<TransactionModel> transactions,
    required double customerDue,
    required double supplierDue,
    String? selectedCategory,
  }) {
    if (transactions.isEmpty &&
        customerDue == 0 &&
        supplierDue == 0) {
      return EmptyReportData(period: period, start: start, end: end);
    }

    // Build category maps in a single pass. We keep two maps so the Income
    // donut and Expense donut don't bleed into each other.
    final incomeByCategory = <String, _CategoryAccumulator>{};
    final expenseByCategory = <String, _CategoryAccumulator>{};

    double totalIncome = 0;
    double totalExpense = 0;
    int totalCount = 0;

    for (final t in transactions) {
      // Drop transactions that fall outside the requested window defensively.
      // Firestore already filtered by the same bounds server-side, but a
      // bad doc with a corrupted `date` field could slip through and we don't
      // want it to poison the chart.
      if (t.date.isBefore(start) || t.date.isAfter(end)) continue;

      totalCount += 1;
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
        final acc = incomeByCategory.putIfAbsent(
          t.category.isEmpty ? 'Uncategorized' : t.category,
          () => _CategoryAccumulator(),
        );
        acc.add(t.amount);
      } else {
        totalExpense += t.amount;
        final acc = expenseByCategory.putIfAbsent(
          t.category.isEmpty ? 'Uncategorized' : t.category,
          () => _CategoryAccumulator(),
        );
        acc.add(t.amount);
      }
    }

    final trend = _buildTrendBuckets(transactions, start, end);

    // Union of categories, alphabetically sorted, for the filter chips.
    final allCategories = <String>{
      ...incomeByCategory.keys,
      ...expenseByCategory.keys,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ReportData(
      period: period,
      start: start,
      end: end,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      customerDue: customerDue,
      supplierDue: supplierDue,
      incomeByCategory: _toSortedList(incomeByCategory),
      expenseByCategory: _toSortedList(expenseByCategory),
      trendBuckets: trend,
      selectedCategory: selectedCategory,
      categoryOptions: allCategories,
      totalTransactionCount: totalCount,
    );
  }

  /// Builds one bucket per day from [start] to [end] inclusive. Days with no
  /// transactions get zero-filled so the line chart renders a continuous axis.
  static List<ReportBucket> _buildTrendBuckets(
    List<TransactionModel> transactions,
    DateTime start,
    DateTime end,
  ) {
    // Cap bucket count at 60 to keep chart rendering cheap — Monthly on a
    // 31-day month produces 31 buckets which is fine; anything more than 60
    // (e.g. a custom range spanning two months) is still readable when we
    // collapse by sampling, but for now we keep all points and rely on
    // fl_chart's auto-decimation.
    final days = end.difference(start).inDays;
    if (days < 0) return const [];

    final bucketCount = days + 1;
    final incomes = List<double>.filled(bucketCount, 0);
    final expenses = List<double>.filled(bucketCount, 0);

    for (final t in transactions) {
      if (t.date.isBefore(start) || t.date.isAfter(end)) continue;
      final dayKey =
          DateTime(t.date.year, t.date.month, t.date.day);
      final diff = dayKey.difference(start).inDays;
      if (diff < 0 || diff >= bucketCount) continue;
      if (t.type == TransactionType.income) {
        incomes[diff] += t.amount;
      } else {
        expenses[diff] += t.amount;
      }
    }

    return List<ReportBucket>.generate(bucketCount, (i) {
      final label = DateTime(start.year, start.month, start.day + i);
      return ReportBucket(
        label: label,
        income: incomes[i],
        expense: expenses[i],
      );
    }, growable: false);
  }

  static List<ReportCategoryTotal> _toSortedList(
      Map<String, _CategoryAccumulator> source) {
    final list = source.entries
        .map((e) => ReportCategoryTotal(
              category: e.key,
              amount: e.value.amount,
              count: e.value.count,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return List<ReportCategoryTotal>.unmodifiable(list);
  }
}

class _CategoryAccumulator {
  double amount = 0;
  int count = 0;

  void add(double value) {
    amount += value;
    count += 1;
  }
}
