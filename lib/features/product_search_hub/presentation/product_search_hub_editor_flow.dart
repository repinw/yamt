import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart'
    as manual_product_models;
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_quick_eat_config.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _productSearchHubDraftItemId = Uuid();

/// Builds the base draft item used by the product search hub editor.
InventoryItem buildProductSearchHubDraftItem({
  required AppLocalizations l10n,
  InventoryItem? sourceItem,
}) {
  if (sourceItem != null) {
    return sourceItem;
  }
  return buildInventoryManualAddDraftItem(
    id: _productSearchHubDraftItemId.v4(),
    now: DateTime.now(),
    storeName: l10n.inventoryManualAddStoreName,
    scannedBarcode: '',
    name: '',
  );
}

/// Opens the existing manual product editor for a selected search product.
Future<InventoryReceiptManualProductResult?>
openProductSearchHubSelectedProductEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required OffProductSearchResult product,
  required ProductSearchHubRouteArgs args,
  String? initialInfoMessage,
}) {
  return _openProductSearchHubEditor(
    context: context,
    draftItem: draftItem,
    args: args,
    selectedProduct: product,
    initialInfoMessage: initialInfoMessage,
  );
}

/// Opens the existing manual product editor for a recent inventory item.
Future<InventoryReceiptManualProductResult?>
openProductSearchHubRecentItemEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required InventoryItem recentItem,
  required ProductSearchHubRouteArgs args,
  String? initialInfoMessage,
}) {
  return _openProductSearchHubEditor(
    context: context,
    draftItem: draftItem,
    args: args,
    initialRecentItem: recentItem,
    initialInfoMessage: initialInfoMessage,
  );
}

/// Opens the existing manual product editor for a new custom item.
Future<InventoryReceiptManualProductResult?>
openProductSearchHubCustomProductEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  String? scannedBarcode,
  String? initialName,
  String? initialInfoMessage,
}) {
  final draftWithInitialValues = productSearchHubDraftItemWithInitialValues(
    draftItem: draftItem,
    scannedBarcode: scannedBarcode,
    initialName: initialName,
  );
  return _openProductSearchHubEditor(
    context: context,
    draftItem: draftWithInitialValues,
    args: args,
    initialInfoMessage: initialInfoMessage,
  );
}

/// Applies optional initial editor values to a hub draft item.
InventoryItem productSearchHubDraftItemWithInitialValues({
  required InventoryItem draftItem,
  required String? scannedBarcode,
  required String? initialName,
}) {
  final normalizedName = initialName == null
      ? null
      : normalizeManualProductText(initialName);
  return draftItem.copyWith(
    barcode: scannedBarcode ?? draftItem.barcode,
    name: normalizedName ?? draftItem.name,
  );
}

Future<InventoryReceiptManualProductResult?> _openProductSearchHubEditor({
  required BuildContext context,
  required InventoryItem draftItem,
  required ProductSearchHubRouteArgs args,
  OffProductSearchResult? selectedProduct,
  InventoryItem? initialRecentItem,
  String? initialInfoMessage,
}) {
  return pushManualProductSearchPage<InventoryReceiptManualProductResult>(
    context: context,
    args: ManualProductSearchRouteArgs.editor(
      config: manual_product_models.InventoryReceiptManualProductConfig(
        item: draftItem,
        selectedProduct: selectedProduct,
      ),
      showEatImmediatelyOption: args.mode == ProductSearchHubMode.diary,
      initialAction: _initialActionForMode(args.mode),
      closeCurrentEditorOnSave: true,
      showActionSelector: false,
      quickEatConfig: productSearchHubQuickEatConfig(args),
      initialRecentItem: initialRecentItem,
      initialInfoMessage: initialInfoMessage,
    ),
  );
}

manual_product_models.InventoryReceiptManualProductAction _initialActionForMode(
  ProductSearchHubMode mode,
) {
  return switch (mode) {
    ProductSearchHubMode.inventory =>
      manual_product_models.InventoryReceiptManualProductAction.addToInventory,
    ProductSearchHubMode.selection =>
      manual_product_models.InventoryReceiptManualProductAction.addToInventory,
    ProductSearchHubMode.diary =>
      manual_product_models.InventoryReceiptManualProductAction.eatNow,
  };
}
