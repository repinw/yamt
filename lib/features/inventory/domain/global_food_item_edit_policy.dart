import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

/// Defines global food item edit kind.
enum GlobalFoodItemEditKind {
  /// Unchanged.
  unchanged,

  /// Patch existing.
  patchExisting,

  /// Create new candidate.
  createNewCandidate,
}

const _amountParser = InventoryAmountParser();

/// Classify global food item edit.
GlobalFoodItemEditKind classifyGlobalFoodItemEdit({
  required GlobalFoodItem currentItem,
  required String name,
  String? brand,
  String? category,
  String? storeName,
  String? barcode,
  String? imageUrl,
  String? packageWeight,
  String? servingSize,
  double? servingQuantity,
  String? servingQuantityUnit,
  GlobalFoodNutrition? nutrition,
}) {
  var result = GlobalFoodItemEditKind.unchanged;

  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.name, name),
  );
  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.brand, brand),
  );
  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.category, category),
  );
  result = _mergeEditKinds(
    result,
    _classifyBarcodeChange(currentItem.barcode, barcode),
  );
  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.imageUrl, imageUrl),
  );
  result = _mergeEditKinds(
    result,
    _classifyPackageWeightChange(currentItem.packageWeight, packageWeight),
  );
  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.servingSize, servingSize),
  );
  result = _mergeEditKinds(
    result,
    _classifyDoubleChange(currentItem.servingQuantity, servingQuantity),
  );
  result = _mergeEditKinds(
    result,
    _classifyStringChange(currentItem.servingQuantityUnit, servingQuantityUnit),
  );
  return _mergeEditKinds(
    result,
    _classifyNutritionChange(currentItem.nutrition, nutrition),
  );
}

GlobalFoodItemEditKind _mergeEditKinds(
  GlobalFoodItemEditKind current,
  GlobalFoodItemEditKind next,
) {
  if (current == GlobalFoodItemEditKind.createNewCandidate ||
      next == GlobalFoodItemEditKind.createNewCandidate) {
    return GlobalFoodItemEditKind.createNewCandidate;
  }
  if (current == GlobalFoodItemEditKind.patchExisting ||
      next == GlobalFoodItemEditKind.patchExisting) {
    return GlobalFoodItemEditKind.patchExisting;
  }
  return GlobalFoodItemEditKind.unchanged;
}

GlobalFoodItemEditKind _classifyStringChange(String? current, String? next) {
  final currentValue = _normalizeOptional(current);
  final nextValue = _normalizeOptional(next);
  if (currentValue == nextValue) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (currentValue == null && nextValue != null) {
    return GlobalFoodItemEditKind.patchExisting;
  }
  return GlobalFoodItemEditKind.createNewCandidate;
}

GlobalFoodItemEditKind _classifyBarcodeChange(String? current, String? next) {
  final currentValue = normalizeBarcode(current ?? '');
  final nextValue = normalizeBarcode(next ?? '');
  if (currentValue == nextValue) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (currentValue.isEmpty && nextValue.isNotEmpty) {
    return GlobalFoodItemEditKind.patchExisting;
  }
  return GlobalFoodItemEditKind.createNewCandidate;
}

GlobalFoodItemEditKind _classifyPackageWeightChange(
  String? current,
  String? next,
) {
  final currentValue = _normalizeOptional(current);
  final nextValue = _normalizeOptional(next);
  if (currentValue == nextValue) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (currentValue == null && nextValue != null) {
    return GlobalFoodItemEditKind.patchExisting;
  }
  if (currentValue == null || nextValue == null) {
    return GlobalFoodItemEditKind.createNewCandidate;
  }

  final currentParsed = _amountParser.tryParse(
    rawWeight: currentValue,
    quantity: 1,
  );
  final nextParsed = _amountParser.tryParse(rawWeight: nextValue, quantity: 1);
  if (currentParsed != null &&
      nextParsed != null &&
      currentParsed.amount == nextParsed.amount &&
      currentParsed.unit == nextParsed.unit) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (_compactWeight(currentValue) == _compactWeight(nextValue)) {
    return GlobalFoodItemEditKind.unchanged;
  }
  return GlobalFoodItemEditKind.createNewCandidate;
}

GlobalFoodItemEditKind _classifyDoubleChange(double? current, double? next) {
  if (current == next) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (current == null && next != null) {
    return GlobalFoodItemEditKind.patchExisting;
  }
  return GlobalFoodItemEditKind.createNewCandidate;
}

GlobalFoodItemEditKind _classifyNutritionChange(
  GlobalFoodNutrition? current,
  GlobalFoodNutrition? next,
) {
  final currentValues = _nutritionValues(current);
  final nextValues = _nutritionValues(next);
  if (_nutritionMapsEqual(currentValues, nextValues)) {
    return GlobalFoodItemEditKind.unchanged;
  }
  if (currentValues.isEmpty && nextValues.isNotEmpty) {
    return GlobalFoodItemEditKind.patchExisting;
  }

  var result = GlobalFoodItemEditKind.unchanged;
  final keys = <String>{...currentValues.keys, ...nextValues.keys};
  for (final key in keys) {
    final fieldKind = _classifyDoubleChange(
      currentValues[key],
      nextValues[key],
    );
    result = _mergeEditKinds(result, fieldKind);
    if (result == GlobalFoodItemEditKind.createNewCandidate) {
      return result;
    }
  }
  return result;
}

Map<String, double> _nutritionValues(GlobalFoodNutrition? nutrition) {
  if (nutrition == null || !nutrition.hasAnyNutritionValue) {
    return const <String, double>{};
  }

  final values = <String, double>{};
  void addValue(String key, double? value) {
    if (value != null) {
      values[key] = value;
    }
  }

  addValue('kcal', nutrition.per100Kcal);
  addValue('protein', nutrition.per100Protein);
  addValue('carbs', nutrition.per100Carbs);
  addValue('fat', nutrition.per100Fat);
  addValue('salt', nutrition.per100Salt);
  addValue('saturated_fat', nutrition.per100SaturatedFat);
  addValue('polyunsaturated_fat', nutrition.per100PolyunsaturatedFat);
  addValue('sugar', nutrition.per100Sugar);
  addValue('fiber', nutrition.per100Fiber);
  return values;
}

bool _nutritionMapsEqual(Map<String, double> left, Map<String, double> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

String? _normalizeOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _compactWeight(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}
