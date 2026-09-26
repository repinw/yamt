import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';

final DateTime _now = DateTime.parse('2026-09-26T12:00:00Z');

InventoryItem _item(String id, {bool nutrition = true, int amount = 500}) {
  return InventoryItem.create(
    id: id,
    name: id,
    entryDate: _now,
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: amount,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: nutrition
        ? const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 200,
            per100Protein: 10,
            per100Carbs: 20,
            per100Fat: 5,
          )
        : null,
  );
}

InventoryItemEatRequest _request(int amount) {
  return InventoryItemEatRequest(
    inventoryAmount: amount,
    loggedAt: _now,
    mealType: MealType.lunch,
  );
}

InventoryItemCombineControllerProvider get _provider =>
    inventoryItemCombineControllerProvider('hub');

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(_provider, (_, _) {});
    addTearDown(subscription.close);
  });

  test('offers items with nutrition and stock, sorted by name', () {
    final candidates = container.read(_provider.notifier).candidatesFrom([
      _item('hub'),
      _item('rice'),
      _item('apple'),
      _item('salt', nutrition: false),
      _item('empty', amount: 0),
    ]);

    expect(candidates.map((item) => item.id), ['apple', 'rice']);
  });

  test('adds a food with its calories and hides it from the offer', () {
    final notifier = container.read(_provider.notifier)
      ..add(_item('rice'), _request(150));

    final pick = container.read(_provider).single;
    expect(pick.component.totalKcal, 300);
    expect(pick.component.amountLabel, '150 g');
    expect(
      notifier
          .candidatesFrom([_item('rice'), _item('apple')])
          .map((item) => item.id),
      ['apple'],
    );
  });

  test('removes a food', () {
    container.read(_provider.notifier)
      ..add(_item('rice'), _request(150))
      ..add(_item('apple'), _request(100))
      ..remove('rice');

    expect(container.read(_provider).map((pick) => pick.item.id), ['apple']);
  });
}
