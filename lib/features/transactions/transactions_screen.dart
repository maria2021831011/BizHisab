import 'dart:async';

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
import '../../providers/transaction_provider.dart';

/// Polished Transaction History screen.
///
/// Layout (top → bottom):
///   1. Sticky header with search + summary totals
///   2. Date range chips (All time / Today / This week / This month / Custom)
///   3. Type segment (All / Income / Expense)
///   4. Category chip row (derived from currently loaded data)
///   5. Paginated list with auto-fetch on scroll, pull-to-refresh, and full
///      loading / error / empty states.
///   6. Result count + "Load more" sentinel at the bottom.
///
/// All filtering beyond local search is server-side — see
/// [TransactionProvider.loadFirstHistoryPage]. Search is client-side over
/// the loaded page (per spec: category + note).
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  /// `null` means "all time" — bounded only by date precision.
  static const _datePresetAll = 0;
  static const _datePresetToday = 1;
  static const _datePresetWeek = 2;
  static const _datePresetMonth = 3;
  static const _datePresetCustom = 4;
  int _datePreset = _datePresetMonth;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _bootstrap() {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    context.read<TransactionProvider>().loadFirstHistoryPage(businessId);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 240) {
      final businessId = context.read<AuthProvider>().user?.businessId;
      if (businessId == null) return;
      context.read<TransactionProvider>().loadNextHistoryPage(businessId);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<TransactionProvider>().setHistorySearch(value),
    );
  }

  HistoryFilter _filterForPreset(int preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _datePresetAll:
        return HistoryFilter(
          startDate: DateTime(2000),
          endDate: today,
        );
      case _datePresetToday:
        return HistoryFilter(startDate: today, endDate: today);
      case _datePresetWeek:
        final start = today.subtract(const Duration(days: 6));
        return HistoryFilter(startDate: start, endDate: today);
      case _datePresetMonth:
        return HistoryFilter(
          startDate: DateTime(now.year, now.month, 1),
          endDate: today,
        );
      default:
        final active =
            context.read<TransactionProvider>().historyFilter ??
                HistoryFilter.defaultRange();
        return active;
    }
  }

  Future<void> _applyPreset(int preset) async {
    setState(() => _datePreset = preset);
    if (preset == _datePresetCustom) {
      final picked = await _pickCustomRange();
      if (picked == null) {
        setState(() => _datePreset = _datePresetMonth);
        return;
      }
      await _applyFilter(picked);
    } else {
      await _applyFilter(_filterForPreset(preset));
    }
  }

  Future<HistoryFilter?> _pickCustomRange() async {
    final initial = context.read<TransactionProvider>().historyFilter ??
        HistoryFilter.defaultRange();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: initial.startDate,
        end: initial.endDate,
      ),
    );
    if (picked == null) return null;
    return HistoryFilter(
      startDate: DateTime(
          picked.start.year, picked.start.month, picked.start.day),
      endDate:
          DateTime(picked.end.year, picked.end.month, picked.end.day),
    );
  }

  Future<void> _applyFilter(HistoryFilter filter) async {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    await context
        .read<TransactionProvider>()
        .applyHistoryFilter(businessId, filter: filter);
    if (mounted) {
      // Jump to top so the user sees the freshly filtered page.
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  void _setCategory(String? category) {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    final current =
        context.read<TransactionProvider>().historyFilter ??
            _filterForPreset(_datePreset);
    final next = category == null
        ? current.copyWith(clearCategory: true)
        : current.copyWith(category: category);
    _applyFilter(next);
  }

  void _setType(TransactionType? type) {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    final current =
        context.read<TransactionProvider>().historyFilter ??
            _filterForPreset(_datePreset);
    final next = type == null
        ? current.copyWith(clearType: true)
        : current.copyWith(type: type);
    _applyFilter(next);
  }

  Future<void> _refresh() async {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    await context
        .read<TransactionProvider>()
        .loadFirstHistoryPage(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _HistoryHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.transactionsSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<TransactionProvider>()
                                    .setHistorySearch('');
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _DatePresetRow(
                  selected: _datePreset,
                  onSelect: _applyPreset,
                ),
              ),
              const SliverToBoxAdapter(child: _TypeSegment()),
              const SliverToBoxAdapter(child: _CategoryRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              Consumer<TransactionProvider>(
                builder: (context, provider, _) {
                  final visible = provider.history;
                  if (provider.historyLoadingFirstPage &&
                      provider.history.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadingWidget(
                          message: l.transactionsLoading),
                    );
                  }
                  if (provider.historyErrorMessage != null &&
                      provider.history.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorWidget(
                        title: l.transactionsLoadFailedTitle,
                        message: provider.historyErrorMessage!,
                        actionText: l.transactionsRetry,
                        onAction: _refresh,
                      ),
                    );
                  }
                  if (visible.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyWidget(
                        icon: Icons.receipt_long_outlined,
                        message: l.transactionsEmptyTitle,
                        subtitle: l.transactionsEmptySubtitle,
                        actionText: l.transactionsResetFilters,
                        onAction: () {
                          context
                              .read<TransactionProvider>()
                              .resetHistory();
                          setState(() {
                            _datePreset = _datePresetMonth;
                            _searchController.clear();
                          });
                          _applyFilter(_filterForPreset(_datePreset));
                        },
                      ),
                    );
                  }
                  return SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: SliverList.separated(
                      itemCount: visible.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return _PagingFooter(
                            hasMore: provider.historyHasMore,
                            isLoading: provider.historyLoadingMore,
                            onLoadMore: () {
                              final biz = context
                                  .read<AuthProvider>()
                                  .user
                                  ?.businessId;
                              if (biz == null) return;
                              context
                                  .read<TransactionProvider>()
                                  .loadNextHistoryPage(biz);
                            },
                          );
                        }
                        final t = visible[index];
                        return _HistoryTile(
                          transaction: t,
                          onTap: () => context.push(
                              '/app/transactions/history/${t.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(
              '/app/transactions/add');
          if (created == true) _refresh();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l.transactionsNewBtn),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                l.transactionsHistoryTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: l.transactionsRefresh,
                onPressed: () {
                  final biz =
                      context.read<AuthProvider>().user?.businessId;
                  if (biz == null) return;
                  context
                      .read<TransactionProvider>()
                      .loadFirstHistoryPage(biz);
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              final s = provider.historySummary;
              return Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: l.transactionsSummaryIncome,
                      value: CurrencyFormatter.formatShort(s.totalIncome),
                      icon: Icons.south_west_rounded,
                      color: Colors.greenAccent.shade100,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: l.transactionsSummaryExpense,
                      value: CurrencyFormatter.formatShort(s.totalExpense),
                      icon: Icons.north_east_rounded,
                      color: Colors.redAccent.shade100,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: l.transactionsSummaryNet,
                      value: CurrencyFormatter.formatShort(
                          s.totalIncome - s.totalExpense),
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.lightBlueAccent.shade100,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DatePresetRow extends StatelessWidget {
  final int selected;
  final Future<void> Function(int) onSelect;
  const _DatePresetRow({required this.selected, required this.onSelect});

  Widget _chip(BuildContext context, String label, int value, IconData icon) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 1.2 : 1,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _chip(context, l.transactionsDateAll, 0, Icons.all_inclusive),
          _chip(context, l.transactionsDateToday, 1, Icons.today_outlined),
          _chip(context, l.transactionsDateWeek, 2, Icons.date_range_outlined),
          _chip(context, l.transactionsDateMonth, 3, Icons.calendar_view_month),
          _chip(context, l.transactionsDateCustom, 4, Icons.tune),
        ],
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final active = provider.historyFilter?.type;
          final state = context
              .findAncestorStateOfType<_TransactionsScreenState>();
          return SegmentedButton<TransactionType?>(
            segments: [
              ButtonSegment(
                value: null,
                label: Text(l.transactionsTypeAll),
                icon: const Icon(Icons.dashboard_outlined, size: 16),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text(l.transactionsTypeIncome),
                icon: const Icon(Icons.south_west, size: 16),
              ),
              ButtonSegment(
                value: TransactionType.expense,
                label: Text(l.transactionsTypeExpense),
                icon: const Icon(Icons.north_east, size: 16),
              ),
            ],
            selected: {active},
            onSelectionChanged: (set) => state?._setType(set.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              side: const BorderSide(color: AppColors.divider),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final active = provider.historyFilter?.category;
        final categories = <String>{
          for (final t in provider.history) t.category,
        }.toList()
          ..sort();
        if (categories.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  selected: active == null,
                  onSelected: (_) {
                    final state = context
                        .findAncestorStateOfType<_TransactionsScreenState>();
                    state?._setCategory(null);
                  },
                  label: Text(l.transactionsAllCategories),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: active == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: active == null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  selectedColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: active == null
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                for (final c in categories) ...[
                  ChoiceChip(
                    selected: active == c,
                    onSelected: (_) {
                      final state = context
                          .findAncestorStateOfType<_TransactionsScreenState>();
                      state?._setCategory(active == c ? null : c);
                    },
                    label: Text(c),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: active == c
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: active == c
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: active == c
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PagingFooter extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  const _PagingFooter({
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary)),
                )
              : TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(l.transactionsLoadMore),
                ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          l.transactionsEndOfList,
          style: TextStyle(
            color: AppColors.textHint.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  const _HistoryTile({required this.transaction, required this.onTap});

  IconData _icon(String category, bool isIncome) {
    if (!isIncome) {
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
      }
    } else {
      switch (category) {
        case 'Sales':
          return Icons.point_of_sale_outlined;
        case 'Service':
          return Icons.handyman_outlined;
        case 'Customer Payment':
          return Icons.payments_outlined;
        case 'Other Income':
          return Icons.savings_outlined;
      }
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _icon(transaction.category, isIncome),
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                isIncome
                                    ? l.transactionsBadgeIncome
                                    : l.transactionsBadgeExpense,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                transaction.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.date(transaction.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                transaction.paymentMethod,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign ${CurrencyFormatter.format(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ],
              ),
              if ((transaction.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
