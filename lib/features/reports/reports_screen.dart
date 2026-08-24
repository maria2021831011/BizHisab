import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_widget.dart' as biz;
import '../../l10n/gen/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import 'models/report_data.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/category_donut.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/income_vs_expense_bar.dart';
import 'widgets/period_selector.dart';
import 'widgets/profit_trend_line.dart';
import 'widgets/report_loading_shell.dart';
import 'widgets/report_summary_grid.dart';
import 'widgets/transaction_list_tile.dart';

/// Main Reports & Analytics screen.
///
/// State machine: loading -> error -> empty -> ready. The same widget is
/// rendered in all four states so transitions are smooth and only the body
/// swaps — the period selector and filter chips stay mounted.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _businessId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  void _initialLoad() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final id = auth.user?.businessId;
    setState(() => _businessId = id);
    context.read<ReportsProvider>().load(id);
  }

  Future<void> _onRefresh() async {
    final auth = context.read<AuthProvider>();
    await context.read<ReportsProvider>().refresh(auth.user?.businessId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reportsAppBarTitle),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(ReportsProvider provider) {
    final l = AppLocalizations.of(context);
    if (provider.isLoading) {
      return const ReportLoadingShell();
    }

    if (provider.errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          biz.AppErrorWidget(
            message: provider.errorMessage!,
            actionText: l.commonRetry,
            onAction: () {
              provider.clearError();
              provider.load(_businessId);
            },
          ),
        ],
      );
    }

    final data = provider.data;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 12),
        PeriodSelector(
          period: provider.period,
          customStart: provider.customStart,
          customEnd: provider.customEnd,
          onSelectPeriod: provider.selectPeriod,
          onSelectCustomRange: (range) =>
              provider.selectCustomRange(range.start, range.end),
        ),
        const SizedBox(height: 8),
        CategoryFilterChips(
          categories: data.categoryOptions,
          selected: provider.selectedCategory,
          onSelected: provider.selectCategory,
        ),
        const SizedBox(height: 12),
        ReportSummaryGrid(data: data),
        const SizedBox(height: 24),
        if (data.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: biz.EmptyWidget(
              icon: Icons.bar_chart_outlined,
              message: l.reportsEmptyTitle,
              subtitle: l.reportsEmptySubtitle,
              actionText: l.reportsActionRefresh,
              onAction: _onRefresh,
            ),
          )
        else
          ..._buildChartSections(data),
        if (data.totalTransactionCount > 0) _buildTransactionsSection(),
      ],
    );
  }

  List<Widget> _buildChartSections(ReportData data) {
    final l = AppLocalizations.of(context);
    return [
      _ChartCard(
        title: l.reportsChartIncomeVsExpense,
        child: IncomeVsExpenseBar(data: data),
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: l.reportsChartProfitTrend,
        child: ProfitTrendLine(data: data),
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: l.reportsChartIncomeCategories,
        child: CategoryDonut(
          categories: data.filteredIncomeByCategory,
          baseColor: AppColors.income,
        ),
      ),
      const SizedBox(height: 12),
      CategoryBreakdownList(
        title: l.reportsBreakdownIncome,
        categories: data.filteredIncomeByCategory,
        accent: AppColors.income,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: l.reportsChartExpenseCategories,
        child: CategoryDonut(
          categories: data.filteredExpenseByCategory,
          baseColor: AppColors.expense,
        ),
      ),
      const SizedBox(height: 12),
      CategoryBreakdownList(
        title: l.reportsBreakdownExpense,
        categories: data.filteredExpenseByCategory,
        accent: AppColors.expense,
      ),
    ];
  }

  Widget _buildTransactionsSection() {
    // Cap to the latest 20 transactions in the window — the screen already
    // shows totals; the list is just a quick "what's happening" preview.
    final l = AppLocalizations.of(context);
    final provider = context.read<ReportsProvider>();
    final cached = provider.cachedTransactions;
    if (cached.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l.reportsTransactionsHeading,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          ...cached
              .take(20)
              .map((t) => TransactionListTile(transaction: t)),
        ],
      ),
    );
  }
}

/// Small wrapper card that gives every chart a consistent title bar +
/// padding without each widget re-implementing it.
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
