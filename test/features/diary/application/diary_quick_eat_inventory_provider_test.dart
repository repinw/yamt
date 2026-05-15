import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/diary/application/diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';

@Dependencies([diaryQuickEatInventory])
void main() {
  test(
    'filters selectable inventory items and depleted prepared meals',
    () async {
      final availableItem = _item(id: 'normal-available', quantity: 2);
      final emptyItem = _item(id: 'normal-empty', quantity: 0);
      final amountItem = _item(
        id: 'amount-available',
        quantity: 1,
        initialAmount: 500,
        currentAmount: 125,
        amountUnit: InventoryAmountUnit.gram,
      );
      final depletedAmountItem = _item(
        id: 'amount-empty',
        quantity: 1,
        initialAmount: 500,
        amountUnit: InventoryAmountUnit.gram,
      );
      final readyMeal = _meal(id: 'ready-meal', remainingPortions: 1);
      final depletedMeal = _meal(id: 'depleted-meal', remainingPortions: 0);
      final container = ProviderContainer(
        overrides: [
          inventoryItemsControllerProvider.overrideWith(
            () => _StaticInventoryItemsController([
              availableItem,
              emptyItem,
              amountItem,
              depletedAmountItem,
            ]),
          ),
          preparedMealsControllerProvider.overrideWith(
            () => _StaticPreparedMealsController([readyMeal, depletedMeal]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(diaryQuickEatInventoryProvider.future);

      expect(data.items.map((item) => item.id), [
        'normal-available',
        'amount-available',
      ]);
      expect(data.meals.map((meal) => meal.id), ['ready-meal']);
    },
  );

  test('resolves max amount for quantity and amount-progress items', () {
    final quantityItem = _item(id: 'quantity', quantity: 3);
    final emptyQuantityItem = _item(id: 'empty-quantity', quantity: 0);
    final amountItem = _item(
      id: 'amount',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 125,
      amountUnit: InventoryAmountUnit.gram,
    );
    final emptyAmountItem = _item(
      id: 'empty-amount',
      quantity: 4,
      initialAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final amountLikeQuantityItem = _item(
      id: 'amount-like-quantity',
      quantity: 2,
      initialAmount: 500,
      currentAmount: 125,
    );

    expect(maxDiaryQuickEatInventoryAmount(quantityItem), 3);
    expect(canDiaryQuickEatInventoryItem(quantityItem), isTrue);
    expect(maxDiaryQuickEatInventoryAmount(emptyQuantityItem), isNull);
    expect(canDiaryQuickEatInventoryItem(emptyQuantityItem), isFalse);
    expect(maxDiaryQuickEatInventoryAmount(amountItem), 125);
    expect(canDiaryQuickEatInventoryItem(amountItem), isTrue);
    expect(maxDiaryQuickEatInventoryAmount(emptyAmountItem), isNull);
    expect(canDiaryQuickEatInventoryItem(emptyAmountItem), isFalse);
    expect(maxDiaryQuickEatInventoryAmount(amountLikeQuantityItem), 2);
    expect(canDiaryQuickEatInventoryItem(amountLikeQuantityItem), isTrue);
  });
}

InventoryItem _item({
  required String id,
  required int quantity,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: id,
    name: id,
    entryDate: DateTime(2026, 4, 27),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
  );
}

PreparedMeal _meal({required String id, required num remainingPortions}) {
  return PreparedMeal(
    id: id,
    name: id,
    totalPortions: 2,
    remainingPortions: remainingPortions,
    totalKcal: 600,
    totalProtein: 30,
    totalCarbs: 60,
    totalFat: 20,
    createdAt: DateTime(2026, 4, 27),
    updatedAt: DateTime(2026, 4, 27),
    components: const <PreparedMealComponent>[],
  );
}

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this.items);

  final List<InventoryItem> items;

  @override
  Future<List<InventoryItem>> build() async => items;
}

class _StaticPreparedMealsController extends PreparedMealsController {
  _StaticPreparedMealsController(this.meals);

  final List<PreparedMeal> meals;

  @override
  Future<List<PreparedMeal>> build() async => meals;
}
