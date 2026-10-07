import 'package:yamt/core/domain/meal_type.dart';

/// Amount and log time chosen on the eat page so far.
typedef InventoryItemEatSelection = ({
  int? inventoryAmount,
  DateTime loggedAt,
  MealType mealType,
});
