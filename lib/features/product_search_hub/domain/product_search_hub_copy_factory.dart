import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

const _copyDraftUuid = Uuid();

/// Builds an immutable new draft cloned from a search result template.
///
/// Ensures strict precedence for immutability and data integrity:
/// - A new image on [baseItem] is never overwritten by an older template image.
/// - Freshly entered or scanned nutrition on [baseItem] is never overwritten by
///   older template nutrition.
/// - The cloned draft receives a fresh UUID and is decoupled from any
///   global food item ID so it is treated as an independent candidate.
InventoryItem cloneSearchResultAsDraftItem({
  required OffProductSearchResult template,
  required DateTime now,
  required String storeName,
  InventoryItem? baseItem,
  String? newId,
  String? recipeVersionNote,
}) {
  return _buildClonedDraftFromSources(
    templateName: template.name,
    templateBrand: template.brand,
    templateBarcode: template.code,
    templateImageUrl: template.imageUrl,
    templateWeight: template.packageWeight,
    templateServingSize: template.servingSize,
    templateServingQuantity: template.servingQuantity,
    templateServingQuantityUnit: template.servingQuantityUnit,
    templateNutrition: template.nutrition,
    baseItem: baseItem,
    now: now,
    storeName: storeName,
    newId: newId,
    recipeVersionNote: recipeVersionNote,
  );
}

/// Builds an immutable new draft cloned from an existing inventory item
/// template.
InventoryItem cloneInventoryItemAsDraftItem({
  required InventoryItem template,
  required DateTime now,
  required String storeName,
  InventoryItem? baseItem,
  String? newId,
  String? recipeVersionNote,
}) {
  return _buildClonedDraftFromSources(
    templateName: template.name,
    templateBrand: template.brand,
    templateBarcode: template.barcode,
    templateImageUrl: template.imageUrl,
    templateWeight: template.weight,
    templateServingSize: template.servingSize,
    templateServingQuantity: template.servingQuantity,
    templateServingQuantityUnit: template.servingQuantityUnit,
    templateNutrition: template.nutrition,
    baseItem: baseItem,
    now: now,
    storeName: storeName,
    newId: newId,
    recipeVersionNote: recipeVersionNote,
  );
}

InventoryItem _buildClonedDraftFromSources({
  required String templateName,
  required String? templateBrand,
  required String? templateBarcode,
  required String? templateImageUrl,
  required String? templateWeight,
  required String? templateServingSize,
  required double? templateServingQuantity,
  required String? templateServingQuantityUnit,
  required GlobalFoodNutrition? templateNutrition,
  required DateTime now,
  required String storeName,
  InventoryItem? baseItem,
  String? newId,
  String? recipeVersionNote,
}) {
  final baseName = _resolveNonEmpty(baseItem?.name) ?? templateName;
  final resolvedWeight =
      _resolveNonEmpty(baseItem?.weight) ?? _resolveNonEmpty(templateWeight);

  return InventoryItem.create(
    id: newId ?? _copyDraftUuid.v4(),
    name: _applyRecipeVersionNote(baseName, recipeVersionNote),
    entryDate: now,
    storeName: storeName,
    origin: InventoryItemOrigin.manualAdd,
    quantity: baseItem?.quantity ?? 1,
    brand: _resolveNonEmpty(baseItem?.brand) ?? templateBrand,
    barcode:
        _resolveNonEmpty(baseItem?.barcode) ??
        _resolveNonEmpty(templateBarcode) ??
        '',
    imageUrl:
        _resolveNonEmpty(baseItem?.imageUrl) ??
        _resolveNonEmpty(templateImageUrl),
    weight: resolvedWeight,
    servingSize: baseItem?.servingSize ?? templateServingSize,
    servingQuantity: baseItem?.servingQuantity ?? templateServingQuantity,
    servingQuantityUnit:
        baseItem?.servingQuantityUnit ?? templateServingQuantityUnit,
    nutrition: _resolveNutrition(
      baseNutrition: baseItem?.nutrition,
      templateNutrition: templateNutrition,
    ),
  ).withDerivedAmount(weight: resolvedWeight, quantity: 1);
}

String _applyRecipeVersionNote(String name, String? note) {
  final trimmedNote = note?.trim();
  if (trimmedNote == null || trimmedNote.isEmpty) {
    return name;
  }
  return '$name ($trimmedNote)';
}

String? _resolveNonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

GlobalFoodNutrition? _resolveNutrition({
  required GlobalFoodNutrition? baseNutrition,
  required GlobalFoodNutrition? templateNutrition,
}) {
  if (baseNutrition != null && baseNutrition.hasAnyNutritionValue) {
    return baseNutrition;
  }
  return templateNutrition;
}
