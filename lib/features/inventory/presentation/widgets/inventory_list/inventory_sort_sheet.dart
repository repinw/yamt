import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_list_view_controller.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the Sortieren sheet of the Vorrat list. Every change applies at
/// once.
Future<void> showInventorySortSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const InventorySortSheet(),
  );
}

/// Sort field with its direction, "Verbrauchte ausblenden" and "Nach Beleg".
/// Tapping the selected field again flips its direction.
class InventorySortSheet extends ConsumerWidget {
  /// Creates the sheet content.
  const new({super.key});

  /// Key of the row for [criterion].
  static Key criterionKey(InventorySortCriterion criterion) =>
      Key('inventory_sort_${criterion.name}');

  /// Key of the "Verbrauchte ausblenden" switch.
  static const hideConsumedKey = Key('inventory_sort_hide_consumed');

  /// Key of the "Nach Beleg" switch.
  static const groupByReceiptKey = Key('inventory_sort_group_by_receipt');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final preferences = ref.watch(
      inventoryListViewControllerProvider.select((state) => state.preferences),
    );
    final controller = ref.read(inventoryListViewControllerProvider.notifier);
    final current = preferences.sortMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.inventorySortAction,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final criterion in InventorySortCriterion.values)
            _CriterionRow(
              key: criterionKey(criterion),
              label: _criterionLabel(l10n, criterion),
              direction: current.criterion == criterion
                  ? _directionLabel(l10n, current)
                  : null,
              isAscending: current.isAscending,
              onPressed: () => controller.setSortMode(
                current.criterion == criterion
                    ? current.flipped
                    : criterion.defaultMode,
              ),
            ),
          const Divider(height: AppSpacing.xxl),
          AppSwitchListTile(
            key: hideConsumedKey,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.inventoryHideConsumedFilterTitle),
            value: preferences.hideConsumed,
            onChanged: (value) =>
                controller.setHideConsumed(hideConsumed: value),
          ),
          AppSwitchListTile(
            key: groupByReceiptKey,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.inventoryListModeByReceipt),
            value: preferences.groupByReceipt,
            onChanged: (value) =>
                controller.setGroupByReceipt(groupByReceipt: value),
          ),
        ],
      ),
    );
  }

  String _criterionLabel(
    AppLocalizations l10n,
    InventorySortCriterion criterion,
  ) {
    return switch (criterion) {
      InventorySortCriterion.added => l10n.inventorySortAdded,
      InventorySortCriterion.eaten => l10n.inventorySortEaten,
      InventorySortCriterion.alphabetical => l10n.inventorySortAlphabetical,
      InventorySortCriterion.amount => l10n.inventorySortQuantity,
    };
  }

  String _directionLabel(AppLocalizations l10n, InventoryItemSortMode mode) {
    return switch (mode) {
      InventoryItemSortMode.recentlyAddedDescending ||
      InventoryItemSortMode.recentlyEatenDescending =>
        l10n.inventorySortNewestFirst,
      InventoryItemSortMode.recentlyAddedAscending ||
      InventoryItemSortMode.recentlyEatenAscending =>
        l10n.inventorySortOldestFirst,
      InventoryItemSortMode.alphabeticalAscending =>
        l10n.inventorySortDirectionAlphaAscending,
      InventoryItemSortMode.alphabeticalDescending =>
        l10n.inventorySortDirectionAlphaDescending,
      InventoryItemSortMode.availableAmountAscending =>
        l10n.inventorySortLeastFirst,
      InventoryItemSortMode.availableAmountDescending =>
        l10n.inventorySortMostFirst,
    };
  }
}

class _CriterionRow extends StatelessWidget {
  const new({
    required this.label,
    required this.direction,
    required this.isAscending,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// Direction text of the selected field; null when not selected.
  final String? direction;
  final bool isAscending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final direction = this.direction;
    final isSelected = direction != null;
    return Material(
      color: isSelected ? colors.tile : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: isSelected,
        onTap: onPressed,
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isSelected ? colors.ink : colors.muted,
        ),
        title: Text(
          label,
          style: textTheme.bodyLarge?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: direction == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xxs,
                children: [
                  Icon(
                    isAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: AppGraphit.chipIcon,
                    color: colors.muted,
                  ),
                  Text(
                    direction,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
