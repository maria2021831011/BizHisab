import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_widget.dart' as ui_widgets;
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/transaction.dart';

/// Compact "Recent Transactions" list-card used on the dashboard.
///
/// * Empty state: friendly placeholder with an "Add" CTA
/// * Loading: handled by the dashboard's skeleton (this widget only renders
///   once data has arrived)
/// * Tapping a row fires [onTransactionTap] (used to open the full list
///   or detail screen).
class DashboardRecentTransactionsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<TransactionModel>? onTransactionTap;

  const DashboardRecentTransactionsCard({
    super.key,
    required this.transactions,
    this.onSeeAllTap,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transactions.isEmpty)
              ui_widgets.EmptyWidget(
                icon: Icons.receipt_long_outlined,
                message: l.transactionsEmpty,
                subtitle: l.dashboardEmptySubtitle,
              )
            else
              ...transactions.map(
                (t) => _TransactionRow(
                  transaction: t,
                  onTap: onTransactionTap == null
                      ? null
                      : () => onTransactionTap!(t),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const _TransactionRow({required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final bg = isIncome ? AppColors.incomeLight : AppColors.expenseLight;
    final signed = isIncome ? transaction.amount : -transaction.amount;

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bg,
                      color.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category.isEmpty
                          ? (isIncome
                              ? l.dashboardIncomeGeneric
                              : l.dashboardExpenseGeneric)
                          : transaction.category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(transaction),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.formatWithSign(signed),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ));
  }

  String _buildSubtitle(TransactionModel t) {
    final datePart = Formatters.date(t.date);
    final method = t.paymentMethod.trim();
    if (method.isEmpty || method.toLowerCase() == 'cash') {
      return datePart;
    }
    return '$datePart  •  $method';
  }
}