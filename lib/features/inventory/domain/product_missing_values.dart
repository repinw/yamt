import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_unit_aliases.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// A value that a product needs for correct stock and calories but lacks.
enum ProductMissingValue {
  /// The package size, or only a placeholder such as "1 Stück".
  packageSize,

  /// The grams of one piece, for a size counted in pieces.
  pieceWeight,

  /// Energy per 100 g or ml.
  energy,

  /// Fat per 100 g or ml.
  fat,

  /// Saturated fat per 100 g or ml.
  saturatedFat,

  /// Carbohydrate per 100 g or ml.
  carbs,

  /// Sugars per 100 g or ml.
  sugar,

  /// Protein per 100 g or ml.
  protein,

  /// Salt per 100 g or ml.
  salt,
}

/// The values of the EU nutrition label (LMIV Art. 30) that [nutrition]
/// lacks, in the order of the label.
List<ProductMissingValue> missingNutritionValues(
  GlobalFoodNutrition? nutrition,
) {
  return [
    if (nutrition?.per100Kcal == null) ProductMissingValue.energy,
    if (nutrition?.per100Fat == null) ProductMissingValue.fat,
    if (nutrition?.per100SaturatedFat == null) ProductMissingValue.saturatedFat,
    if (nutrition?.per100Carbs == null) ProductMissingValue.carbs,
    if (nutrition?.per100Sugar == null) ProductMissingValue.sugar,
    if (nutrition?.per100Protein == null) ProductMissingValue.protein,
    if (nutrition?.per100Salt == null) ProductMissingValue.salt,
  ];
}

/// What [packageSize] lacks to give the package in grams or milliliters:
/// [ProductMissingValue.packageSize] without a size, or
/// [ProductMissingValue.pieceWeight] for pieces without a serving in grams
/// or milliliters. Null when the size is complete.
///
/// A size in pieces needs the grams of one piece, because nobody knows the
/// calories of "1 egg" without them.
ProductMissingValue? missingPackageSize({
  required String? packageSize,
  required double? servingQuantity,
  required String? servingQuantityUnit,
  InventoryAmountUnit? fallbackUnit,
}) {
  final parsed = const InventoryAmountParser().tryParse(
    rawWeight: packageSize,
    quantity: 1,
    fallbackUnit: fallbackUnit,
  );
  if (parsed == null || parsed.amount <= 0) {
    return ProductMissingValue.packageSize;
  }
  if (parsed.unit != InventoryAmountUnit.piece) {
    return null;
  }
  final servingUnit = resolveInventoryAmountUnitAlias(servingQuantityUnit)
      ?.base;
  final hasPieceWeight =
      (servingQuantity ?? 0) > 0 &&
      (servingUnit == InventoryAmountUnit.gram ||
          servingUnit == InventoryAmountUnit.milliliter);
  return hasPieceWeight ? null : ProductMissingValue.pieceWeight;
}

/// The values [item] lacks: its package size when [checkPackageSize], then
/// the nutrition values.
List<ProductMissingValue> missingItemValues(
  InventoryItem item, {
  required bool checkPackageSize,
}) {
  return [
    if (checkPackageSize)
      ?missingPackageSize(
        packageSize: item.weight,
        servingQuantity: item.servingQuantity,
        servingQuantityUnit: item.servingQuantityUnit,
        fallbackUnit: item.amountUnit,
      ),
    ...missingNutritionValues(item.nutrition),
  ];
}
