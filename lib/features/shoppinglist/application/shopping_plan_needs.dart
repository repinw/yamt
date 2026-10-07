import 'package:collection/collection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

/// [needs] grouped by day and meal, days in order and meals in diary order,
/// without the foods that [listed] already holds. Within a group the needs
/// keep their order.
List<ShoppingPlanNeedGroup> groupShoppingPlanNeeds(
  List<ShoppingPlanNeed> needs,
  Set<ShoppingListItemMatchKey> listed,
) {
  final open = needs.where(
    (need) => !isSourceItemInActiveShoppingList(
      item: (
        name: need.name,
        brand: need.brand,
        initialQuantity: 1,
        unitPrice: 0,
      ),
      activeItemKeys: listed,
    ),
  );
  final byMeal = groupBy(
    open,
    (need) => (day: dateOnly(need.day), mealType: need.mealType),
  );
  final keys = byMeal.keys.sorted(
    (a, b) => a.day != b.day
        ? a.day.compareTo(b.day)
        : MealType.sectionOrder
              .indexOf(a.mealType)
              .compareTo(MealType.sectionOrder.indexOf(b.mealType)),
  );
  return [
    for (final key in keys)
      (
        day: key.day,
        mealType: key.mealType,
        needs: List.unmodifiable(byMeal[key]!),
      ),
  ];
}
