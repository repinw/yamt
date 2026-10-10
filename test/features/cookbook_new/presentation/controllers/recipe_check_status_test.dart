import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_check_status.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import '../../../shoppinglist/support/fake_shopping_list_repository.dart';

final _now = DateTime.utc(2026, 10, 9);

final _recipe = PreparedMeal(
  id: 'stew',
  name: 'Bauerntopf',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: _now,
  updatedAt: _now,
  components: const <PreparedMealComponent>[],
  recipeIngredients: const ['600 g Karotten', '1 Zwiebel'],
);

ShoppingListItem _listed(String name) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
);

Future<RecipeCheckStatus> _status(List<ShoppingListItem> list) async {
  final repository = FakeShoppingListRepository(initialItems: list);
  final container = ProviderContainer(
    overrides: [
      cookbookTemplatesProvider.overrideWith((ref) => Stream.value([_recipe])),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value([
          InventoryItem.create(
            id: 'carrots',
            name: 'Karotten',
            entryDate: _now,
            storeName: 'Store',
            quantity: 1,
            initialAmount: 400,
            currentAmount: 400,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ]),
      ),
      shoppingListRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  final provider = recipeCheckStatusProvider('stew', 'de');
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  final status = container.read(provider);
  return status;
}

void main() {
  test('counts what is missing or partly there', () async {
    expect(await _status(const []), (missing: 1, partial: 1));
  });

  test('what is on the shopping list is sorted', () async {
    expect(await _status([_listed('200 g Karotten'), _listed('1 Zwiebel')]), (
      missing: 0,
      partial: 0,
    ));
  });
}
