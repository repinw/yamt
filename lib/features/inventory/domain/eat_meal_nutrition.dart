import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

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
    required this.incomplete,
    required this.per100,
    required this.amounts,
  });

  /// Adds up [foods].
  ///
  /// Energy and the three macros are unknown when one food does not list
  /// them, since a Vorrat meal needs them from every food. Any other
  /// nutrient adds up the foods that list it, and [incomplete] notes that a
  /// food lacks it. The per-100 values exist only when all foods share one
  /// unit, since grams and milliliters do not add up.
  factory combine(List<EatMealFood> foods) {
    NutritionFacts facts(double? Function(Nutrient nutrient) valueOf) {
      return NutritionFacts(
        kcal: valueOf(Nutrient.kcal),
        fat: valueOf(Nutrient.fat),
        saturatedFat: valueOf(Nutrient.saturatedFat),
        polyunsaturatedFat: valueOf(Nutrient.polyunsaturatedFat),
        carbs: valueOf(Nutrient.carbs),
        sugar: valueOf(Nutrient.sugar),
        fiber: valueOf(Nutrient.fiber),
        protein: valueOf(Nutrient.protein),
        salt: valueOf(Nutrient.salt),
      );
    }

    bool someFoodLacks(Nutrient nutrient) =>
        foods.any((food) => nutrient.of(food.eaten) == null);

    final listed = facts((nutrient) {
      final values = foods.map((food) => nutrient.of(food.eaten)).nonNulls;
      return values.isEmpty ? null : values.fold<double>(0, (a, b) => a + b);
    });
    final total = facts(
      (nutrient) =>
          _requiredNutrients.contains(nutrient) && someFoodLacks(nutrient)
          ? null
          // A meal without foods holds nothing, not unknown values.
          : nutrient.of(listed) ?? (foods.isEmpty ? 0 : null),
    );

    // A food without an amount adds nothing to the meal's weight, and the
    // per-100 values need every food's weight.
    final amounts = <ConsumedUnit, double>{};
    for (final food in foods) {
      if (food.amount > 0) {
        amounts[food.unit] = (amounts[food.unit] ?? 0) + food.amount;
      }
    }
    final hasAllAmounts = foods.every((food) => food.amount > 0);
    final amount = amounts.length == 1 && hasAllAmounts
        ? amounts.values.single
        : 0.0;
    return EatMealNutrition._(
      total: total,
      listed: listed,
      incomplete: Set.unmodifiable({
        for (final nutrient in Nutrient.values)
          if (nutrient.of(total) != null && someFoodLacks(nutrient)) nutrient,
      }),
      per100: amount > 0 ? total.scaled(100 / amount) : null,
      amounts: Map.unmodifiable(amounts),
    );
  }

  /// Nutrients of [share] of the Vorrat [meal], 1 being the whole meal.
  ///
  /// Energy and the macros are the meal's own totals, which eating it logs;
  /// a meal without ingredients, such as one from the AI chef, has only
  /// these. The other nutrients add up the ingredients as
  /// [EatMealNutrition.combine] does, as a minimum when an ingredient lacks
  /// them. The per-100 values are the food left
  /// per 100 g of its weight, so they are known only once the cooked meal
  /// was weighed: cooking changes the weight, and the raw ingredients'
  /// weights would give wrong values. There are no amounts.
  factory ofPreparedMeal(PreparedMeal meal, double share) {
    // The ingredients' weights do not matter here, so none is given.
    final ingredients = meal.components.isEmpty
        ? null
        : EatMealNutrition.combine([
            for (final component in meal.components)
              (
                eaten: component.nutritionFacts,
                amount: 0,
                unit: ConsumedUnit.grams,
              ),
          ]);

    NutritionFacts withMealTotals(NutritionFacts? facts) {
      return NutritionFacts(
        kcal: meal.totalKcal,
        fat: meal.totalFat,
        saturatedFat: facts?.saturatedFat,
        polyunsaturatedFat: facts?.polyunsaturatedFat,
        carbs: meal.totalCarbs,
        sugar: facts?.sugar,
        fiber: facts?.fiber,
        protein: meal.totalProtein,
        salt: facts?.salt,
      );
    }

    final whole = withMealTotals(ingredients?.total);
    final grams = meal.remainingNetWeight;
    return EatMealNutrition._(
      total: whole.scaled(share),
      listed: withMealTotals(ingredients?.listed).scaled(share),
      // Energy and the macros are the meal's own totals, never a minimum.
      incomplete: Set.unmodifiable({
        ...?ingredients?.incomplete.difference(_requiredNutrients),
      }),
      per100: grams == null || grams <= 0 || meal.totalPortions < 1
          ? null
          : whole.scaled(meal.remainingRatio * 100 / grams),
      amounts: const {},
    );
  }

  /// The meal split into [portions]: nutrients and amounts per portion.
  /// The per-100 values do not change.
  EatMealNutrition perPortion(int portions) {
    if (portions < 2) {
      return this;
    }
    final share = 1 / portions;
    return EatMealNutrition._(
      total: total.scaled(share),
      listed: listed.scaled(share),
      incomplete: incomplete,
      per100: per100,
      amounts: Map.unmodifiable({
        for (final MapEntry(key: unit, value: amount) in amounts.entries)
          unit: amount * share,
      }),
    );
  }

  /// Nutrients of all foods. Energy and the macros are null when one food
  /// lacks them, any other nutrient only when no food lists it.
  final NutritionFacts total;

  /// Nutrients that at least one food lists, to show unknown totals.
  final NutritionFacts listed;

  /// Nutrients whose [total] and [per100] leave out foods that do not list
  /// them. The meal holds at least that much.
  final Set<Nutrient> incomplete;

  /// Nutrients per 100 g or ml of the meal, or null with mixed units or an
  /// unknown amount.
  final NutritionFacts? per100;

  /// Eaten amount per unit.
  final Map<ConsumedUnit, double> amounts;
}

/// The meal food for eating [request] of [item], in the unit the request
/// counts calories in, or null when that unit is unknown. An [item] without
/// nutrition values lists none, so the meal's totals show it lacks them.
///
/// A request without its own calorie amount eats [item]'s stock unit, so
/// [item] must count in grams or milliliters then.
EatMealFood? eatMealFoodOfRequest(
  InventoryItem item,
  InventoryItemEatRequest request,
) {
  final nutrition = item.nutrition;
  final unit = request.calorieUnit ?? inventoryItemConsumedUnit(item);
  if (unit == null) {
    return null;
  }
  final amount = request.calorieAmount ?? request.inventoryAmount.toDouble();
  return (
    eaten: nutrition == null
        ? const NutritionFacts()
        : EatNutrition.fromPer100(nutrition, amount).eaten,
    amount: amount,
    unit: unit,
  );
}

/// Amount a stock item starts with when it joins a meal: 100 g or ml, or
/// less when less is in stock. Null when [item] does not count in grams or
/// milliliters.
int? defaultMealFoodAmount(InventoryItem item) {
  if (!inventoryItemUsesFixedCalorieUnit(item)) {
    return null;
  }
  return math.min(_defaultMealAmount, mealFoodMaxAmount(item));
}

/// Largest amount of [item] that a meal can take.
int mealFoodMaxAmount(InventoryItem item, {bool hasOpenStock = false}) {
  if (hasOpenStock) {
    return math.max(item.initialAmount, _openStockMealMax);
  }
  return consumableInventoryAmount(item) ?? 0;
}

/// Amount of [item] typed as [text] for a meal, read as the eat page reads
/// it: grams and milliliters may have a decimal, and the stock takes them
/// rounded to whole units. Null when [text] is no amount or more than
/// [mealFoodMaxAmount].
int? typedMealFoodAmount(
  InventoryItem item,
  String text, {
  bool hasOpenStock = false,
}) {
  final max = mealFoodMaxAmount(item, hasOpenStock: hasOpenStock);
  final calculator = InventoryItemEatCalculator(item: item, maxAmount: max);
  final amount = calculator.parseInventoryAmount(text);
  // 37,4 g rounds to the last 37 g but would log more than is there.
  if (amount == null ||
      amount > max ||
      (calculator.parseEatenAmount(text) ?? 0) > max) {
    return null;
  }
  return amount;
}

const _defaultMealAmount = 100;
const _openStockMealMax = 1000;

/// Energy and the macros, which a Vorrat meal needs from every food.
const _requiredNutrients = <Nutrient>{
  Nutrient.kcal,
  Nutrient.fat,
  Nutrient.carbs,
  Nutrient.protein,
};
