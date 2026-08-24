import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/greeting.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Header showing "Good Morning, Maria Fashion" + the running profit for
/// the day as a small chip. Used at the very top of the dashboard.
class DashboardGreetingHeader extends StatelessWidget {
  final String greeting;
  final String businessName;
  final String? ownerName;
  final double todayProfit;
  final VoidCallback? onProfileTap;

  const DashboardGreetingHeader({
    super.key,
    required this.greeting,
    required this.businessName,
    this.ownerName,
    required this.todayProfit,
    this.onProfileTap,
  });

  factory DashboardGreetingHeader.fromContext({
    required BuildContext context,
    required String businessName,
    required double todayProfit,
    String? ownerName,
    VoidCallback? onProfileTap,
  }) {
    final l = AppLocalizations.of(context);
    return DashboardGreetingHeader(
      greeting: greetingFor(DateTime.now(), l),
      businessName: businessName,
      ownerName: ownerName,
      todayProfit: todayProfit,
      onProfileTap: onProfileTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final profitColor =
        todayProfit >= 0 ? AppColors.income : AppColors.expense;
    final profitLabel =
        todayProfit >= 0 ? l.dashboardTodayProfit : l.dashboardTodayLoss;
    final isProfitable = todayProfit >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfitable
              ? [
                  AppColors.income.withValues(alpha: 0.08),
                  AppColors.income.withValues(alpha: 0.02),
                ]
              : [
                  AppColors.expense.withValues(alpha: 0.08),
                  AppColors.expense.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: profitColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: profitColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        greeting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  businessName.isEmpty
                      ? l.dashboardBusinessFallback
                      : businessName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: profitColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProfitable
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: profitColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$profitLabel  ${CurrencyFormatter.format(todayProfit)}',
                        style: TextStyle(
                          color: profitColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: l.dashboardProfile,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primaryLight.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
