import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Horizontal filter chips for narrowing the active report down to one
/// category. Hidden when fewer than 2 categories are available so we don't
/// clutter the UI with a no-op filter.
class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return ChoiceChip(
              selected: selected == null,
              label: Text(l.reportsFilterAll),
              onSelected: (_) => onSelected(null),
              selectedColor: scheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: selected == null ? scheme.primary : scheme.onSurface,
                fontWeight:
                    selected == null ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected == null
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              ),
            );
          }
          final c = categories[i - 1];
          final isSelected = c == selected;
          return ChoiceChip(
            selected: isSelected,
            label: Text(c),
            onSelected: (_) => onSelected(isSelected ? null : c),
            selectedColor: scheme.primary.withValues(alpha: 0.12),
            labelStyle: TextStyle(
              color: isSelected ? scheme.primary : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
