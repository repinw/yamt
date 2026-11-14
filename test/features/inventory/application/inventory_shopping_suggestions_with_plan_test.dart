import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_suggestion.dart';

const _milk = ShoppingSuggestion(name: 'Milch', purchaseCount: 3);

final ShoppingPlanNeedGroup _eggs = (
  day: DateTime(2026, 11, 16),
  mealType: MealType.breakfast,
  needs: [
    ShoppingPlanNeed(
      name: 'Eier',
      day: DateTime(2026, 11, 16),
      mealType: MealType.breakfast,
      amount: null,
      inMilliliters: false,
      isPartial: false,
    ),
  ],
);

ProviderContainer _container(
  Future<List<ShoppingPlanNeedGroup>> Function() plans,
) {
  final container = ProviderContainer(
    overrides: [
      inventoryShoppingSuggestionsProvider.overrideWithValue(
        const AsyncData([_milk]),
      ),
      inventoryShoppingPlanNeedGroupsProvider.overrideWith((_) => plans()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('what the plans need comes before the stock suggestions', () async {
    final container = _container(() async => [_eggs])
      ..listen(inventoryShoppingSuggestionsWithPlanProvider, (_, _) {});
    await container.read(inventoryShoppingPlanNeedGroupsProvider.future);

    final names = container
        .read(inventoryShoppingSuggestionsWithPlanProvider)
        .requireValue
        .map((suggestion) => suggestion.name);
    expect(names, ['Eier', 'Milch']);
  });

  test('while the plans load, the stock suggestions show alone', () {
    final plans = Completer<List<ShoppingPlanNeedGroup>>();
    final container = _container(() => plans.future);

    final names = container
        .read(inventoryShoppingSuggestionsWithPlanProvider)
        .requireValue
        .map((suggestion) => suggestion.name);
    expect(names, ['Milch']);
  });

  test('a failure of the plans fails the whole list', () async {
    final container = _container(() async => throw StateError('offline'))
      ..listen(inventoryShoppingSuggestionsWithPlanProvider, (_, _) {});
    await expectLater(
      container.read(inventoryShoppingPlanNeedGroupsProvider.future),
      throwsStateError,
    );

    expect(
      container.read(inventoryShoppingSuggestionsWithPlanProvider),
      isA<AsyncError<List<ShoppingSuggestion>>>(),
    );
  });
}
