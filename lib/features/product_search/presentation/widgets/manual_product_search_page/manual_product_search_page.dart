import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_launcher_page/manual_product_search_launcher_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';

/// Defines inventory receipt manual product page.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
class InventoryReceiptManualProductPage extends StatelessWidget {
  /// The inventory receipt manual product page.
  const InventoryReceiptManualProductPage({
    required this.item,
    super.key,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
    this.showEatImmediatelyOption = false,
    this.initialAction = InventoryReceiptManualProductAction.addToInventory,
    this.initialIntent = InventoryReceiptManualProductInitialIntent.launcher,
    this.onSaved,
  });

  /// The item.
  final InventoryItem item;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// The include store in search.
  final bool includeStoreInSearch;

  /// The include weight in search.
  final bool includeWeightInSearch;

  /// The show eat immediately option.
  final bool showEatImmediatelyOption;

  /// The initial action.
  final InventoryReceiptManualProductAction initialAction;

  /// The initial launcher intent.
  final InventoryReceiptManualProductInitialIntent initialIntent;

  /// Documented member.
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  Widget build(BuildContext context) {
    final config = InventoryReceiptManualProductConfig(
      item: item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: includeStoreInSearch,
      includeWeightInSearch: includeWeightInSearch,
    );

    if (_shouldOpenEditorImmediately(
      item: item,
      selectedProduct: selectedProduct,
    )) {
      return InventoryReceiptManualProductEditorPage(
        config: config,
        showEatImmediatelyOption: showEatImmediatelyOption,
        initialAction: initialAction,
        closeCurrentEditorOnSave: false,
        onSaved: onSaved,
      );
    }

    return InventoryReceiptManualProductLauncherPage(
      config: config,
      showEatImmediatelyOption: showEatImmediatelyOption,
      initialIntent: initialIntent,
      onSaved: onSaved,
    );
  }
}

bool _shouldOpenEditorImmediately({
  required InventoryItem item,
  required OffProductSearchResult? selectedProduct,
}) {
  return selectedProduct != null ||
      item.normalizedBarcode != null ||
      item.nutrition != null;
}
