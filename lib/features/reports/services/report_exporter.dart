import 'package:intl/intl.dart';

import '../models/report_data.dart';

/// Strategy interface for "take a [ReportData] and produce a sharable artifact".
///
/// Returns the artifact path (or in-memory identifier) on success, `null`
/// if the export was cancelled by the user or failed. Implementations are
/// responsible for surfacing their own errors via the returned `Future`'s
/// exception channel — the caller decides whether to surface them.
abstract class ReportExporter {
  Future<String?> export(ReportData data);
}

/// Default no-op exporter. Wired in until a real export surface (share
/// intent, file save, etc.) lands. Returning `null` cleanly lets the UI
/// render a "coming soon" snackbar without breaking.
class StubReportExporter implements ReportExporter {
  const StubReportExporter();

  @override
  Future<String?> export(ReportData data) async => null;
}

/// CSV exporter. Builds a string in-memory so it has no platform dependencies
/// — the caller can hand the result to a share intent, file picker, or
/// download manager. Columns: header block + income rows + expense rows +
/// due snapshot.
class CsvReportExporter implements ReportExporter {
  const CsvReportExporter();

  @override
  Future<String?> export(ReportData data) async {
    return _buildCsv(data);
  }

  String _buildCsv(ReportData data) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final start = dateFmt.format(data.start);
    final end = dateFmt.format(data.end);
    final periodLabel = data.period.label;

    final buffer = StringBuffer()
      ..writeln('BizHisab AI Report')
      ..writeln('Period,$periodLabel,$start to $end')
      ..writeln('Generated,${dateFmt.format(DateTime.now())}')
      ..writeln()
      ..writeln('Summary')
      ..writeln('Metric,Amount')
      ..writeln('Total Income,${data.totalIncome.toStringAsFixed(2)}')
      ..writeln('Total Expense,${data.totalExpense.toStringAsFixed(2)}')
      ..writeln('Net Profit,${data.netProfit.toStringAsFixed(2)}')
      ..writeln('Profit Margin,${data.profitMargin.toStringAsFixed(2)}%')
      ..writeln('Customer Due,${data.customerDue.toStringAsFixed(2)}')
      ..writeln('Supplier Due,${data.supplierDue.toStringAsFixed(2)}')
      ..writeln()
      ..writeln('Income by Category')
      ..writeln('Category,Amount,Transactions')
      ..writeln(_rowsFor(data.incomeByCategory))
      ..writeln()
      ..writeln('Expense by Category')
      ..writeln('Category,Amount,Transactions')
      ..writeln(_rowsFor(data.expenseByCategory));

    return buffer.toString();
  }

  String _rowsFor(List<ReportCategoryTotal> list) {
    if (list.isEmpty) return '(none)';
    return list
        .map((c) =>
            '${_escape(c.category)},${c.amount.toStringAsFixed(2)},${c.count}')
        .join('\n');
  }

  String _escape(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }
}