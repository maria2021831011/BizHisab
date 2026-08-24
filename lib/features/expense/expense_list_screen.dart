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

/// Polished finance-app list of expense transactions.
///
/// Reads from [TransactionProvider.watchExpense] so any add / edit / delete
/// elsewhere propagates here immediately. Tap a row to edit, use the trailing
/// menu to delete with a confirmation sheet.
///
/// Filter chips above the list let the user narrow the visible items by date
/// range (today / this month / all) and category. Filters are applied
/// locally on top of the Firestore stream so snapping between filters is
/// instant and does not cost an extra round-trip.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  Stream<List<TransactionModel>>? _expenseStream;

  /// `null` = "All time". Otherwise start-of-day for "Today" or start-of-month
  /// for "This month". The list is filtered using the inclusive lower bound.
  DateTime? _dateFilter;
  String? _categoryFilter;

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
      _expenseStream =
          context.read<TransactionProvider>().watchExpense(businessId);
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionProvider>();
    final businessId = auth.user?.businessId;
    if (businessId != null) {
      await provider.loadExpense(businessId);
      if (!mounted) return;
      _ensureStream();
    }
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> all) {
    final categoryFilter = _categoryFilter;
    final dateFilter = _dateFilter;
    final filtered = <TransactionModel>[];
    for (final t in all) {
      if (categoryFilter != null && t.category != categoryFilter) continue;
      if (dateFilter != null && t.date.isBefore(dateFilter)) continue;
      filtered.add(t);
    }
    return filtered;
  }

  Future<void> _confirmDelete(TransactionModel expense) async {
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
                l.expenseListDeleteTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.expenseListDeleteBody(expense.category,
                    CurrencyFormatter.format(expense.amount),
                    Formatters.date(expense.date)),
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
    if (userId == null) return;

    final ok = await provider.deleteExpense(expense, currentUserId: userId);
    if (!mounted) return;

    if (ok) {
      provider.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.expenseListDeleteSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? l.expenseListDeleteFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _setDateFilter(DateTime? lowerBound) {
    setState(() => _dateFilter = lowerBound);
  }

  void _setCategoryFilter(String? category) {
    setState(() => _categoryFilter = category);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.expenseListTitle),
        actions: [
          IconButton(
            tooltip: l.expenseListTooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _expenseStream == null
          ? LoadingWidget(message: l.expenseListLoading)
          : StreamBuilder<List<TransactionModel>>(
              stream: _expenseStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorWidget(
                    title: l.expenseListLoadFailedTitle,
                    message: l.expenseListLoadFailedSubtitle,
                    actionText: l.commonRetry,
                    onAction: _refresh,
                  );
                }
                if (!snapshot.hasData) {
                  return LoadingWidget(message: l.expenseListLoading);
                }

                final all = snapshot.data!;
                // Sync the in-memory cache for any non-stream consumers.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  context
                      .read<TransactionProvider>()
                      .setExpenseList(all);
                });

                final filtered = _applyFilters(all);

                return _ExpenseListBody(
                  allExpenses: all,
                  expenses: filtered,
                  activeCategory: _categoryFilter,
                  dateFilter: _dateFilter,
                  onPickCategory: _setCategoryFilter,
                  onPickDate: _setDateFilter,
                  onEdit: (t) => context.push(
                      '/app/transactions/expense/${t.id}/edit'),
                  onDelete: _confirmDelete,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/app/transactions/add-expense'),
        backgroundColor: AppColors.expense,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l.expenseListAdd),
      ),
    );
  }
}

class _ExpenseListBody extends StatelessWidget {
  final List<TransactionModel> allExpenses;
  final List<TransactionModel> expenses;
  final String? activeCategory;
  final DateTime? dateFilter;
  final ValueChanged<String?> onPickCategory;
  final ValueChanged<DateTime?> onPickDate;
  final void Function(TransactionModel) onEdit;
  final Future<void> Function(TransactionModel) onDelete;

  const _ExpenseListBody({
    required this.allExpenses,
    required this.expenses,
    required this.activeCategory,
    required this.dateFilter,
    required this.onPickCategory,
    required this.onPickDate,
    required this.onEdit,
    required this.onDelete,
  });

  double get _total =>
      expenses.fold<double>(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _ExpenseSummaryCard(total: _total, count: expenses.length),
        ),
        _FilterRow(
          allExpenses: allExpenses,
          activeCategory: activeCategory,
          dateFilter: dateFilter,
          onPickCategory: onPickCategory,
          onPickDate: onPickDate,
        ),
        Expanded(
          child: expenses.isEmpty
              ? EmptyWidget(
                  icon: Icons.north_east_rounded,
                  message: allExpenses.isEmpty
                      ? l.expenseListEmptyTitle
                      : l.expenseListEmptyFilterTitle,
                  subtitle: allExpenses.isEmpty
                      ? l.expenseListEmptySubtitle
                      : l.expenseListEmptyFilterSubtitle,
                  actionText:
                      allExpenses.isEmpty ? l.expenseListAdd : l.incomeListClearFilters,
                  onAction: () {
                    if (allExpenses.isEmpty) {
                      context.push('/app/transactions/add-expense');
                    } else {
                      onPickCategory(null);
                      onPickDate(null);
                    }
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = expenses[index];
                    return _ExpenseTile(
                      expense: t,
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

class _FilterRow extends StatelessWidget {
  final List<TransactionModel> allExpenses;
  final String? activeCategory;
  final DateTime? dateFilter;
  final ValueChanged<String?> onPickCategory;
  final ValueChanged<DateTime?> onPickDate;

  const _FilterRow({
    required this.allExpenses,
    required this.activeCategory,
    required this.dateFilter,
    required this.onPickCategory,
    required this.onPickDate,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime get _startOfDay {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _startOfMonth {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories = <String>{
      for (final t in allExpenses) t.category,
    }.toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l.incomeListFilterAllTime,
                  selected: dateFilter == null,
                  color: AppColors.expense,
                  onSelected: () => onPickDate(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l.incomeListFilterToday,
                  selected: dateFilter != null &&
                      _isSameDay(dateFilter!, _startOfDay),
                  color: AppColors.expense,
                  onSelected: () => onPickDate(_startOfDay),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l.incomeListFilterMonth,
                  selected: dateFilter != null &&
                      !_isSameDay(dateFilter!, _startOfDay) &&
                      dateFilter == _startOfMonth,
                  color: AppColors.expense,
                  onSelected: () => onPickDate(_startOfMonth),
                ),
              ],
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: l.transactionsAllCategories,
                    selected: activeCategory == null,
                    color: AppColors.expense,
                    onSelected: () => onPickCategory(null),
                  ),
                  const SizedBox(width: 8),
                  for (final c in categories) ...[
                    _FilterChip(
                      label: c,
                      selected: activeCategory == c,
                      color: AppColors.expense,
                      onSelected: () => onPickCategory(
                        activeCategory == c ? null : c,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.15),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: selected ? color : AppColors.divider,
        width: selected ? 1.2 : 1,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  final double total;
  final int count;

  const _ExpenseSummaryCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.expenseGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.expense.withValues(alpha: 0.25),
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
                  Icons.north_east_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.expenseListSummaryTitle,
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
            l.expenseListSummaryCount(count),
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

class _ExpenseTile extends StatelessWidget {
  final TransactionModel expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
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
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.north_east_rounded;
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
                  color: AppColors.expenseLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(expense.category),
                  color: AppColors.expense,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category,
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
                              Formatters.date(expense.date),
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
                            expense.paymentMethod,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((expense.note ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        expense.note!,
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
                    '- ${CurrencyFormatter.format(expense.amount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    tooltip: l.expenseListTileMore,
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
