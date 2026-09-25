import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_types.dart';

/// Context and callbacks for dispatching barcode scanner outcomes.
class EditorBarcodeDispatchContext {
  /// Creates the dispatch context.
  const new({
    required this.context,
    required this.config,
    required this.controller,
    required this.onDirectComplete,
    required this.onApplyScannedProduct,
    required this.onApplyScannedInventoryItem,
    required this.onApplyScannedBarcodeOnly,
    required this.onShowSnackBar,
  });

  /// Build context of the editor page.
  final BuildContext context;

  /// Product search configuration.
  final InventoryReceiptManualProductConfig config;

  /// Manual product search controller.
  final InventoryReceiptManualProductController controller;

  /// Callback when a direct eat flow completes.
  final void Function(InventoryReceiptManualProductResult result)
  onDirectComplete;

  /// Callback to apply a scanned external product.
  final void Function(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  )
  onApplyScannedProduct;

  /// Callback to apply a scanned inventory item.
  final void Function(
    InventoryItem item,
    InventoryReceiptManualProductAction action,
  )
  onApplyScannedInventoryItem;

  /// Callback to apply an unresolved barcode string.
  final void Function(String barcode) onApplyScannedBarcodeOnly;

  /// SnackBar message callback.
  final void Function(String message) onShowSnackBar;
}
