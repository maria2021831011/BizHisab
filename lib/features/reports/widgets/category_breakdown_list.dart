import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/report_data.dart';

/// Ranked list of categories with a horizontal % bar. Designed to look
/// correct at any width — each row is a Column inside an Expanded row.
class CategoryBreakdownList extends StatelessWidget {
  final String title;
  final List<ReportCategoryTotal> categories;
  final Color accent;

  const CategoryBreakdownList({
    super.key,
    required this.title,
    required this.categories,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          l.reportsBreakdownEmpty(title),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    final total = categories.fold<double>(0, (sum, c) => sum + c.amount);
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        for (final c in categories) _Row(item: c, total: total, accent: accent, currency: currency),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final ReportCategoryTotal item;
  final double total;
  final Color accent;
  final NumberFormat currency;

  const _Row({
    required this.item,
    required this.total,
    required this.accent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = total > 0 ? (item.amount / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.category == 'Uncategorized'
                      ? l.reportsCategoryUncategorized
                      : item.category,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.format(item.amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l.reportsBreakdownCount(item.count),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}