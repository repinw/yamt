import 'dart:math' show max, min;

import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

/// One food of a Vorlage to cook: `amount` of `name` in display units of
/// `unit` (pieces may be fractional), taken from the Vorrat items `itemIds`
/// in order.
typedef VorlageFood = ({
  String name,
  InventoryAmountUnit unit,
  double amount,
  List<String> itemIds,
});

/// The meal of the Vorlage [vorlage] cooked for [totalPortions] from
/// [foods], with their amounts as given. What the items cannot supply stays
/// an open row of the meal.
PreparedMealBuildResult buildPreparedMealFromVorlage({
  required List<InventoryItem> currentItems,
  required String preparedMealId,
  required DateTime now,
  required PreparedMeal vorlage,
  required int totalPortions,
  required List<VorlageFood> foods,
}) {
  if (foods.isEmpty) {
    throw const PreparedMealBuildException(
      PreparedMealCreationFailureReason.invalidInput,
    );
  }
  final nextItems = List<InventoryItem>.from(currentItems);
  final components = <PreparedMealComponent>[];
  final pending = <String>[];
  for (final food in foods) {
    final isPiece = food.unit == InventoryAmountUnit.piece;
    // Grams and milliliters count whole; parts of a piece stay.
    var rest = isPiece ? food.amount : food.amount.roundToDouble();
    // Less than a hundredth of a piece is rounding, not a missing amount.
    final done = isPiece ? 0.01 : 1;
    for (final itemId in food.itemIds) {
      final index = nextItems.indexWhere((item) => item.id == itemId);
      if (rest < done || index < 0) {
        continue;
      }
      final item = nextItems[index];
      final take = _take(item, food.unit, rest);
      if (take == null) {
        continue;
      }
      final next = item.reducedBy(take.amount);
      if (next == null) {
        continue;
      }
      nextItems[index] = next;
      components.add(
        buildPreparedMealComponent(
          item: item,
          usedAmount: take.amount,
          usedUnit: resolveTemplateUsedUnit(
            item: item,
            requiredUnit: food.unit,
          ),
          nutrition:
              item.nutrition ??
              const GlobalFoodNutrition(
                qualityStatus: GlobalFoodNutritionQualityStatus.missing,
              ),
        ).copyWith(
          pendingRecipeIngredient: _row(
            min(take.covered, rest),
            food.unit,
            food.name,
          ),
        ),
      );
      rest -= take.covered;
    }
    if (rest >= done) {
      pending.add(_row(rest, food.unit, food.name));
    }
  }

  final totals = components.nutritionTotals;
  return PreparedMealBuildResult(
    nextItems: nextItems,
    preparedMeal: PreparedMeal(
      id: preparedMealId,
      name: vorlage.name,
      imageAssetId: normalizeOptionalImageAssetId(vorlage.imageAssetId),
      imageUrl: vorlage.imageUrl,
      // The foods as rows, so the meal reads like one cooked from a recipe.
      recipeIngredients: [
        for (final food in foods) _row(food.amount, food.unit, food.name),
      ],
      recipeIngredientAssignments: {
        for (final food in foods)
          if (food.itemIds.isNotEmpty)
            _row(food.amount, food.unit, food.name): food.itemIds,
      },
      pendingRecipeIngredients: pending,
      totalPortions: totalPortions,
      remainingPortions: totalPortions,
      servedInPieces: vorlage.servedInPieces,
      totalKcal: totals.totalKcal,
      totalProtein: totals.totalProtein,
      totalCarbs: totals.totalCarbs,
      totalFat: totals.totalFat,
      createdAt: now,
      updatedAt: now,
      components: components,
    ),
  );
}

/// How much of [item] supplies [rest] of a food in [unit], in the item's
/// stored amount, and how much of [rest] that covers; `null` when the item
/// cannot supply it. A pack counted by weight is one piece, and an item
/// that counts whole pieces gives whole pieces.
({int amount, double covered})? _take(
  InventoryItem item,
  InventoryAmountUnit unit,
  double rest,
) {
  final available = item.availableAmount;
  if (available < 1) {
    return null;
  }
  if (unit != InventoryAmountUnit.piece) {
    if (!item.usesAmountProgress || item.amountUnit != unit) {
      return null;
    }
    final amount = min(rest.round(), available);
    return (amount: amount, covered: amount.toDouble());
  }
  if (!item.usesAmountProgress) {
    // The whole pieces stand for all of the rest; only a lack leaves some.
    final wanted = max(1, rest.round());
    final amount = min(wanted, available);
    return (
      amount: amount,
      covered: amount == wanted ? rest : amount.toDouble(),
    );
  }
  if (item.amountUnit != InventoryAmountUnit.piece) {
    return (amount: available, covered: 1);
  }
  final scale = item.amountScale < 1 ? 1 : item.amountScale;
  final amount = min((rest * scale).round(), available);
  return (amount: amount, covered: amount / scale);
}

/// The row of [amount] of [name], with pieces whole and at least one: open
/// rows are filled through the ingredient parser, which counts whole pieces.
String _row(double amount, InventoryAmountUnit unit, String name) =>
    preparedMealFoodRow(
      unit == InventoryAmountUnit.piece
          ? max(1, amount.round()).toDouble()
          : amount,
      unit,
      name,
    );
