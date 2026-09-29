import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'cookbook_controller.g.dart';

/// Watches the saved Vorlagen and recipes of the household.
@riverpod
Stream<List<PreparedMeal>> cookbookTemplates(Ref ref) {
  return ref.watch(preparedMealTemplateRepositoryProvider).watchAll();
}

/// Holds the Kochbuch overview and rebuilds it when templates, meals, or the
/// Vorrat change.
@riverpod
class CookbookController extends _$CookbookController {
  @override
  Future<CookbookOverview> build(String localeCode) async {
    final templates = await ref.watch(cookbookTemplatesProvider.future);
    final meals = await ref.watch(inventoryQuickEatMealsProvider.future);
    final items = await ref.watch(inventoryQuickEatItemsProvider.future);
    return CookbookOverview.fromMeals(
      savedTemplates: templates,
      meals: meals,
      isInStock: (food) => matchInventoryItemsForIngredient(
        ingredient: food,
        inventoryItems: items,
        localeCode: localeCode,
      ).isNotEmpty,
    );
  }

  /// Loads the templates, meals, and Vorrat again after a failure.
  void retry() {
    ref
      ..invalidate(cookbookTemplatesProvider)
      ..invalidate(inventoryQuickEatMealsProvider)
      ..invalidate(inventoryQuickEatItemsProvider);
  }
}
