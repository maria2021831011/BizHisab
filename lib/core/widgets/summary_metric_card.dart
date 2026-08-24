import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// A single labelled amount card used across the dashboard for each metric
/// (Today's Sales, Today's Expense, etc.). Used inside a Row of two on
/// phones and up to four on tablets, with consistent padding.
class SummaryMetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color accentColor;
  final IconData icon;
  final bool emphasize;
  final String? subLabel;
  final double? subAmount;

  const SummaryMetricCard({
    super.key,
    required this.label,
    required this.amount,
    required this.accentColor,
    required this.icon,
    this.emphasize = false,
    this.subLabel,
    this.subAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStyle = emphasize
        ? theme.textTheme.headlineSmall?.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.titleLarge?.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: accentColor.withValues(alpha: emphasize ? 0.55 : 0.35),
              width: emphasize ? 4 : 3,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(emphasize ? 16 : 14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.16),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.format(amount),
                  style: amountStyle?.copyWith(letterSpacing: -0.3),
                ),
              ),
              if (subLabel != null && subAmount != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$subLabel: ${CurrencyFormatter.format(subAmount!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
