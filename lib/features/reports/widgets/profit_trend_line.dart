import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/report_data.dart';

/// Profit-trend line chart — one point per day from `data.start` to
/// `data.end`. Days with no transactions get a zero bucket (already
/// zero-filled by the aggregator).
class ProfitTrendLine extends StatelessWidget {
  final ReportData data;

  const ProfitTrendLine({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (data.trendBuckets.length < 2) {
      return AspectRatio(
        aspectRatio: 1.6,
        child: Center(
          child: Text(
            l.reportsTrendEmpty,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (int i = 0; i < data.trendBuckets.length; i++) {
      final b = data.trendBuckets[i];
      final profit = b.netProfit;
      spots.add(FlSpot(i.toDouble(), profit));
      if (profit < minY) minY = profit;
      if (profit > maxY) maxY = profit;
    }

    // Pad a bit so the line never hugs the axis edges.
    final range = (maxY - minY).abs();
    final pad = range == 0 ? (maxY.abs() * 0.2 + 100) : range * 0.15;
    final adjustedMin = minY < 0 ? minY - pad : 0.0;
    final adjustedMax = maxY + pad;

    final currency = NumberFormat.compactCurrency(symbol: '', decimalDigits: 0);
    final dayFmt = DateFormat('d MMM');

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minY: adjustedMin,
          maxY: adjustedMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((adjustedMax - adjustedMin) / 4)
                .clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: ((adjustedMax - adjustedMin) / 4)
                    .clamp(1, double.infinity),
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    currency.format(value),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval:
                    (data.trendBuckets.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.trendBuckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dayFmt.format(data.trendBuckets[i].label),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.profit,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.profit.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}