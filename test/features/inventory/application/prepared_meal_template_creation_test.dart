import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation.dart';
import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/inventory_item_whole_list_writes.dart';

/// The creation part over [meals], for the template creation that the
/// cooking service uses.
PreparedMealCreation _creation(FakePreparedMealRepository meals) {
  return PreparedMealCreation(
    writer: PreparedMealWriter(
      meals: meals,
      clock: () => DateTime(2026, 4, 19),
      logName: 'test',
    ),
  );
}

class _FakeInventoryItemRepository with InventoryItemWholeListWrites {
  new({required List<InventoryItem> initialItems})
    : _items = List<InventoryItem>.from(initialItems);

  final StreamController<List<InventoryItem>> _controller =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items;
  bool readShouldThrow = false;
  bool saveShouldFail = false;
  int readAllCount = 0;
  List<InventoryItem> savedItems = const <InventoryItem>[];
  final List<List<InventoryItem>> saveHistory = <List<InventoryItem>>[];

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
      controller.add(List<InventoryItem>.from(_items));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    readAllCount += 1;
    if (readShouldThrow) {
      throw StateError('inventory-read-failed');
    }
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    if (saveShouldFail) {
      return false;
    }
    _items = List<InventoryItem>.from(items);
    savedItems = List<InventoryItem>.from(items);
    saveHistory.add(List<InventoryItem>.from(items));
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(_items)..addAll(items);
    _controller.add(List<InventoryItem>.from(_items));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

InventoryItem _item({
  required String id,
  required String name,
  int currentAmount = 300,
  int initialAmount = 300,
  int quantity = 1,
  int initialQuantity = 1,
  InventoryAmountUnit? amountUnit = InventoryAmountUnit.gram,
  GlobalFoodNutrition? nutrition = const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 200,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
  ),
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    nutrition: nutrition,
  );
}

void main() {
  test('createPreparedMealFromTemplate parses fractions and decimals '
      'and keeps unsupported units pending', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [
        _item(id: 'potatoes', name: 'Potatoes', currentAmount: 1000),
        _item(
          id: 'broth',
          name: 'Broth',
          currentAmount: 2000,
          amountUnit: InventoryAmountUnit.milliliter,
        ),
        _item(
          id: 'milk',
          name: 'Milk',
          currentAmount: 1000,
          amountUnit: InventoryAmountUnit.milliliter,
        ),
      ],
    );
    final preparedMealRepository = FakePreparedMealRepository();
    addTearDown(inventoryRepository.dispose);

    final template = PreparedMeal(
      id: 'template-1',
      name: 'Soup',
      recipeIngredients: const <String>[
        '1/2 kg Potatoes',
        '1,5 l Broth',
        '1 cup Milk',
      ],
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );
    final result = await _creation(preparedMealRepository)
        .createPreparedMealFromTemplate(
          inventoryRepository: inventoryRepository,
          ingredientParser: const TemplateIngredientParser(),
          template: template,
          totalPortions: 1,
          recipeIngredientAssignments: const <String, List<String>>{
            '1/2 kg Potatoes': <String>['potatoes'],
            '1,5 l Broth': <String>['broth'],
            '1 cup Milk': <String>['milk'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
        );

    expect(result.isSuccess, isTrue);
    expect(inventoryRepository.savedItems[0].currentAmount, 500);
    expect(inventoryRepository.savedItems[1].currentAmount, 500);
    expect(inventoryRepository.savedItems[2].currentAmount, 1000);
    expect(preparedMealRepository.meals, hasLength(1));
    expect(preparedMealRepository.meals.single.components, hasLength(2));
    expect(
      preparedMealRepository.meals.single.pendingRecipeIngredients,
      const <String>['1 cup Milk'],
    );
  });

  test('a template counted in pieces makes a meal in pieces', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [
        _item(id: 'potatoes', name: 'Potatoes', currentAmount: 1000),
      ],
    );
    final preparedMealRepository = FakePreparedMealRepository();
    addTearDown(inventoryRepository.dispose);
    final template = PreparedMeal(
      id: 'template-1',
      name: 'Wraps',
      recipeIngredients: const <String>['500 g Potatoes'],
      totalPortions: 6,
      remainingPortions: 6,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
      servedInPieces: true,
    );

    final result = await _creation(preparedMealRepository)
        .createPreparedMealFromTemplate(
          inventoryRepository: inventoryRepository,
          ingredientParser: const TemplateIngredientParser(),
          template: template,
          totalPortions: 6,
          recipeIngredientAssignments: const <String, List<String>>{
            '500 g Potatoes': <String>['potatoes'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
        );

    expect(result.isSuccess, isTrue);
    expect(preparedMealRepository.meals.single.isServedInPieces, isTrue);
  });

  test(
    'createPreparedMealFromTemplate uses piece-to-gram conversions safely',
    () async {
      final inventoryRepository = _FakeInventoryItemRepository(
        initialItems: [
          _item(
            id: 'carrots',
            name: 'Carrots',
            currentAmount: 2000,
            initialAmount: 2000,
          ),
        ],
      );
      final preparedMealRepository = FakePreparedMealRepository();
      addTearDown(inventoryRepository.dispose);

      final template = PreparedMeal(
        id: 'template-1',
        name: 'Carrot side',
        recipeIngredients: const <String>['2 Carrots'],
        totalPortions: 1,
        remainingPortions: 1,
        totalKcal: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
        updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
        components: const <PreparedMealComponent>[],
      );
      final result = await _creation(preparedMealRepository)
          .createPreparedMealFromTemplate(
            inventoryRepository: inventoryRepository,
            ingredientParser: const TemplateIngredientParser(),
            template: template,
            totalPortions: 1,
            recipeIngredientAssignments: const <String, List<String>>{
              '2 Carrots': <String>['carrots'],
            },
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{
                  '2 Carrots': RecipeIngredientAmountConversion(
                    amountPerPiece: 100,
                    unit: InventoryAmountUnit.gram,
                  ),
                },
          );

      expect(result.isSuccess, isTrue);
      expect(inventoryRepository.savedItems.single.currentAmount, 1800);
      expect(preparedMealRepository.meals.single.components, hasLength(1));
      expect(
        preparedMealRepository.meals.single.components.single.usedAmount,
        200,
      );
      expect(
        preparedMealRepository.meals.single.components.single.usedUnit,
        InventoryAmountUnit.gram,
      );
      expect(
        preparedMealRepository.meals.single.pendingRecipeIngredients,
        isEmpty,
      );
    },
  );

  test('createPreparedMealFromTemplate does not consume measured items '
      'without piece conversion', () async {
    final inventoryRepository = _FakeInventoryItemRepository(
      initialItems: [
        _item(
          id: 'carrots',
          name: 'Carrots',
          currentAmount: 2000,
          initialAmount: 2000,
        ),
      ],
    );
    final preparedMealRepository = FakePreparedMealRepository();
    addTearDown(inventoryRepository.dispose);

    final template = PreparedMeal(
      id: 'template-1',
      name: 'Carrot side',
      recipeIngredients: const <String>['2 Carrots'],
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
      components: const <PreparedMealComponent>[],
    );
    final result = await _creation(preparedMealRepository)
        .createPreparedMealFromTemplate(
          inventoryRepository: inventoryRepository,
          ingredientParser: const TemplateIngredientParser(),
          template: template,
          totalPortions: 1,
          recipeIngredientAssignments: const <String, List<String>>{
            '2 Carrots': <String>['carrots'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
        );

    expect(result.isSuccess, isTrue);
    expect(inventoryRepository.savedItems, isEmpty);
    expect((await inventoryRepository.readAll()).single.currentAmount, 2000);
    expect(preparedMealRepository.meals.single.components, isEmpty);
    expect(
      preparedMealRepository.meals.single.pendingRecipeIngredients,
      const <String>['2 pc Carrots'],
    );
  });
}
