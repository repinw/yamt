import 'dart:developer' show log;

import 'package:yamt/features/inventory/application/prepared_meal_from_items.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_inventory_math.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// The Vorrat foods that can go into a new cookbook template, by name: they
/// have stock to count and a full label, since a template adds up its
/// ingredients' labels (#428).
List<InventoryItem> inventoryTemplateCandidates(List<InventoryItem> items) => [
  for (final item in items)
    if (defaultMealFoodAmount(item) != null &&
        mealFoodMaxAmount(item) >= 1 &&
        hasCompleteNutrition(item.nutrition))
      item,
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

/// A one-portion meal named [name] of [items] with all of their stock, to
/// save as a cookbook template, or null when one of them cannot be counted.
/// It is only built, so the Vorrat keeps the stock.
PreparedMeal? preparedMealTemplateFromItems(
  List<InventoryItem> items, {
  required String name,
  required DateTime now,
}) {
  try {
    return buildPreparedMealCreationResult(
      currentItems: items,
      preparedMealId: '',
      now: now,
      name: name,
      imageAssetId: null,
      totalPortions: 1,
      inputs: [
        for (final item in items)
          PreparedMealItemInput(
            itemId: item.id,
            usedAmount: mealFoodMaxAmount(item),
          ),
      ],
    ).preparedMeal;
  } on PreparedMealBuildException catch (error) {
    // A picked food whose stock cannot be counted into a meal.
    log('The template was not built: ${error.reason}.');
    return null;
  }
}
