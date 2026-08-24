import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small circular-icon button with a label below it, used in the
/// dashboard's quick-actions row. Wraps [InkWell] so it animates on press.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.14),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: color.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lay out a horizontal row of [QuickActionButton]s. On wide screens the
/// row wraps to a second line rather than overflowing.
class QuickActionRow extends StatelessWidget {
  final List<QuickActionButton> actions;

  const QuickActionRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      children: actions
          .map(
            (a) => SizedBox(
              width: _slotWidth(context, actions.length),
              child: a,
            ),
          )
          .toList(growable: false),
    );
  }

  double _slotWidth(BuildContext context, int count) {
    final width = MediaQuery.sizeOf(context).width;
    // Reserve 32px page padding total + 8px gap between slots.
    final reserved = 32.0 + (8 * (count - 1));
    final available = width - reserved;
    return available / count;
  }
}
