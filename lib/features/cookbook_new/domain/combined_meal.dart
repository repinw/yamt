import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// What the "Gekocht" step needs to know about a meal combined from Vorrat
/// foods instead of cooked from rows.
extension CombinedMeal on PreparedMeal {
  /// Whether the meal was combined from Vorrat foods and waits for its
  /// "Gekocht" step. Free cooking always keeps its rows; a combined meal has
  /// none. Once cooked, on this or another device, it is a plain meal.
  bool get isCombined => isInPot && recipeIngredients.isEmpty;

  /// Grams of the meal's ingredients, or `null` when one is not counted in
  /// grams. Nothing evaporates from a combined meal, so they are its weight.
  int? get ingredientsGrams =>
      components.every(
        (component) => component.usedUnit == InventoryAmountUnit.gram,
      )
      ? perHundredAmountBasis
      : null;
}
