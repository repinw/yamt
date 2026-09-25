import 'package:flutter/foundation.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;

@immutable
/// Defines inventory receipt manual product config.
class InventoryReceiptManualProductConfig {
  /// The inventory receipt manual product config.
  const new({required this.item, this.selectedProduct});

  /// The item.
  final InventoryItem item;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryReceiptManualProductConfig &&
            other.item == item &&
            _selectedProductEquals(other.selectedProduct, selectedProduct);
  }

  @override
  int get hashCode {
    return Object.hash(item, _selectedProductHash(selectedProduct));
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

/// Defines inventory receipt manual product nutrition scan outcome.
enum InventoryReceiptManualProductNutritionScanOutcome {
  /// Documented member.
  applied,

  /// Documented member.
  canceled,

  /// Documented member.
  failed,

  /// Firebase App Check temporarily blocked the request.
  appCheckThrottled,

  /// Documented member.
  missingBarcode,
}

/// Defines inventory receipt manual product selection source.
enum InventoryReceiptManualProductSelectionSource {
  /// Documented member.
  externalSearch,

  /// Documented member.
  recentInventory,
}

/// Defines inventory receipt optional nutrition type.
enum InventoryReceiptOptionalNutritionType {
  /// Polyunsaturated fat.
  polyunsaturatedFat,

  /// Fiber.
  fiber,
}

/// Defines inventory receipt manual product selection.
class InventoryReceiptManualProductSelection {
  /// The inventory receipt manual product selection.
  const new({
    required this.source,
    required this.name,
    required this.barcode,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
    this.externalProduct,
    this.globalFoodItemId,
  });

  /// Creates a [InventoryReceiptManualProductSelection] for from search result.
  factory fromSearchResult(OffProductSearchResult result) {
    return InventoryReceiptManualProductSelection(
      source: InventoryReceiptManualProductSelectionSource.externalSearch,
      name: result.name,
      barcode: result.code,
      brand: result.brand,
      imageUrl: result.imageUrl,
      packageWeight: result.packageWeight,
      servingSize: result.servingSize,
      servingQuantity: result.servingQuantity,
      servingQuantityUnit: result.servingQuantityUnit,
      nutrition: result.nutrition,
      externalProduct: result,
      globalFoodItemId: result.globalFoodItemId,
    );
  }

  /// Creates a [InventoryReceiptManualProductSelection] from inventory item.
  factory fromInventoryItem(InventoryItem item) {
    return InventoryReceiptManualProductSelection(
      source: InventoryReceiptManualProductSelectionSource.recentInventory,
      name: item.name,
      barcode: item.normalizedBarcode ?? '',
      brand: item.brand,
      imageUrl: item.imageUrl,
      packageWeight: item.weight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
      globalFoodItemId: _normalizeReusableGlobalFoodItemId(
        item.globalFoodItemId,
      ),
    );
  }

  /// The source.
  final InventoryReceiptManualProductSelectionSource source;

  /// The name.
  final String name;

  /// The barcode.
  final String barcode;

  /// The brand.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// The package weight.
  final String? packageWeight;

  /// The serving size.
  final String? servingSize;

  /// The serving quantity.
  final double? servingQuantity;

  /// The serving quantity unit.
  final String? servingQuantityUnit;

  /// The nutrition.
  final GlobalFoodNutrition? nutrition;

  /// The external product.
  final OffProductSearchResult? externalProduct;

  /// The global food item id.
  final String? globalFoodItemId;
}

/// Structured save payload returned by manual product save builders.
typedef InventoryReceiptManualProductSavePayload = ({
  InventoryItem item,
  OffProductSearchResult? selectedProduct,
  String? selectedGlobalFoodItemId,
  bool requiresGlobalPersistence,
  String? globalPackageWeight,
});

String? _normalizeReusableGlobalFoodItemId(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (isPendingGlobalFoodItemId(normalized)) {
    return null;
  }
  return normalized;
}

/// Keeps the unit of a product that has no package size.
extension ManualProductItemWeightUnit on InventoryItem {
  /// Sets [unit] as the amount unit when no package size set one.
  ///
  /// Only grams and milliliters are kept: the eat page then asks for that
  /// unit instead of pieces. Pieces need no unit.
  InventoryItem withWeightUnitWithoutPackage(InventoryAmountUnit? unit) {
    if (amountUnit != null ||
        (unit != InventoryAmountUnit.gram &&
            unit != InventoryAmountUnit.milliliter)) {
      return this;
    }
    return copyWith(amountUnit: unit);
  }
}
