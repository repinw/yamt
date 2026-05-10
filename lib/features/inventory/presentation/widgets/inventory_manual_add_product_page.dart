import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_models.dart';

/// Product selection surface for manual inventory add.
@Dependencies([inventoryItemRepository])
class InventoryManualAddProductPage extends StatelessWidget {
  /// Creates product selection surface.
  const InventoryManualAddProductPage({
    required this.item,
    required this.initialIntent,
    required this.onSaved,
    super.key,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
  });

  /// Draft inventory item used by the product search flow.
  final InventoryItem item;

  /// Initial product-search launcher intent.
  final InventoryReceiptManualProductInitialIntent initialIntent;

  /// Initial result action.
  final InventoryReceiptManualProductAction initialAction;

  /// Called when the product flow returns a save result.
  final Future<void> Function(InventoryReceiptManualProductResult result)
  onSaved;

  @override
  Widget build(BuildContext context) {
    return InventoryReceiptManualProductPage(
      item: item,
      showEatImmediatelyOption: true,
      initialIntent: initialIntent,
      initialAction: initialAction,
      onSaved: onSaved,
    );
  }
}
