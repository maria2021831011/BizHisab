import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_widget.dart' as ui_widgets;
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/summary_metric_card.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/dashboard_ai_insight_card.dart';
import 'widgets/dashboard_due_row.dart';
import 'widgets/dashboard_greeting_header.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_recent_transactions_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  void _loadDashboard() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final businessId = authProvider.user?.businessId;
    if (businessId != null) {
      dashboardProvider.loadDashboard(businessId);
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final businessId = authProvider.user?.businessId;
    await context.read<DashboardProvider>().refresh(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l.dashboardTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l.dashboardRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: Consumer<DashboardProvider>(
          builder: (context, dashboard, _) {
            if (dashboard.isLoading &&
                dashboard.data.business == null &&
                dashboard.data.recentTransactions.isEmpty) {
              return const DashboardSkeleton();
            }

            if (dashboard.errorMessage != null &&
                dashboard.data.recentTransactions.isEmpty &&
                dashboard.data.business == null) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: ui_widgets.AppErrorWidget(
                      title: l.dashboardLoadFailed,
                      message: dashboard.errorMessage!,
                      actionText: l.commonRetry,
                      onAction: _loadDashboard,
                    ),
                  ),
                ),
              );
            }

            return const _DashboardContent();
          },
        ),
      ),
    );
  }
}
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  void _safeNavigate(BuildContext context, String path) {
    try {
      context.push(path);
    } catch (_) {
      // Route not registered yet - silently no-op so the dashboard
      // doesn't crash while other features are still landing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: isWide ? 960 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: l.dashboardToday,
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildTodaySection(context, isWide),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: l.dashboardMonth,
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildMonthSection(context, isWide),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: l.dashboardDue,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildDueSection(context),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: l.dashboardQuickActions,
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActions(context),
                  const SizedBox(height: 22),
                  _buildAiInsight(context),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: l.dashboardRecentTransactions,
                    icon: Icons.receipt_long_rounded,
                    trailing: l.dashboardSeeAll,
                    onTrailingTap: () =>
                        _safeNavigate(context, '/app/transactions'),
                  ),
                  const SizedBox(height: 10),
                  _buildRecentTransactions(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer2<DashboardProvider, AuthProvider>(
      builder: (context, dashboard, auth, _) {
        final data = dashboard.data;
        final businessName =
            data.business?.name ?? auth.user?.businessId ?? '';
        return DashboardGreetingHeader.fromContext(
          context: context,
          businessName: businessName.isEmpty
              ? l.dashboardBusinessFallback
              : businessName,
          todayProfit: data.todayProfit,
          onProfileTap: () => _safeNavigate(context, '/app/profile'),
        );
      },
    );
  }

  Widget _buildTodaySection(BuildContext context, bool isWide) {
    final l = AppLocalizations.of(context);
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final data = dashboard.data;
        final profitColor = data.todayProfit >= 0
            ? AppColors.income
            : AppColors.expense;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardTodaySales,
                  amount: data.todaySales,
                  accentColor: AppColors.income,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardTodayExpense,
                  amount: data.todayExpense,
                  accentColor: AppColors.expense,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardTodayProfit,
                  amount: data.todayProfit,
                  accentColor: profitColor,
                  icon: data.todayProfit >= 0
                      ? Icons.workspace_premium_outlined
                      : Icons.warning_amber_outlined,
                  emphasize: true,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryMetricCard(
                    label: l.dashboardTodaySales,
                    amount: data.todaySales,
                    accentColor: AppColors.income,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryMetricCard(
                    label: l.dashboardTodayExpense,
                    amount: data.todayExpense,
                    accentColor: AppColors.expense,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SummaryMetricCard(
              label: l.dashboardTodayProfit,
              amount: data.todayProfit,
              accentColor: profitColor,
              icon: data.todayProfit >= 0
                  ? Icons.workspace_premium_outlined
                  : Icons.warning_amber_outlined,
              emphasize: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthSection(BuildContext context, bool isWide) {
    final l = AppLocalizations.of(context);
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final data = dashboard.data;
        final profitColor = data.monthProfit >= 0
            ? AppColors.income
            : AppColors.expense;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardIncome,
                  amount: data.monthIncome,
                  accentColor: AppColors.income,
                  icon: Icons.south_west,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardExpense,
                  amount: data.monthExpense,
                  accentColor: AppColors.expense,
                  icon: Icons.north_east,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryMetricCard(
                  label: l.dashboardProfit,
                  amount: data.monthProfit,
                  accentColor: profitColor,
                  icon: data.monthProfit >= 0
                      ? Icons.emoji_events_outlined
                      : Icons.error_outline,
                  emphasize: true,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryMetricCard(
                    label: l.dashboardIncome,
                    amount: data.monthIncome,
                    accentColor: AppColors.income,
                    icon: Icons.south_west,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryMetricCard(
                    label: l.dashboardExpense,
                    amount: data.monthExpense,
                    accentColor: AppColors.expense,
                    icon: Icons.north_east,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SummaryMetricCard(
              label: l.dashboardProfit,
              amount: data.monthProfit,
              accentColor: profitColor,
              icon: data.monthProfit >= 0
                  ? Icons.emoji_events_outlined
                  : Icons.error_outline,
              emphasize: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDueSection(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final data = dashboard.data;
        return DashboardDueRow(
          customerDue: data.customerDue,
          supplierDue: data.supplierDue,
          onCustomerDueTap: () =>
              _safeNavigate(context, '/app/customers'),
          onSupplierDueTap: () =>
              _safeNavigate(context, '/app/suppliers'),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return DashboardQuickActions(
      onAddIncome: () =>
          _safeNavigate(context, '/app/transactions/add-income'),
      onAddExpense: () =>
          _safeNavigate(context, '/app/transactions/add-expense'),
      onCustomers: () => _safeNavigate(context, '/app/customers'),
      onSuppliers: () => _safeNavigate(context, '/app/suppliers'),
      onReports: () => _safeNavigate(context, '/app/reports'),
    );
  }

  Widget _buildAiInsight(BuildContext context) {
    return DashboardAiInsightCard(
      onTap: () => _safeNavigate(context, '/app/ai'),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return DashboardRecentTransactionsCard(
          transactions: dashboard.data.recentTransactions,
          onTransactionTap: (t) => _safeNavigate(context, '/app/transactions'),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const _SectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (trailing != null && onTrailingTap != null)
            TextButton(
              onPressed: onTrailingTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
