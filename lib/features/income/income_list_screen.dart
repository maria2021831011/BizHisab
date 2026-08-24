import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../l10n/gen/app_localizations.dart';

/// Polished finance-app list of income transactions.
///
/// Reads from [TransactionProvider.watchIncome] so any add / edit / delete
/// elsewhere propagates here immediately. Tap a row to edit, long-press
/// (or use the trailing menu) to delete with a confirmation sheet.
class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  Stream<List<TransactionModel>>? _incomeStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureStream();
    });
  }

  void _ensureStream() {
    if (!mounted) return;
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    setState(() {
      _incomeStream =
          context.read<TransactionProvider>().watchIncome(businessId);
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionProvider>();
    final businessId = auth.user?.businessId;
    if (businessId != null) {
      await provider.loadIncome(businessId);
      if (!mounted) return;
      _ensureStream();
    }
  }

  Future<void> _confirmDelete(TransactionModel income) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                l.incomeListDeleteTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.incomeListDeleteBody(
                  income.category,
                  CurrencyFormatter.format(income.amount),
                  Formatters.date(income.date),
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
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text(l.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(l.commonDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionProvider>();
    final userId = auth.user?.uid;
    final businessId = auth.user?.businessId;
    if (userId == null || businessId == null) return;

    final ok = await provider.deleteIncome(income, currentUserId: userId);
    if (!mounted) return;
    final l2 = AppLocalizations.of(context);

    if (ok) {
      provider.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l2.incomeListDeleteSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? l2.incomeListDeleteFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.incomeListTitle),
        actions: [
          IconButton(
            tooltip: l.incomeListTooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _incomeStream == null
          ? LoadingWidget(message: l.incomeListLoading)
          : StreamBuilder<List<TransactionModel>>(
              stream: _incomeStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorWidget(
                    title: l.incomeListLoadFailedTitle,
                    message: l.incomeListLoadFailedSubtitle,
                    actionText: l.commonRetry,
                    onAction: _refresh,
                  );
                }
                if (!snapshot.hasData) {
                  return LoadingWidget(message: l.incomeListLoading);
                }

                final incomes = snapshot.data!;
                // Sync the in-memory cache for any non-stream consumers.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  context
                      .read<TransactionProvider>()
                      .setIncomeList(incomes);
                });

                return _IncomeListBody(
                  incomes: incomes,
                  onEdit: (t) =>
                      context.push('/app/transactions/income/${t.id}/edit'),
                  onDelete: _confirmDelete,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/app/transactions/add-income'),
        backgroundColor: AppColors.income,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l.incomeListAdd),
      ),
    );
  }
}

class _IncomeListBody extends StatelessWidget {
  final List<TransactionModel> incomes;
  final void Function(TransactionModel) onEdit;
  final Future<void> Function(TransactionModel) onDelete;

  const _IncomeListBody({
    required this.incomes,
    required this.onEdit,
    required this.onDelete,
  });

  double get _total =>
      incomes.fold<double>(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (incomes.isEmpty) {
      return EmptyWidget(
        icon: Icons.south_west_rounded,
        message: l.incomeListEmptyTitle,
        subtitle: l.incomeListEmptySubtitle,
        actionText: l.incomeListAdd,
        onAction: () => context.push('/app/transactions/add-income'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _IncomeSummaryCard(total: _total, count: incomes.length),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: incomes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = incomes[index];
              return _IncomeTile(
                income: t,
                onTap: () => onEdit(t),
                onDelete: () => onDelete(t),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IncomeSummaryCard extends StatelessWidget {
  final double total;
  final int count;

  const _IncomeSummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.incomeGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.income.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.south_west_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.incomeListSummaryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.incomeListSummaryCount(count),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final TransactionModel income;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IncomeTile({
    required this.income,
    required this.onTap,
    required this.onDelete,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Sales':
        return Icons.point_of_sale;
      case 'Service':
        return Icons.handyman_outlined;
      case 'Other Income':
        return Icons.attach_money;
      case 'Customer Payment':
        return Icons.payments_outlined;
      default:
        return Icons.south_west_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(income.category),
                  color: AppColors.income,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.date(income.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            income.paymentMethod,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((income.note ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        income.note!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ ${CurrencyFormatter.format(income.amount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    tooltip: l.incomeListTileMore,
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onTap();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l.commonEdit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(l.commonDelete,
                                style: const TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
