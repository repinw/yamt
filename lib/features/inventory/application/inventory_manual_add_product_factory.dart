import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Builds the empty draft item used by manual add product search.
InventoryItem buildInventoryManualAddDraftItem({
  required String id,
  required DateTime now,
  required String storeName,
  required String scannedBarcode,
  required String name,
  String? brand,
  String? imageUrl,
  String? weight,
  String? servingSize,
  double? servingQuantity,
  String? servingQuantityUnit,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: now,
    storeName: storeName,
    origin: InventoryItemOrigin.manualAdd,
    quantity: 1,
    brand: brand,
    barcode: scannedBarcode,
    imageUrl: imageUrl,
    servingSize: servingSize,
    servingQuantity: servingQuantity,
    servingQuantityUnit: servingQuantityUnit,
    nutrition: nutrition,
    weight: weight,
  ).withDerivedAmount(weight: weight, quantity: 1);
}

/// Builds global food item from manual add selection.
GlobalFoodItem buildInventoryManualAddGlobalFoodItem({
  required InventoryItem item,
  required String? barcode,
  required DateTime now,
  required String? packageWeight,
  required String manualGlobalFoodItemId,
  OffProductSearchResult? selectedProduct,
  String? selectedGlobalFoodItemId,
}) {
  return GlobalFoodItem.create(
    id:
        selectedGlobalFoodItemId ??
        _selectedProductGlobalFoodItemId(
          selectedProduct: selectedProduct,
          barcode: barcode,
        ) ??
        inventoryManualAddGlobalFoodItemIdFor(
          item: item,
          barcode: barcode,
          manualGlobalFoodItemId: manualGlobalFoodItemId,
        ),
    name: item.name,
    now: now,
    brand: item.brand,
    barcode: barcode,
    imageUrl: normalizeProductImageUrl(item.imageUrl),
    packageWeight: packageWeight,
    servingSize: item.servingSize ?? selectedProduct?.servingSize,
    servingQuantity: item.servingQuantity ?? selectedProduct?.servingQuantity,
    servingQuantityUnit:
        item.servingQuantityUnit ?? selectedProduct?.servingQuantityUnit,
    nutrition: item.nutrition,
  );
}

/// Builds inventory item persisted from manual add selection.
InventoryItem buildInventoryManualAddSavedItem({
  required String id,
  required GlobalFoodItem globalProduct,
  required bool globalSaved,
  required DateTime now,
  required String storeName,
  required String? inventoryWeight,
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: globalSaved ? globalProduct.id : null,
    name: globalProduct.name,
    entryDate: now,
    storeName: storeName,
    origin: InventoryItemOrigin.manualAdd,
    quantity: 1,
    brand: globalProduct.brand,
    barcode: globalProduct.barcode,
    imageUrl: globalProduct.imageUrl,
    servingSize: globalProduct.servingSize,
    servingQuantity: globalProduct.servingQuantity,
    servingQuantityUnit: globalProduct.servingQuantityUnit,
    nutrition: globalProduct.nutrition,
    weight: inventoryWeight,
    foodFingerprint: globalProduct.resolvedFoodFingerprint,
  ).withDerivedAmount(weight: inventoryWeight, quantity: 1);
}

/// Resolves inventory-local package weight text.
String? resolveInventoryManualAddInventoryWeight(String? packageWeight) {
  final normalizedPackageWeight = packageWeight?.trim();
  if (normalizedPackageWeight != null && normalizedPackageWeight.isNotEmpty) {
    return normalizedPackageWeight;
  }
  return null;
}

/// Builds fallback global food item id for a manual add item.
String inventoryManualAddGlobalFoodItemIdFor({
  required InventoryItem item,
  required String? barcode,
  required String manualGlobalFoodItemId,
}) {
  if (barcode == null || barcode.isEmpty) {
    return 'manual-food-$manualGlobalFoodItemId';
  }
  final normalizedName = normalizeGlobalFoodText(item.name);
  final normalizedBrand = normalizeGlobalFoodText(item.brand ?? '');
  final suffix = <String>[
    normalizedName,
    normalizedBrand,
  ].where((value) => value.isNotEmpty).join('-');
  if (suffix.isEmpty) {
    return 'off-$barcode';
  }
  return 'off-$barcode-$suffix';
}

String? _selectedProductGlobalFoodItemId({
  required OffProductSearchResult? selectedProduct,
  required String? barcode,
}) {
  if (selectedProduct == null) {
    return null;
  }
  final normalizedBarcode = selectedProduct.code.trim().isEmpty
      ? barcode
      : selectedProduct.code;
  if (normalizedBarcode == null || normalizedBarcode.isEmpty) {
    return null;
  }
  return 'off-$normalizedBarcode';
}
