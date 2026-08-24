import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/summary_metric_card.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/report_data.dart';

/// 5-tile responsive summary at the top of the Reports screen.
///
/// Layout: 2 columns on phones (one Net-Profit tile spans both columns at the
/// top for emphasis), 5 columns on wide tablets. Pure widget — receives a
/// [ReportData] snapshot and nothing else.
class ReportSummaryGrid extends StatelessWidget {
  final ReportData data;

  const ReportSummaryGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    final tiles = <_SummaryTile>[
      _SummaryTile(
        label: l.reportsSummaryTotalIncome,
        amount: data.totalIncome,
        accent: AppColors.income,
        icon: Icons.trending_up_rounded,
      ),
      _SummaryTile(
        label: l.reportsSummaryTotalExpense,
        amount: data.totalExpense,
        accent: AppColors.expense,
        icon: Icons.trending_down_rounded,
      ),
      _SummaryTile(
        label: l.reportsSummaryNetProfit,
        amount: data.netProfit,
        accent: data.netProfit >= 0 ? AppColors.profit : AppColors.expense,
        icon: Icons.account_balance_wallet_rounded,
        subLabel: l.reportsSummaryMargin,
        subAmount: data.profitMargin,
      ),
      _SummaryTile(
        label: l.reportsSummaryCustomerDue,
        amount: data.customerDue,
        accent: AppColors.due,
        icon: Icons.people_alt_rounded,
      ),
      _SummaryTile(
        label: l.reportsSummarySupplierDue,
        amount: data.supplierDue,
        accent: AppColors.supplier,
        icon: Icons.local_shipping_rounded,
      ),
    ];

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              Expanded(child: tiles[i].build()),
              if (i != tiles.length - 1) const SizedBox(width: 12),
            ]
          ],
        ),
      );
    }

    // Phone layout: profit tile full-width on top, then a 2x2 grid.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          tiles[2].build(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: tiles[0].build()),
              const SizedBox(width: 12),
              Expanded(child: tiles[1].build()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: tiles[3].build()),
              const SizedBox(width: 12),
              Expanded(child: tiles[4].build()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile {
  final String label;
  final double amount;
  final Color accent;
  final IconData icon;
  final String? subLabel;
  final double? subAmount;

  _SummaryTile({
    required this.label,
    required this.amount,
    required this.accent,
    required this.icon,
    this.subLabel,
    this.subAmount,
  });

  Widget build() {
    return SummaryMetricCard(
      label: label,
      amount: amount,
      accentColor: accent,
      icon: icon,
      subLabel: subLabel,
      subAmount: subAmount,
    );
  }
}