import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/quick_action_button.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Quick-actions row for the dashboard. Tap handlers can be null for
/// destinations that aren't implemented yet - the button then no-ops
/// silently so the screen keeps working while other features land.
class DashboardQuickActions extends StatelessWidget {
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddExpense;
  final VoidCallback? onCustomers;
  final VoidCallback? onSuppliers;
  final VoidCallback? onReports;

  const DashboardQuickActions({
    super.key,
    this.onAddIncome,
    this.onAddExpense,
    this.onCustomers,
    this.onSuppliers,
    this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: QuickActionRow(
          actions: [
            QuickActionButton(
              icon: Icons.add_circle_outline,
              label: l.dashboardAddIncome,
              color: AppColors.income,
            ).withOptionalCallback(onAddIncome),
            QuickActionButton(
              icon: Icons.remove_circle_outline,
              label: l.dashboardAddExpense,
              color: AppColors.expense,
            ).withOptionalCallback(onAddExpense),
            QuickActionButton(
              icon: Icons.people_outline,
              label: l.navCustomers,
            ).withOptionalCallback(onCustomers),
            QuickActionButton(
              icon: Icons.local_shipping_outlined,
              label: l.navSuppliers,
            ).withOptionalCallback(onSuppliers),
            QuickActionButton(
              icon: Icons.bar_chart_outlined,
              label: l.navReports,
              color: AppColors.primary,
            ).withOptionalCallback(onReports),
          ],
        ),
      ),
    );
  }
}

/// Internal helper so we can keep `const` declarations above while still
/// attaching a non-const callback at the call site.
extension on QuickActionButton {
  QuickActionButton withOptionalCallback(VoidCallback? onTap) {
    return QuickActionButton(
      key: key,
      icon: icon,
      label: label,
      color: color,
      onTap: onTap ?? this.onTap,
    );
  }
}