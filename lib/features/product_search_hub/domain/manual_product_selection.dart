import 'package:meta/meta.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/data/off_product_search_result.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Where the food picked in the product editor came from.
enum InventoryReceiptManualProductSelectionSource {
  /// A product search result, for example from the shared catalog.
  externalSearch,

  /// A food the user already has in their stock.
  recentInventory,
}

/// The food picked in the product editor, whose values fill the form.
@immutable
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
    this.aiEstimated = false,
  });

  /// The selection for a product search [result].
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

  /// The selection for a food [item] from the user's stock.
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
      aiEstimated: item.aiEstimated,
    );
  }

  /// The source.
  final InventoryReceiptManualProductSelectionSource source;

  /// Whether the picked food is an AI estimate, which stays the user's own
  /// (#701).
  final bool aiEstimated;

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

const _tolerance = 0.000001;

/// Whether saving [selection] writes to the shared catalog.
bool manualProductRequiresGlobalPersistence({
  required InventoryReceiptManualProductSelection? selection,
  required GlobalFoodItemEditKind editKind,
  required bool aiEstimated,
}) {
  // An AI estimate stays the user's own, also after an edit (#701).
  if (aiEstimated) {
    return false;
  }
  if (selection == null) {
    return true;
  }
  if (selection.externalProduct != null) {
    return true;
  }
  return editKind == GlobalFoodItemEditKind.patchExisting;
}

/// Whether [left] and [right] hold the same values per 100 g.
bool manualProductHasSameNutrition(
  GlobalFoodNutrition left,
  GlobalFoodNutrition right,
) {
  return _sameAmount(left.per100Kcal, right.per100Kcal) &&
      _sameAmount(left.per100Protein, right.per100Protein) &&
      _sameAmount(left.per100Carbs, right.per100Carbs) &&
      _sameAmount(left.per100Fat, right.per100Fat) &&
      _sameAmount(left.per100Salt, right.per100Salt) &&
      _sameAmount(left.per100SaturatedFat, right.per100SaturatedFat) &&
      _sameAmount(
        left.per100PolyunsaturatedFat,
        right.per100PolyunsaturatedFat,
      ) &&
      _sameAmount(left.per100Sugar, right.per100Sugar) &&
      _sameAmount(left.per100Fiber, right.per100Fiber);
}

bool _sameAmount(double? left, double? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return (left - right).abs() <= _tolerance;
}

/// The catalog item that [selection] stands for.
GlobalFoodItem manualProductGlobalFoodItem(
  InventoryReceiptManualProductSelection selection,
) {
  return GlobalFoodItem.create(
    id: selection.globalFoodItemId ?? '',
    name: selection.name,
    now: DateTime.fromMillisecondsSinceEpoch(0),
    brand: selection.brand,
    barcode: selection.barcode,
    imageUrl: normalizeProductImageUrl(selection.imageUrl),
    packageWeight: selection.packageWeight,
    servingSize: selection.servingSize,
    servingQuantity: selection.servingQuantity,
    servingQuantityUnit: selection.servingQuantityUnit,
    nutrition: selection.nutrition,
  );
}
