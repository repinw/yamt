import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Round quick filter chips with their counts: Alle, Offen, Mahlzeiten,
/// Fast leer. The selected chip is filled with ink.
class InventoryQuickFilterChips extends StatelessWidget {
  /// Creates the chips.
  const new({
    required this.selected,
    required this.counts,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  /// Selected chip.
  final InventoryQuickFilter selected;

  /// Count shown on each chip.
  final Map<InventoryQuickFilter, int> counts;

  /// Called with the tapped chip.
  final ValueChanged<InventoryQuickFilter> onSelected;

  /// Whether the chips react to taps.
  final bool enabled;

  /// Key of the chip for [filter].
  static Key chipKey(InventoryQuickFilter filter) =>
      Key('inventory_quick_filter_${filter.name}');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          for (final filter in InventoryQuickFilter.values)
            _Chip(
              key: chipKey(filter),
              label: switch (filter) {
                InventoryQuickFilter.all => l10n.inventoryQuickFilterAll,
                InventoryQuickFilter.open => l10n.inventoryQuickFilterOpen,
                InventoryQuickFilter.meals => l10n.inventoryQuickFilterMeals,
                InventoryQuickFilter.low => l10n.inventoryQuickFilterLow,
              },
              count: counts[filter] ?? 0,
              isSelected: filter == selected,
              onPressed: enabled ? () => onSelected(filter) : null,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const new({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final foreground = isSelected ? colors.paper : colors.ink;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? colors.ink : colors.tile,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: AppInkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppGraphit.chipHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$count',
                    style: textTheme.labelMedium?.copyWith(
                      color: isSelected ? colors.paper : colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
