import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/report_data.dart';

/// Donut chart for one side of the split (income or expense categories).
///
/// Renders nothing when the slice list is empty so we don't pass `[]` to
/// fl_chart (which throws).
class CategoryDonut extends StatelessWidget {
  final List<ReportCategoryTotal> categories;
  final Color baseColor;

  const CategoryDonut({
    super.key,
    required this.categories,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (categories.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.6,
        child: Center(
          child: Text(
            l.reportsChartEmpty,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final total = categories.fold<double>(0, (sum, c) => sum + c.amount);
    if (total <= 0) {
      return AspectRatio(
        aspectRatio: 1.6,
        child: Center(
          child: Text(
            l.reportsChartEmpty,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final palette = _shades(baseColor, categories.length);
    final currency = NumberFormat.compactCurrency(symbol: '', decimalDigits: 0);

    return AspectRatio(
      aspectRatio: 1.6,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                startDegreeOffset: -90,
                sections: [
                  for (int i = 0; i < categories.length; i++)
                    PieChartSectionData(
                      value: categories[i].amount,
                      color: palette[i],
                      radius: 56,
                      title: '${((categories[i].amount / total) * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: palette[i],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categories[i].category == 'Uncategorized'
                                ? l.reportsCategoryUncategorized
                                : categories[i].category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency.format(categories[i].amount),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generates a hue-graded set of colors anchored on [base].
  List<Color> _shades(Color base, int count) {
    final hsl = HSLColor.fromColor(base);
    return List<Color>.generate(count, (i) {
      // Spread hue around the base; keep saturation/lightness steady so
      // slices stay readable against white backgrounds.
      final hueShift = (i * 30) % 360;
      final h = (hsl.hue + hueShift) % 360;
      return hsl.withHue(h).toColor();
    });
  }
}