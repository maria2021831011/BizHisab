import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../repositories/transaction_repository.dart';

/// Read-only detail view of a single transaction plus Edit + Delete actions.
///
/// Edit navigates to the legacy add/edit screen (`/app/transactions/:id`)
/// which already supports both income and expense updates. Delete
/// dispatches through [TransactionProvider.deleteIncome] / [deleteExpense]
/// depending on type and refreshes the dashboard so totals stay correct.
class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Future<TransactionModel?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TransactionModel?> _load() {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return Future.value(null);
    return TransactionRepository().getTransaction(
      businessId,
      widget.transactionId,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _confirmDelete(TransactionModel tx) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isIncome = tx.type == TransactionType.income;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Icon(
                  Icons.delete_outline_rounded,
                  size: 44,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
                const SizedBox(height: 12),
                Text(
                  l.transactionsDeleteConfirmTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.transactionsDetailDeleteBody(
                    isIncome
                        ? l.transactionsTypeIncome
                        : l.transactionsTypeExpense,
                    CurrencyFormatter.format(tx.amount),
                    Formatters.date(tx.date),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          l.commonDelete,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;
    if (businessId == null || userId == null) return;

    final provider = context.read<TransactionProvider>();
    final ok = tx.type == TransactionType.income
        ? await provider.deleteIncome(tx, currentUserId: userId)
        : await provider.deleteExpense(tx, currentUserId: userId);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? l.transactionsDeleteFailed)),
      );
      return;
    }

    // Refresh dependent surfaces (dashboard summary + history list).
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.refresh(businessId);
    if (provider.historyFilter != null) {
      await provider.loadFirstHistoryPage(businessId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.transactionsDeleteSuccess)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactionsDetailTitle),
        actions: [
          FutureBuilder<TransactionModel?>(
            future: _future,
            builder: (context, snapshot) {
              final tx = snapshot.data;
              if (tx == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: l.transactionsDetailEditTooltip,
                onPressed: () async {
                  final saved = await context.push<bool>(
                      '/app/transactions/${tx.id}');
                  if (saved == true) _reload();
                },
                icon: const Icon(Icons.edit_outlined),
              );
            },
          ),
          FutureBuilder<TransactionModel?>(
            future: _future,
            builder: (context, snapshot) {
              final tx = snapshot.data;
              if (tx == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: l.transactionsDetailDeleteTooltip,
                onPressed: () => _confirmDelete(tx),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.expense),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<TransactionModel?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingWidget(
                  message: l.transactionsDetailLoading);
            }
            if (snapshot.hasError) {
              return AppErrorWidget(
                title: l.transactionsDetailLoadFailedTitle,
                message: snapshot.error.toString(),
                actionText: l.commonRetry,
                onAction: _reload,
              );
            }
            final tx = snapshot.data;
            if (tx == null) {
              return EmptyWidget(
                icon: Icons.search_off,
                message: l.transactionsDetailNotFoundTitle,
                subtitle: l.transactionsDetailNotFoundSubtitle,
                actionText: l.transactionsDetailBack,
                onAction: () => Navigator.of(context).pop(),
              );
            }
            return _DetailBody(transaction: tx);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final TransactionModel transaction;
  const _DetailBody({required this.transaction});

  IconData _categoryIcon() {
    final cat = transaction.category;
    final isIncome = transaction.type == TransactionType.income;
    switch (cat) {
      case 'Sales':
        return Icons.point_of_sale_outlined;
      case 'Service':
        return Icons.handyman_outlined;
      case 'Customer Payment':
        return Icons.payments_outlined;
      case 'Other Income':
        return Icons.savings_outlined;
      case 'Purchase':
        return Icons.shopping_bag_outlined;
      case 'Rent':
        return Icons.home_work_outlined;
      case 'Salary':
        return Icons.badge_outlined;
      case 'Transport':
        return Icons.directions_bus_outlined;
      case 'Utilities':
        return Icons.bolt_outlined;
      case 'Marketing':
        return Icons.campaign_outlined;
      case 'Packaging':
        return Icons.inventory_2_outlined;
      case 'Internet':
        return Icons.wifi;
    }
    return isIncome
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final accentLight =
        isIncome ? AppColors.incomeLight : AppColors.expenseLight;
    final sign = isIncome ? '+' : '-';

    return RefreshIndicator(
      onRefresh: () async {
        // Force a rebuild by triggering reload.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              gradient: isIncome
                  ? AppColors.incomeGradient
                  : AppColors.expenseGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isIncome
                        ? l.transactionsBadgeIncome
                        : l.transactionsBadgeExpense,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$sign ${CurrencyFormatter.format(transaction.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_categoryIcon(),
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: l.transactionsDetailInfoDate,
                value: Formatters.dateTime(transaction.date),
              ),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: l.transactionsDetailInfoPaymentMethod,
                value: transaction.paymentMethod,
                showDivider: true,
              ),
              if (transaction.supplierId != null &&
                  transaction.supplierId!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: l.transactionsDetailInfoSupplier,
                  value: l.transactionsDetailInfoYes,
                  showDivider: true,
                ),
              if (transaction.customerId != null &&
                  transaction.customerId!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline,
                  label: l.transactionsDetailInfoCustomer,
                  value: l.transactionsDetailInfoYes,
                  showDivider: true,
                ),
            ],
          ),
          if ((transaction.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: l.transactionsDetailNote,
              icon: Icons.notes_outlined,
              child: Text(
                transaction.note!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Section(
            title: l.transactionsDetailTypeIndicator,
            icon: Icons.palette_outlined,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_categoryIcon(), size: 16, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  isIncome
                      ? l.transactionsDetailCountsIncome
                      : l.transactionsDetailCountsExpense,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}