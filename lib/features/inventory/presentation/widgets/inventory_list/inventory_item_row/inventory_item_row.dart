import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_progress.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_row_main_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_row_snapshot.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/inventory_item_row_view_data.dart';

/// Row of a stock item in the inventory list. A tap opens the item hub, or
/// toggles the selection in selection mode.
class InventoryItemRow extends ConsumerWidget {
  /// Creates the row.
  const new({
    required this.item,
    required this.isAlreadyInShoppingList,
    super.key,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onStartSelection,
    this.onSelectionToggle,
  });

  /// The item.
  final InventoryItem item;

  /// Whether the item is already on the shopping list.
  final bool isAlreadyInShoppingList;

  /// Whether selection mode.
  final bool isSelectionMode;

  /// Whether selected.
  final bool isSelected;

  /// Called by a long press to start the selection.
  final VoidCallback? onStartSelection;

  /// Called by a tap in selection mode.
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: AppInkWell(
            onTap: isSelectionMode
                ? (onSelectionToggle ?? () {})
                : () => unawaited(
                    InventoryItemHubFlow.open(
                      context: context,
                      ref: ref,
                      item: item,
                      isOnShoppingList: isAlreadyInShoppingList,
                    ),
                  ),
            onLongPress: isSelectionMode ? null : onStartSelection,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: InventoryItemRowMainSection(
                item: InventoryItemRowSnapshot.fromItem(item),
                viewData: _viewData(context),
                showSelectionCheckbox: isSelectionMode,
                isSelected: isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InventoryItemRowViewData _viewData(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = const InventoryItemProgressCalculator().fromItem(item);
    final brand = item.brand?.trim() ?? '';
    final nameStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: item.isFullyConsumed
          ? colors.onSurface.withValues(alpha: AppOpacities.inventoryUsedUpName)
          : colors.onSurface,
      fontSize: AppInventoryClosedTile.titleFontSize,
      fontWeight: FontWeight.w700,
      height: AppInventoryClosedTile.titleLineHeight,
      letterSpacing: 0,
    );
    return InventoryItemRowViewData(
      nameTextStyle: nameStyle,
      hasBrand: brand.isNotEmpty,
      brand: brand,
      remainingRatio: progress.remainingRatio,
      remainingLabel: progress.remainingLabel,
      segmentedByUnits: progress.segmentedByUnits,
    );
  }
}
