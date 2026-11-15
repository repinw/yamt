import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';

/// The food the cook names for a recipe line in the food pick.
sealed class RecipeFoodPick {
  const new();
}

/// A food that is not in the Vorrat yet, with the amount that goes in: one
/// full pack, the amount the cook typed, or exactly what the line needs for a
/// food the app estimated (`InventoryItem.aiEstimated`).
final class RecipeFoodNew extends RecipeFoodPick {
  /// Creates the pick of [food].
  const new(this.food);

  /// The food with its amount.
  final InventoryMealFoodPick food;
}

/// Foods that are in the Vorrat already, in the order the line takes them:
/// nothing new goes in.
final class RecipeFoodInStock extends RecipeFoodPick {
  /// Creates the pick of [items].
  const new(this.items);

  /// The Vorrat items, at least one.
  final List<InventoryItem> items;
}
