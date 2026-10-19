import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';

InventoryMealFoodPick _catalogFood(String name, {bool nutrition = true}) => (
  result: InventoryReceiptManualProductResult(
    item: InventoryItem.create(
      id: 'draft-$name',
      name: name,
      nutrition: nutrition
          ? const GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 250,
              per100Protein: 8,
              per100Carbs: 48,
              per100Fat: 2,
            )
          : null,
      entryDate: DateTime(2026, 10, 15),
      storeName: 'Store',
      quantity: 1,
      weight: '500g',
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    ),
    action: InventoryReceiptManualProductAction.eatNow,
    requiresGlobalPersistence: false,
  ),
  request: InventoryItemEatRequest(
    inventoryAmount: 100,
    loggedAt: DateTime(2026, 10, 15, 12),
    mealType: MealType.lunch,
  ),
);

void main() {
  test('selection controller enters, toggles and clears selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(preparedMealSelectionControllerProvider.notifier)
          ..enterSelection('item-1')
          ..toggleSelection('item-2');
    expect(
      container.read(preparedMealSelectionControllerProvider).selectedItemIds,
      {'item-1', 'item-2'},
    );

    controller.toggleSelection('item-1');
    expect(
      container.read(preparedMealSelectionControllerProvider).selectedItemIds,
      {'item-2'},
    );

    controller.clearSelection();
    expect(
      container.read(preparedMealSelectionControllerProvider).isSelectionMode,
      isFalse,
    );
  });

  test('a selection started from an eat page keeps its anchor and catalog '
      'foods until it ends', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    PreparedMealSelectionState read() =>
        container.read(preparedMealSelectionControllerProvider);
    final bread = _catalogFood('Bread');
    final salad = _catalogFood('Salad');

    final controller = container.read(
      preparedMealSelectionControllerProvider.notifier,
    )..startFrom(anchorItemId: 'item-1', itemIds: {'item-1'});
    expect(read().anchorItemId, 'item-1');
    expect(read().canConfirm, isFalse);

    // A food without nutrition values cannot be added up into the meal.
    expect(
      controller.addCatalogFood(_catalogFood('Salt', nutrition: false)),
      isFalse,
    );
    expect(read().catalogFoods, isEmpty);

    expect(controller.addCatalogFood(bread), isTrue);
    expect(read().selectedCount, 2);
    expect(read().canConfirm, isTrue);

    // Catalog foods alone make no meal: one food must come from the stock.
    controller.toggleSelection('item-1');
    expect(read().isSelectionMode, isTrue);
    expect(read().canConfirm, isFalse);
    expect(read().anchorItemId, 'item-1');

    final rice = _catalogFood('Rice');
    controller
      ..addCatalogFood(salad)
      ..addCatalogFood(rice)
      // A double tap on the remove button of the row at index 1 removes its
      // food once and leaves the food that moves up into that index.
      ..removeCatalogFoodAt(1, salad)
      ..removeCatalogFoodAt(1, salad);
    expect(read().catalogFoods, [bread, rice]);

    controller.clearSelection();
    expect(read().isSelectionMode, isFalse);
    expect(read().anchorItemId, isNull);
    expect(read().catalogFoods, isEmpty);
  });

  test('restore brings back a cleared selection (#728)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      preparedMealSelectionControllerProvider.notifier,
    )..startFrom(anchorItemId: 'a', itemIds: {'a', 'b'});
    final selection = container.read(preparedMealSelectionControllerProvider);

    controller
      ..clearSelection()
      ..restore(selection);

    expect(container.read(preparedMealSelectionControllerProvider), selection);
  });
}
