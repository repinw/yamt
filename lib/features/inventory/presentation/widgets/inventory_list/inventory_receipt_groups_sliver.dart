import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'receipt_group_tile.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';

const double _inventoryReceiptGroupsBottomPadding =
    AppSpacing.xxxxl * 4 + AppSpacing.xxxl;

/// Defines inventory receipt groups sliver.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  InventoryItemsController,
  manualProductRecentItemsService,
])
class InventoryReceiptGroupsSliver extends StatelessWidget {
  /// The inventory receipt groups sliver.
  const InventoryReceiptGroupsSliver({
    required this.groups,
    required this.dateFormat,
    required this.activeShoppingListItemKeys,
    required this.actions,
    required this.selection,
    super.key,
  });

  /// The groups.
  final List<InventoryReceiptGroup> groups;

  /// The date format.
  final DateFormat dateFormat;

  /// The active shopping list item keys.
  final Set<ShoppingListItemMatchKey> activeShoppingListItemKeys;

  /// Inventory item row actions.
  final ReceiptGroupTileActions actions;

  /// Inventory item selection options.
  final ReceiptGroupSelectionOptions selection;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = responsivePageHorizontalPadding(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        _inventoryReceiptGroupsBottomPadding,
      ),
      sliver: SliverList.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            child: ReceiptGroupTile(
              group: group,
              dateFormat: dateFormat,
              activeShoppingListItemKeys: activeShoppingListItemKeys,
              actions: actions,
              selection: selection,
            ),
          );
        },
      ),
    );
  }
}
