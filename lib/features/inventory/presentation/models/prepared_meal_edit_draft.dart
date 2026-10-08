import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

/// What the meal editor saves: the name, a changed picture, the portions
/// and the amount of each ingredient.
@immutable
class PreparedMealEditResult {
  /// Creates the result.
  const new({
    required this.name,
    required this.imageChanged,
    required this.imageBytes,
    required this.totalPortions,
    required this.items,
  });

  /// The meal name.
  final String name;

  /// Whether the picture changed; [imageBytes] is then the new picture, or
  /// null when the user removed it.
  final bool imageChanged;

  /// The new picture.
  final Uint8List? imageBytes;

  /// Portions the whole meal makes.
  final int totalPortions;

  /// Ingredients with the amount the meal uses.
  final List<PreparedMealItemInput> items;
}

/// One ingredient on the meal editor.
@immutable
class PreparedMealEditRow {
  const new _({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.unit,
    required this.amount,
    required this.maxAmount,
    required this._baseFacts,
    required this._baseAmount,
  });

  /// Row of an ingredient already in the meal. [available] is what the
  /// stock still holds of it, so the meal can take that much more.
  factory ofComponent(PreparedMealComponent component, {int available = 0}) {
    return PreparedMealEditRow._(
      itemId: component.inventoryItemId,
      name: component.name,
      imageUrl: component.imageUrl,
      unit: component.usedUnit,
      amount: component.usedAmount,
      maxAmount: component.usedAmount + available,
      baseFacts: NutritionFacts(
        kcal: component.totalKcal,
        protein: component.totalProtein,
        carbs: component.totalCarbs,
        fat: component.totalFat,
      ),
      baseAmount: component.usedAmount.toDouble(),
    );
  }

  /// Row of a stock item that joins the meal with [amount], or null when
  /// the item has no nutrition values.
  static PreparedMealEditRow? ofItem(InventoryItem item, int amount) {
    final nutrition = item.nutrition;
    if (nutrition == null) {
      return null;
    }
    return PreparedMealEditRow._(
      itemId: item.id,
      name: item.name,
      imageUrl: item.imageUrl,
      unit: item.amountUnit ?? InventoryAmountUnit.piece,
      amount: amount,
      maxAmount: mealFoodMaxAmount(item),
      baseFacts: EatNutrition.fromPer100(nutrition, _per100).eaten,
      baseAmount: _per100,
    );
  }

  static const _per100 = 100.0;

  /// Stock item the ingredient comes from.
  final String itemId;

  /// Ingredient name.
  final String name;

  /// Ingredient picture.
  final String? imageUrl;

  /// Unit of [amount].
  final InventoryAmountUnit unit;

  /// Amount the meal uses.
  final int amount;

  /// Largest amount the stock allows.
  final int maxAmount;

  final NutritionFacts _baseFacts;
  final double _baseAmount;

  /// Whether the amount can change on a ruler: only grams and milliliters.
  bool get hasRuler => _consumedUnit != null && maxAmount > 0;

  /// This row with [amount], kept between one and [maxAmount].
  PreparedMealEditRow withAmount(int amount) {
    return PreparedMealEditRow._(
      itemId: itemId,
      name: name,
      imageUrl: imageUrl,
      unit: unit,
      amount: amount.clamp(1, maxAmount < 1 ? 1 : maxAmount),
      maxAmount: maxAmount,
      baseFacts: _baseFacts,
      baseAmount: _baseAmount,
    );
  }

  /// Nutrients of [amount].
  NutritionFacts get eaten =>
      _baseAmount <= 0 ? _baseFacts : _baseFacts.scaled(amount / _baseAmount);

  /// The row as a meal food. Pieces add no weight to the meal.
  EatMealFood get food {
    final consumedUnit = _consumedUnit;
    return (
      eaten: eaten,
      amount: consumedUnit == null ? 0 : amount.toDouble(),
      unit: consumedUnit ?? ConsumedUnit.grams,
    );
  }

  /// The row as the input the meal update takes.
  PreparedMealItemInput get input =>
      PreparedMealItemInput(itemId: itemId, usedAmount: amount);

  ConsumedUnit? get _consumedUnit => switch (unit) {
    InventoryAmountUnit.gram => ConsumedUnit.grams,
    InventoryAmountUnit.milliliter => ConsumedUnit.milliliters,
    InventoryAmountUnit.piece => null,
  };
}
