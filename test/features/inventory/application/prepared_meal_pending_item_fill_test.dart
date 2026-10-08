import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_pending_item_fill.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_writer.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime.utc(2026, 10, 1, 19);

void main() {
  test('uses the chosen amount for a row without an amount', () async {
    final harness = _Harness(saves: true);
    final items = _FakeInventoryRepository([_salt()]);

    final filled = await harness.fill.fill(
      mealId: 'pan',
      ingredient: 'Salz',
      itemId: 'salt',
      usedAmount: 5,
      inventoryRepository: items,
    );

    expect(filled, isTrue);
    final meal = harness.stored.single;
    expect(meal.pendingRecipeIngredients, ['200 g Reis']);
    expect(meal.components.single.usedAmount, 5);
    expect(meal.totalKcal, 0);
    expect(meal.updatedAt, _now);
    expect(items.items.single.currentAmount, 495);
  });

  test('restores the Vorrat when the meal cannot be saved', () async {
    final harness = _Harness(saves: false);
    final items = _FakeInventoryRepository([_salt()]);

    final filled = await harness.fill.fill(
      mealId: 'pan',
      ingredient: 'Salz',
      itemId: 'salt',
      usedAmount: 5,
      inventoryRepository: items,
    );

    expect(filled, isFalse);
    expect(items.items.single.currentAmount, 500);
    expect(harness.stored.single.pendingRecipeIngredients, hasLength(2));
  });

  test('fails for a row that is not open', () async {
    final harness = _Harness(saves: true);

    final filled = await harness.fill.fill(
      mealId: 'pan',
      ingredient: 'Pfeffer',
      itemId: 'salt',
      usedAmount: 5,
      inventoryRepository: _FakeInventoryRepository([_salt()]),
    );

    expect(filled, isFalse);
  });
}

InventoryItem _salt() {
  return InventoryItem.create(
    id: 'salt',
    name: 'Salz',
    entryDate: DateTime.utc(2026, 9),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 0,
      per100Protein: 0,
      per100Carbs: 0,
      per100Fat: 0,
    ),
  );
}

class _Harness {
  new({required this.saves});

  final bool saves;
  List<PreparedMeal> meals = [
    PreparedMeal(
      id: 'pan',
      name: 'Reispfanne',
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.utc(2026, 10),
      updatedAt: DateTime.utc(2026, 10),
      components: const [],
      pendingRecipeIngredients: const ['200 g Reis', 'Salz'],
    ),
  ];

  late final _repository = FakePreparedMealRepository(
    meals: meals,
    writeResults: [saves],
  );

  PreparedMealPendingItemFill get fill {
    return PreparedMealPendingItemFill(
      writer: PreparedMealWriter(
        meals: _repository,
        clock: () => _now,
        logName: 'test',
        newId: () => 'id',
      ),
    );
  }

  /// The stored meals after the fill.
  List<PreparedMeal> get stored => _repository.meals;
}

class _FakeInventoryRepository with InventoryItemWholeListWrites {
  new(this.items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(items);

  @override
  Future<List<InventoryItem>> readAll() async => items;

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    this.items = items;
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    this.items = [...this.items, ...items];
    return true;
  }
}
