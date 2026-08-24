import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Pair of "Customer Due" / "Supplier Due" cards. Tappable so the user
/// can jump straight to the relevant list screen.
class DashboardDueRow extends StatelessWidget {
  final double customerDue;
  final double supplierDue;
  final VoidCallback? onCustomerDueTap;
  final VoidCallback? onSupplierDueTap;

  const DashboardDueRow({
    super.key,
    required this.customerDue,
    required this.supplierDue,
    this.onCustomerDueTap,
    this.onSupplierDueTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient accent stripe tying the pair together visually.
            Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.due, AppColors.supplier],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Expanded(
              child: _DueCard(
                label: l.dashboardCustomerDue,
                amount: customerDue,
                icon: Icons.people_alt_outlined,
                color: AppColors.due,
                onTap: onCustomerDueTap,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 14),
              color: AppColors.divider.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _DueCard(
                label: l.dashboardSupplierDue,
                amount: supplierDue,
                icon: Icons.local_shipping_outlined,
                color: AppColors.warning,
                onTap: onSupplierDueTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DueCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: color.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
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
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}