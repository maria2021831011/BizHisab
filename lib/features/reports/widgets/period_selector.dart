import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/report_data.dart';

/// Period selector strip — three preset chips plus a "Custom" button that
/// opens a date-range picker dialog.
///
/// Renders as a horizontal scroll so it never wraps off-screen on narrow
/// phones.
class PeriodSelector extends StatelessWidget {
  final ReportPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<ReportPeriod> onSelectPeriod;
  final ValueChanged<DateTimeRange> onSelectCustomRange;

  const PeriodSelector({
    super.key,
    required this.period,
    required this.customStart,
    required this.customEnd,
    required this.onSelectPeriod,
    required this.onSelectCustomRange,
  });

  Future<void> _openCustomPicker(BuildContext context) async {
    final now = DateTime.now();
    final initial = customStart != null && customEnd != null
        ? DateTimeRange(start: customStart!, end: customEnd!)
        : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) onSelectCustomRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = DateFormat('dd MMM');
    final customLabel = period == ReportPeriod.custom &&
            customStart != null &&
            customEnd != null
        ? '${fmt.format(customStart!)} \u2013 ${fmt.format(customEnd!)}'
        : l.reportsPeriodCustom;

    final chips = <Widget>[
      _PresetChip(
        label: l.reportsPeriodToday,
        selected: period == ReportPeriod.daily,
        onTap: () => onSelectPeriod(ReportPeriod.daily),
      ),
      _PresetChip(
        label: l.reportsPeriodWeek,
        selected: period == ReportPeriod.weekly,
        onTap: () => onSelectPeriod(ReportPeriod.weekly),
      ),
      _PresetChip(
        label: l.reportsPeriodMonth,
        selected: period == ReportPeriod.monthly,
        onTap: () => onSelectPeriod(ReportPeriod.monthly),
      ),
      _PresetChip(
        label: customLabel,
        selected: period == ReportPeriod.custom,
        onTap: () => _openCustomPicker(context),
        trailing: period == ReportPeriod.custom
            ? null
            : const Icon(Icons.calendar_today_rounded, size: 16),
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, i) => chips[i],
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: selected ? scheme.primary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
    );
  }
}
