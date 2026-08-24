import 'package:flutter_test/flutter_test.dart';

import 'package:bizhisab_ai/features/reports/models/report_data.dart';
import 'package:bizhisab_ai/features/reports/utils/date_range_resolver.dart';
import 'package:bizhisab_ai/features/reports/utils/report_aggregator.dart';
import 'package:bizhisab_ai/models/transaction.dart';

TransactionModel _tx({
  required String id,
  required TransactionType type,
  required String category,
  required double amount,
  required DateTime date,
  String? note,
}) {
  return TransactionModel(
    id: id,
    userId: 'u',
    businessId: 'b',
    type: type,
    amount: amount,
    category: category,
    date: date,
    note: note,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('ReportAggregator', () {
    final today = DateTime(2025, 6, 15);
    final yesterday = DateTime(2025, 6, 14);
    final tenDaysAgo = DateTime(2025, 6, 5);

    test('returns EmptyReportData when no inputs are provided', () {
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: const [],
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result, isA<EmptyReportData>());
      expect(result.totalIncome, 0);
      expect(result.totalExpense, 0);
      expect(result.netProfit, 0);
    });

    test('totals are correctly split by type', () {
      final txs = [
        _tx(id: '1', type: TransactionType.income, category: 'Sales',
            amount: 1000, date: today),
        _tx(id: '2', type: TransactionType.income, category: 'Sales',
            amount: 500, date: today),
        _tx(id: '3', type: TransactionType.expense, category: 'Rent',
            amount: 300, date: today),
      ];

      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 200,
        supplierDue: 50,
      );

      expect(result.totalIncome, 1500);
      expect(result.totalExpense, 300);
      expect(result.netProfit, 1200);
      expect(result.profitMargin, closeTo(80.0, 0.01));
      expect(result.customerDue, 200);
      expect(result.supplierDue, 50);
    });

    test('profit margin returns 0 when there is no income', () {
      final txs = [
        _tx(id: '1', type: TransactionType.expense, category: 'Rent',
            amount: 100, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.profitMargin, 0);
      expect(result.netProfit, -100);
    });

    test('category splits are sorted by amount descending', () {
      final txs = [
        _tx(id: '1', type: TransactionType.expense, category: 'Rent',
            amount: 100, date: today),
        _tx(id: '2', type: TransactionType.expense, category: 'Food',
            amount: 400, date: today),
        _tx(id: '3', type: TransactionType.expense, category: 'Travel',
            amount: 250, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.expenseByCategory.map((c) => c.category).toList(),
          ['Food', 'Travel', 'Rent']);
      expect(result.expenseByCategory.map((c) => c.count).toList(), [1, 1, 1]);
    });

    test('income and expense categories are kept separate', () {
      final txs = [
        _tx(id: '1', type: TransactionType.income, category: 'Sales',
            amount: 100, date: today),
        _tx(id: '2', type: TransactionType.expense, category: 'Sales',
            amount: 50, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.incomeByCategory.length, 1);
      expect(result.expenseByCategory.length, 1);
      expect(result.incomeByCategory.first.category, 'Sales');
      expect(result.expenseByCategory.first.category, 'Sales');
    });

    test('transactions outside the window are dropped', () {
      final txs = [
        _tx(id: '1', type: TransactionType.income, category: 'Sales',
            amount: 100, date: today),
        _tx(id: '2', type: TransactionType.income, category: 'Sales',
            amount: 999, date: yesterday), // outside today's window
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.totalIncome, 100);
      expect(result.totalTransactionCount, 1);
    });

    test('daily buckets are zero-filled across the window', () {
      final txs = [
        _tx(id: '1', type: TransactionType.income, category: 'Sales',
            amount: 100, date: tenDaysAgo),
        _tx(id: '2', type: TransactionType.expense, category: 'Rent',
            amount: 50, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.custom,
        start: tenDaysAgo,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.trendBuckets.length, 11);
      expect(result.trendBuckets.first.income, 100);
      expect(result.trendBuckets.first.expense, 0);
      expect(result.trendBuckets.last.income, 0);
      expect(result.trendBuckets.last.expense, 50);
    });

    test('category filter narrows the visible lists', () {
      final txs = [
        _tx(id: '1', type: TransactionType.income, category: 'Sales',
            amount: 100, date: today),
        _tx(id: '2', type: TransactionType.income, category: 'Other',
            amount: 50, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
        selectedCategory: 'Sales',
      );
      expect(result.selectedCategory, 'Sales');
      expect(result.filteredIncomeByCategory.length, 1);
      expect(result.filteredIncomeByCategory.first.category, 'Sales');
      expect(result.filteredIncomeAmount, 100);
      // Totals stay unfiltered so the summary doesn't flicker on filter changes.
      expect(result.totalIncome, 150);
    });

    test('customer and supplier due pass through unchanged', () {
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.monthly,
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 6, 30, 23, 59, 59),
        transactions: const [],
        customerDue: 1234.5,
        supplierDue: 6789.0,
      );
      expect(result.customerDue, 1234.5);
      expect(result.supplierDue, 6789.0);
    });

    test('empty category falls back to Uncategorized', () {
      final txs = [
        _tx(id: '1', type: TransactionType.expense, category: '',
            amount: 50, date: today),
      ];
      final result = ReportAggregator.aggregate(
        period: ReportPeriod.daily,
        start: today,
        end: today,
        transactions: txs,
        customerDue: 0,
        supplierDue: 0,
      );
      expect(result.expenseByCategory.first.category, 'Uncategorized');
    });
  });

  group('DateRangeResolver', () {
    test('daily resolves to a single-day inclusive window', () {
      final now = DateTime(2025, 6, 15, 14, 30);
      final (start, end) = DateRangeResolver.resolve(
        ReportPeriod.daily,
        now: now,
      );
      expect(start, DateTime(2025, 6, 15));
      expect(end, DateTime(2025, 6, 15, 23, 59, 59, 999));
    });

    test('weekly covers the trailing 7 days inclusive', () {
      final now = DateTime(2025, 6, 15, 10);
      final (start, end) = DateRangeResolver.resolve(
        ReportPeriod.weekly,
        now: now,
      );
      expect(start, DateTime(2025, 6, 9));
      expect(end, DateTime(2025, 6, 15, 23, 59, 59, 999));
    });

    test('monthly covers the first through last day of the month', () {
      final now = DateTime(2025, 2, 10);
      final (start, end) = DateRangeResolver.resolve(
        ReportPeriod.monthly,
        now: now,
      );
      expect(start, DateTime(2025, 2, 1));
      expect(end, DateTime(2025, 2, 28, 23, 59, 59, 999));
    });

    test('custom range is normalized (start > end is swapped)', () {
      final now = DateTime(2025, 6, 15);
      final (start, end) = DateRangeResolver.resolve(
        ReportPeriod.custom,
        now: now,
        customStart: DateTime(2025, 6, 20),
        customEnd: DateTime(2025, 6, 10),
      );
      expect(start.isBefore(end), isTrue);
      // After swap: the user's original `end` date becomes the window start
      // (rounded to end-of-day), and the user's original `start` date
      // becomes the window end, then clamped to today.
      expect(start, DateTime(2025, 6, 10, 23, 59, 59, 999));
      expect(end, DateTime(2025, 6, 15, 23, 59, 59, 999));
    });

    test('custom range end is clamped to today', () {
      final now = DateTime(2025, 6, 15);
      final (start, end) = DateRangeResolver.resolve(
        ReportPeriod.custom,
        now: now,
        customStart: DateTime(2025, 6, 1),
        customEnd: DateTime(2025, 7, 1),
      );
      expect(end, DateTime(2025, 6, 15, 23, 59, 59, 999));
    });
  });
}