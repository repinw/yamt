import 'package:flutter/foundation.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;

@immutable
/// Defines inventory receipt manual product config.
class InventoryReceiptManualProductConfig {
  /// The inventory receipt manual product config.
  const new({required this.item, this.selectedProduct, this.isEdit = false});

  /// The item.
  final InventoryItem item;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// Whether the editor changes a food that exists. Its save already
  /// answered the barcode question, so a food without one counts as having
  /// none.
  final bool isEdit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryReceiptManualProductConfig &&
            other.item == item &&
            other.isEdit == isEdit &&
            _selectedProductEquals(other.selectedProduct, selectedProduct);
  }

  @override
  int get hashCode {
    return Object.hash(item, isEdit, _selectedProductHash(selectedProduct));
  }

  static bool _selectedProductEquals(
    OffProductSearchResult? left,
    OffProductSearchResult? right,
  ) {
    return left?.code == right?.code &&
        left?.name == right?.name &&
        left?.score == right?.score &&
        left?.brand == right?.brand &&
        left?.imageUrl == right?.imageUrl &&
        left?.packageWeight == right?.packageWeight &&
        left?.servingSize == right?.servingSize &&
        left?.servingQuantity == right?.servingQuantity &&
        left?.servingQuantityUnit == right?.servingQuantityUnit &&
        left?.nutrition == right?.nutrition;
  }

  static int _selectedProductHash(OffProductSearchResult? product) {
    return Object.hash(
      product?.code,
      product?.name,
      product?.score,
      product?.brand,
      product?.imageUrl,
      product?.packageWeight,
      product?.servingSize,
      product?.servingQuantity,
      product?.servingQuantityUnit,
      product?.nutrition,
    );
  }
}

/// Defines inventory receipt manual product error.
enum InventoryReceiptManualProductError {
  /// Documented member.
  requiredProductOrNutrition,

  /// Documented member.
  requiredPackageWeight,
}

/// Defines inventory receipt manual product action.
typedef InventoryReceiptManualProductAction =
    inventory_models.InventoryReceiptManualProductAction;

/// Where a barcode on a package photo came from.
enum ManualProductBarcodeOrigin {
  /// The barcode scanner found it on a photo.
  photo,

  /// The AI read its digits on the front photo.
  ai,
}

/// Defines inventory receipt optional nutrition type.
enum InventoryReceiptOptionalNutritionType {
  /// Polyunsaturated fat.
  polyunsaturatedFat,

  /// Fiber.
  fiber,
}

/// Structured save payload returned by manual product save builders.
typedef InventoryReceiptManualProductSavePayload = ({
  InventoryItem item,
  OffProductSearchResult? selectedProduct,
  String? selectedGlobalFoodItemId,
  bool requiresGlobalPersistence,
  String? globalPackageWeight,
});

/// The editor's result for a save payload, so a new result field is added
/// in one place.
extension InventoryReceiptManualProductSavePayloadResult
    on InventoryReceiptManualProductSavePayload {
  /// The result that saves this payload with [action]. A product the user
  /// marked as having no barcode passes [skipMissingBarcodePrompt].
  inventory_models.InventoryReceiptManualProductResult toResult(
    InventoryReceiptManualProductAction action, {
    bool skipMissingBarcodePrompt = false,
  }) {
    return inventory_models.InventoryReceiptManualProductResult(
      item: item,
      action: action,
      selectedProduct: selectedProduct,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      requiresGlobalPersistence: requiresGlobalPersistence,
      globalPackageWeight: globalPackageWeight,
      skipMissingBarcodePrompt: skipMissingBarcodePrompt,
    );
  }
}
