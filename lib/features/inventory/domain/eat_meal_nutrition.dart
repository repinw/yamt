import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// One food of a meal on the item hub: its eaten nutrients and amount.
typedef EatMealFood = ({
  NutritionFacts eaten,
  double amount,
  ConsumedUnit unit,
});

/// Nutrients of several foods eaten together.
@immutable
class EatMealNutrition {
  const new _({
    required this.total,
    required this.listed,
    required this.per100,
    required this.amounts,
  });

  /// Adds up [foods].
  ///
  /// A total is unknown when one food does not list the nutrient, the same
  /// rule the combined diary entry follows. The per-100 values exist only
  /// when all foods share one unit, since grams and milliliters do not add
  /// up.
  factory combine(List<EatMealFood> foods) {
    double? sum(double? Function(NutritionFacts facts) read) {
      var total = 0.0;
      for (final food in foods) {
        final value = read(food.eaten);
        if (value == null) {
          return null;
        }
        total += value;
      }
      return total;
    }

    double? sumKnown(double? Function(NutritionFacts facts) read) {
      final values = foods.map((food) => read(food.eaten)).nonNulls;
      return values.isEmpty ? null : values.fold<double>(0, (a, b) => a + b);
    }

    NutritionFacts facts(
      double? Function(double? Function(NutritionFacts)) of,
    ) {
      return NutritionFacts(
        kcal: of((f) => f.kcal),
        fat: of((f) => f.fat),
        saturatedFat: of((f) => f.saturatedFat),
        polyunsaturatedFat: of((f) => f.polyunsaturatedFat),
        carbs: of((f) => f.carbs),
        sugar: of((f) => f.sugar),
        fiber: of((f) => f.fiber),
        protein: of((f) => f.protein),
        salt: of((f) => f.salt),
      );
    }

    // A food without an amount adds nothing to the meal's weight, and the
    // per-100 values need every food's weight.
    final amounts = <ConsumedUnit, double>{};
    for (final food in foods) {
      if (food.amount > 0) {
        amounts[food.unit] = (amounts[food.unit] ?? 0) + food.amount;
      }
    }
    final total = facts(sum);
    final hasAllAmounts = foods.every((food) => food.amount > 0);
    final amount = amounts.length == 1 && hasAllAmounts
        ? amounts.values.single
        : 0.0;
    return EatMealNutrition._(
      total: total,
      listed: facts(sumKnown),
      per100: amount > 0 ? total.scaled(100 / amount) : null,
      amounts: Map.unmodifiable(amounts),
    );
  }

  /// Nutrients of all foods, or null per nutrient when one food lacks it.
  final NutritionFacts total;

  /// Nutrients that at least one food lists, to show unknown totals.
  final NutritionFacts listed;

  /// Nutrients per 100 g or ml of the meal, or null with mixed units or an
  /// unknown amount.
  final NutritionFacts? per100;

  /// Eaten amount per unit.
  final Map<ConsumedUnit, double> amounts;
}

/// The meal food for eating [request] of [item], in the unit the request
/// counts calories in, or null when [item] has no nutrition values.
///
/// A request without its own calorie amount eats [item]'s stock unit, so
/// [item] must count in grams or milliliters then.
EatMealFood? eatMealFoodOfRequest(
  InventoryItem item,
  InventoryItemEatRequest request,
) {
  final nutrition = item.nutrition;
  final unit = request.calorieUnit ?? inventoryItemConsumedUnit(item);
  if (nutrition == null || unit == null) {
    return null;
  }
  final amount = request.calorieAmount ?? request.inventoryAmount.toDouble();
  return (
    eaten: EatNutrition.fromPer100(nutrition, amount).eaten,
    amount: amount,
    unit: unit,
  );
}

/// Amount a food starts with when it joins a meal: 100 g or ml, or less
/// when less is in stock. Null when [item] does not count in grams or
/// milliliters, so the amount has to be entered on the eat page.
///
/// A food found by search has no stock yet: [hasOpenStock] ignores the
/// stock limit.
int? defaultMealFoodAmount(InventoryItem item, {bool hasOpenStock = false}) {
  if (!inventoryItemUsesFixedCalorieUnit(item)) {
    return null;
  }
  return hasOpenStock
      ? _defaultMealAmount
      : math.min(_defaultMealAmount, mealFoodMaxAmount(item));
}

/// Largest amount of [item] that a meal can take.
int mealFoodMaxAmount(InventoryItem item, {bool hasOpenStock = false}) {
  if (hasOpenStock) {
    return math.max(item.initialAmount, _openStockMealMax);
  }
  return consumableInventoryAmount(item) ?? 0;
}

const _defaultMealAmount = 100;
const _openStockMealMax = 1000;
