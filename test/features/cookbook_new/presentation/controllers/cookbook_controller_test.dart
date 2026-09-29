import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../../support/prepared_meal_test_data.dart';

InventoryItem _item(String name) {
  return InventoryItem.create(
    id: name,
    name: name,
    entryDate: DateTime.utc(2026, 9, 29),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
  );
}

ProviderContainer _container({
  required List<PreparedMeal> templates,
  required List<PreparedMeal> meals,
  required List<InventoryItem> items,
}) {
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value(templates)),
      inventoryQuickEatMealsProvider.overrideWith((ref) => Stream.value(meals)),
      inventoryQuickEatItemsProvider.overrideWith((ref) => Stream.value(items)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<CookbookOverview> _overview(ProviderContainer container) async {
  final provider = cookbookControllerProvider('en');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  while (!container.read(provider).hasValue &&
      !container.read(provider).hasError) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(provider).requireValue;
}

void main() {
  test('marks recipe ingredients that the Vorrat holds', () async {
    final recipe = preparedMealTestData(
      id: 'pasta',
    ).copyWith(recipeIngredients: const ['200 g Pasta', '150 g Tomato sauce']);
    final container = _container(
      templates: [recipe],
      meals: const [],
      items: [_item('Pasta')],
    );

    final overview = await _overview(container);

    expect(overview.recipes.single.inStock, [true, false]);
  });

  test('shows meals with open rows in the pot', () async {
    final meal = preparedMealTestData(id: 'free')
        .copyWith(pendingRecipeIngredients: const ['500 g Chicken']);
    final container = _container(
      templates: const [],
      meals: [meal],
      items: const [],
    );

    final overview = await _overview(container);

    expect(overview.openMeals.single.id, 'free');
    expect(overview.recipes, isEmpty);
  });
}
