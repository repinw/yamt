import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/controllers/manual_product_search_models.dart';

/// Initial action for the manual product launcher.
enum InventoryReceiptManualProductInitialIntent {
  /// Show the launcher without opening a child flow.
  launcher,

  /// Open the text search editor immediately.
  manualSearch,

  /// Open the AI suggestion page immediately.
  aiSuggestion,

  /// Open the barcode scanner immediately.
  barcodeScan,
}

/// Defines inventory receipt manual product result.
class InventoryReceiptManualProductResult {
  /// The inventory receipt manual product result.
  const InventoryReceiptManualProductResult({
    required this.item,
    required this.action,
    this.selectedProduct,
    this.selectedGlobalFoodItemId,
    this.requiresGlobalPersistence = true,
    this.globalPackageWeight,
    this.skipMissingBarcodePrompt = false,
    this.eatSelection,
  });

  /// The item.
  final InventoryItem item;

  /// The action.
  final InventoryReceiptManualProductAction action;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// The selected global food item id.
  final String? selectedGlobalFoodItemId;

  /// The requires global persistence.
  final bool requiresGlobalPersistence;

  /// The package weight to persist on the global product.
  final String? globalPackageWeight;

  /// Whether missing barcode prompt should be skipped.
  final bool skipMissingBarcodePrompt;

  /// Generic eat selection to complete after saving.
  final EatSelection? eatSelection;
}
