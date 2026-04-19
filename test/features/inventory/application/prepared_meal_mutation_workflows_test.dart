import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  const ingredientParser = TemplateIngredientParser();

  group('prepared meal mutation workflows', () {
    test('createPreparedMeal saves inventory and meal on success', () async {
      final harness = _WorkflowHarness();
      final inventoryRepository = _FakeInventoryItemRepository(
        items: <InventoryItem>[
          _measuredItem(
            id: 'rice',
            name: 'Rice',
            currentAmount: 200,
            initialAmount: 200,
            initialQuantity: 1,
          ),
        ],
      );

      final result = await harness.workflows.createPreparedMeal(
        name: 'Rice Bowl',
        totalPortions: 2,
        items: const <PreparedMealItemInput>[
          PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
        ],
        imageAssetId: ' hero ',
        inventoryRepository: inventoryRepository,
      );

      expect(result.isSuccess, isTrue);
      expect(result.preparedMealId, 'generated-id');
      expect(inventoryRepository.readCount, 1);
      expect(inventoryRepository.saveCount, 1);
      expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
      expect(harness.saveCalls, 1);
      expect(harness.lastSavedMeals.single.name, 'Rice Bowl');
      expect(harness.lastSavedMeals.single.imageAssetId, 'hero');
      expect(harness.lastSavedMeals.single.components, hasLength(1));
    });

    test(
      'createPreparedMeal returns invalid input before touching repository',
      () async {
        final harness = _WorkflowHarness();
        final inventoryRepository = _FakeInventoryItemRepository();

        final result = await harness.workflows.createPreparedMeal(
          name: ' ',
          totalPortions: 0,
          items: const <PreparedMealItemInput>[],
          imageAssetId: null,
          inventoryRepository: inventoryRepository,
        );

        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.invalidInput,
        );
        expect(inventoryRepository.readCount, 0);
        expect(harness.loadCalls, 0);
      },
    );

    test(
      'createPreparedMealFromTemplate saves created meal on success',
      () async {
        final harness = _WorkflowHarness();
        final inventoryRepository = _FakeInventoryItemRepository(
          items: <InventoryItem>[
            _measuredItem(
              id: 'rice',
              name: 'Rice',
              currentAmount: 200,
              initialAmount: 200,
              initialQuantity: 1,
            ),
          ],
        );

        final result = await harness.workflows.createPreparedMealFromTemplate(
          template: _meal(
            id: 'template',
            name: 'Rice Bowl',
            totalPortions: 1,
            remainingPortions: 1,
            recipeIngredients: const <String>['100 g rice'],
            components: const <PreparedMealComponent>[],
          ),
          totalPortions: 1,
          recipeIngredientAssignments: const <String, List<String>>{
            '100 g rice': <String>['rice'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
          inventoryRepository: inventoryRepository,
          ingredientParser: ingredientParser,
        );

        expect(result.isSuccess, isTrue);
        expect(inventoryRepository.saveCount, 1);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
        expect(harness.saveCalls, 1);
        expect(harness.lastSavedMeals.single.components, hasLength(1));
        expect(harness.lastSavedMeals.single.pendingRecipeIngredients, isEmpty);
        expect(
          harness
              .lastSavedMeals
              .single
              .recipeIngredientAssignments['100 g rice'],
          equals(<String>['rice']),
        );
      },
    );

    test(
      'createPreparedMealFromTemplate returns invalid input early',
      () async {
        final harness = _WorkflowHarness();
        final result = await harness.workflows.createPreparedMealFromTemplate(
          template: _meal(
            id: 'template',
            name: 'Soup',
            totalPortions: 1,
            remainingPortions: 1,
            components: const <PreparedMealComponent>[],
          ),
          totalPortions: 0,
          recipeIngredientAssignments: const <String, List<String>>{},
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
          inventoryRepository: _FakeInventoryItemRepository(),
          ingredientParser: ingredientParser,
        );

        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.invalidInput,
        );
        expect(harness.loadCalls, 0);
      },
    );

    test('updatePreparedMealDetails saves changed values', () async {
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Soup',
            totalPortions: 2,
            remainingPortions: 2,
            imageAssetId: 'hero-old',
            components: const <PreparedMealComponent>[],
          ),
        ],
      );

      final saved = await harness.workflows.updatePreparedMealDetails(
        mealId: 'meal-1',
        name: 'Tomato Soup',
        imageChanged: true,
        imageAssetId: 'hero-new',
      );

      expect(saved, isTrue);
      expect(harness.saveCalls, 1);
      expect(harness.lastSavedMeals.single.name, 'Tomato Soup');
      expect(harness.lastSavedMeals.single.imageAssetId, 'hero-new');
    });

    test(
      'updatePreparedMealDetails skips save when values unchanged',
      () async {
        final meal = _meal(
          id: 'meal-1',
          name: 'Soup',
          totalPortions: 2,
          remainingPortions: 2,
          imageAssetId: 'hero',
          components: const <PreparedMealComponent>[],
        );
        final harness = _WorkflowHarness(meals: <PreparedMeal>[meal]);

        final saved = await harness.workflows.updatePreparedMealDetails(
          mealId: 'meal-1',
          name: 'Soup',
          imageChanged: true,
          imageAssetId: 'hero',
        );

        expect(saved, isTrue);
        expect(harness.saveCalls, 0);
      },
    );

    test(
      'fillPreparedMealPendingIngredient updates inventory and meal',
      () async {
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Soup',
              totalPortions: 2,
              remainingPortions: 2,
              pendingRecipeIngredients: const <String>['100 g rice'],
              components: const <PreparedMealComponent>[],
            ),
          ],
        );
        final inventoryRepository = _FakeInventoryItemRepository(
          items: <InventoryItem>[
            _measuredItem(
              id: 'rice',
              name: 'Rice',
              currentAmount: 150,
              initialAmount: 150,
              initialQuantity: 1,
            ),
          ],
        );

        final saved = await harness.workflows.fillPreparedMealPendingIngredient(
          mealId: 'meal-1',
          ingredient: '100 g rice',
          inventoryItemIds: const <String>['rice'],
          inventoryRepository: inventoryRepository,
          ingredientParser: ingredientParser,
        );

        expect(saved, isTrue);
        expect(inventoryRepository.saveCount, 1);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 50);
        expect(harness.saveCalls, 1);
        expect(harness.lastSavedMeals.single.pendingRecipeIngredients, isEmpty);
        expect(harness.lastSavedMeals.single.components, hasLength(1));
        expect(harness.lastSavedMeals.single.totalKcal, 100);
      },
    );

    test(
      'fillPreparedMealPendingIngredient returns false for blank ids',
      () async {
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Soup',
              totalPortions: 2,
              remainingPortions: 2,
              pendingRecipeIngredients: const <String>['100 g rice'],
              components: const <PreparedMealComponent>[],
            ),
          ],
        );

        final saved = await harness.workflows.fillPreparedMealPendingIngredient(
          mealId: 'meal-1',
          ingredient: '100 g rice',
          inventoryItemIds: const <String>['   '],
          inventoryRepository: _FakeInventoryItemRepository(),
          ingredientParser: ingredientParser,
        );

        expect(saved, isFalse);
        expect(harness.loadCalls, 0);
      },
    );

    test('ignorePreparedMealPendingIngredient saves updated meal', () async {
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Soup',
            totalPortions: 2,
            remainingPortions: 2,
            pendingRecipeIngredients: const <String>['100 g rice'],
            components: const <PreparedMealComponent>[],
          ),
        ],
      );

      final saved = await harness.workflows.ignorePreparedMealPendingIngredient(
        mealId: 'meal-1',
        ingredient: '100 g rice',
      );

      expect(saved, isTrue);
      expect(harness.saveCalls, 1);
      expect(
        harness.lastSavedMeals.single.pendingRecipeIngredients,
        isEmpty,
      );
    });

    test('consumePreparedMeal saves reduced meal and calorie entry', () async {
      final rice = _measuredItem(
        id: 'rice',
        name: 'Rice',
        currentAmount: 400,
        initialAmount: 400,
        initialQuantity: 1,
      );
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Rice Bowl',
            totalPortions: 4,
            remainingPortions: 4,
            totalKcal: 400,
            totalProtein: 40,
            totalCarbs: 80,
            totalFat: 20,
            components: <PreparedMealComponent>[
              _component(
                item: rice,
                usedAmount: 400,
                totalKcal: 400,
                totalProtein: 40,
                totalCarbs: 80,
                totalFat: 20,
              ),
            ],
          ),
        ],
      );
      var savedEntryCount = 0;
      final bridge = PreparedMealCalorieLogBridge(
        saveEntry: (_) async {
          savedEntryCount += 1;
          return true;
        },
        now: () => DateTime(2026, 4, 19, 12),
        nextEntryId: () => 'entry-1',
      );

      final saved = await harness.workflows.consumePreparedMeal(
        mealId: 'meal-1',
        consumedPortions: 2,
        mealType: MealType.breakfast,
        loggedDay: null,
        calorieLogBridge: bridge,
      );

      expect(saved, isTrue);
      expect(savedEntryCount, 1);
      expect(harness.saveCalls, 1);
      expect(harness.lastSavedMeals.single.remainingPortions, 2);
      expect(harness.publishCalls, 0);
    });

    test('consumePreparedMeal returns false for invalid portions', () async {
      final harness = _WorkflowHarness();
      final bridge = PreparedMealCalorieLogBridge(
        saveEntry: (_) async => true,
        now: () => DateTime(2026, 4, 19),
        nextEntryId: () => 'entry-1',
      );

      final saved = await harness.workflows.consumePreparedMeal(
        mealId: 'meal-1',
        consumedPortions: 0,
        mealType: MealType.breakfast,
        loggedDay: null,
        calorieLogBridge: bridge,
      );

      expect(saved, isFalse);
      expect(harness.loadCalls, 0);
    });

    test(
      'throwAwayPreparedMeal saves reduced meal and discard event',
      () async {
        final sourceItem = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 400,
          initialAmount: 400,
          initialQuantity: 1,
          unitPrice: 4,
        );
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Rice Bowl',
              totalPortions: 4,
              remainingPortions: 4,
              components: <PreparedMealComponent>[
                _component(item: sourceItem, usedAmount: 400, totalKcal: 400),
              ],
            ),
          ],
        );
        final discardRepository = _FakeDiscardEventRepository();

        final saved = await harness.workflows.throwAwayPreparedMeal(
          mealId: 'meal-1',
          discardedPortions: 1,
          reason: InventoryDiscardReason.spoiled,
          discardEventRepository: discardRepository,
        );

        expect(saved, isTrue);
        expect(harness.saveCalls, 1);
        expect(harness.lastSavedMeals.single.remainingPortions, 3);
        expect(discardRepository.saveCount, 1);
        expect(discardRepository.lastSavedEvent?.sourceId, 'meal-1');
        expect(
          discardRepository.lastSavedEvent?.reason,
          InventoryDiscardReason.spoiled,
        );
      },
    );

    test('throwAwayPreparedMeal returns false for invalid portions', () async {
      final harness = _WorkflowHarness();
      final discardRepository = _FakeDiscardEventRepository();

      final saved = await harness.workflows.throwAwayPreparedMeal(
        mealId: 'meal-1',
        discardedPortions: 0,
        reason: InventoryDiscardReason.spoiled,
        discardEventRepository: discardRepository,
      );

      expect(saved, isFalse);
      expect(discardRepository.saveCount, 0);
      expect(harness.loadCalls, 0);
    });

    test('restorePreparedMealPortions saves increased portions', () async {
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Soup',
            totalPortions: 4,
            remainingPortions: 2,
            components: const <PreparedMealComponent>[],
          ),
        ],
      );

      final saved = await harness.workflows.restorePreparedMealPortions(
        mealId: 'meal-1',
        portions: 1,
      );

      expect(saved, isTrue);
      expect(harness.saveCalls, 1);
      expect(harness.lastSavedMeals.single.remainingPortions, 3);
    });

    test(
      'restorePreparedMealPortions returns false when exceeding total',
      () async {
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Soup',
              totalPortions: 2,
              remainingPortions: 2,
              components: const <PreparedMealComponent>[],
            ),
          ],
        );

        final saved = await harness.workflows.restorePreparedMealPortions(
          mealId: 'meal-1',
          portions: 1,
        );

        expect(saved, isFalse);
        expect(harness.saveCalls, 0);
      },
    );

    test('unbundlePreparedMeal restores inventory and removes meal', () async {
      final sourceItem = _measuredItem(
        id: 'rice',
        name: 'Rice',
        currentAmount: 200,
        initialAmount: 200,
        initialQuantity: 1,
      );
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Rice Bowl',
            totalPortions: 4,
            remainingPortions: 2,
            components: <PreparedMealComponent>[
              _component(item: sourceItem, usedAmount: 200, totalKcal: 200),
            ],
          ),
        ],
      );
      final inventoryRepository = _FakeInventoryItemRepository();

      final saved = await harness.workflows.unbundlePreparedMeal(
        mealId: 'meal-1',
        inventoryRepository: inventoryRepository,
      );

      expect(saved, isTrue);
      expect(inventoryRepository.readCount, 1);
      expect(inventoryRepository.saveCount, 1);
      expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
      expect(harness.saveCalls, 1);
      expect(harness.lastSavedMeals, isEmpty);
    });

    test('unbundlePreparedMeal returns false when meal is missing', () async {
      final harness = _WorkflowHarness();
      final inventoryRepository = _FakeInventoryItemRepository();

      final saved = await harness.workflows.unbundlePreparedMeal(
        mealId: 'missing',
        inventoryRepository: inventoryRepository,
      );

      expect(saved, isFalse);
      expect(inventoryRepository.readCount, 0);
    });
  });
}

class _WorkflowHarness {
  _WorkflowHarness({List<PreparedMeal>? meals})
    : _meals = List<PreparedMeal>.from(meals ?? const <PreparedMeal>[]);

  final List<PreparedMeal> _meals;
  int loadCalls = 0;
  int saveCalls = 0;
  int publishCalls = 0;
  int restoreInventoryCalls = 0;
  List<PreparedMeal> lastSavedMeals = const <PreparedMeal>[];
  List<PreparedMeal> lastPublishedMeals = const <PreparedMeal>[];

  PreparedMealMutationWorkflows get workflows {
    return PreparedMealMutationWorkflows(
      loadMeals: () async {
        loadCalls += 1;
        return List<PreparedMeal>.from(_meals);
      },
      saveMeals: ({required previousMeals, required nextMeals}) async {
        saveCalls += 1;
        lastSavedMeals = List<PreparedMeal>.from(nextMeals);
        _meals
          ..clear()
          ..addAll(nextMeals);
        return true;
      },
      restoreInventory:
          ({
            required inventoryRepository,
            required previousItems,
          }) async {
            restoreInventoryCalls += 1;
          },
      publishMeals: (meals) {
        publishCalls += 1;
        lastPublishedMeals = List<PreparedMeal>.from(meals);
      },
      buildId: () => 'generated-id',
      buildNow: () => DateTime(2026, 4, 19),
      logName: 'test',
    );
  }
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({List<InventoryItem>? items})
    : _items = List<InventoryItem>.from(items ?? const <InventoryItem>[]);

  final List<InventoryItem> _items;
  int readCount = 0;
  int saveCount = 0;
  List<InventoryItem> lastSavedItems = const <InventoryItem>[];

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    readCount += 1;
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    saveCount += 1;
    lastSavedItems = List<InventoryItem>.from(items);
    _items
      ..clear()
      ..addAll(items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items.addAll(items);
    return true;
  }
}

class _FakeDiscardEventRepository implements InventoryDiscardEventRepository {
  int saveCount = 0;
  InventoryDiscardEvent? lastSavedEvent;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return const <InventoryDiscardEvent>[];
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    saveCount += 1;
    lastSavedEvent = event;
    return true;
  }

  @override
  Future<bool> deleteEvent(String eventId) async {
    return true;
  }
}

PreparedMeal _meal({
  required String id,
  required String name,
  required int totalPortions,
  required int remainingPortions,
  required List<PreparedMealComponent> components,
  double totalKcal = 0,
  double totalProtein = 0,
  double totalCarbs = 0,
  double totalFat = 0,
  String? imageAssetId,
  List<String> pendingRecipeIngredients = const <String>[],
  List<String> recipeIngredients = const <String>[],
}) {
  return PreparedMeal(
    id: id,
    name: name,
    imageAssetId: imageAssetId,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: totalKcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    createdAt: DateTime(2026, 4, 19),
    updatedAt: DateTime(2026, 4, 19),
    recipeIngredients: recipeIngredients,
    pendingRecipeIngredients: pendingRecipeIngredients,
    components: components,
  );
}

InventoryItem _measuredItem({
  required String id,
  required String name,
  required int currentAmount,
  required int initialAmount,
  required int initialQuantity,
  double unitPrice = 0,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 19),
    storeName: 'Store',
    quantity: initialQuantity,
    initialQuantity: initialQuantity,
    unitPrice: unitPrice,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: nutrition ?? _nutrition(),
  );
}

PreparedMealComponent _component({
  required InventoryItem item,
  required int usedAmount,
  double totalKcal = 0,
  double totalProtein = 0,
  double totalCarbs = 0,
  double totalFat = 0,
}) {
  return PreparedMealComponent(
    inventoryItemId: item.id,
    name: item.name,
    brand: item.brand,
    imageUrl: item.imageUrl,
    usedAmount: usedAmount,
    usedUnit: item.amountUnit ?? InventoryAmountUnit.piece,
    totalKcal: totalKcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    sourceItemSnapshot: item,
  );
}

GlobalFoodNutrition _nutrition() {
  return const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
  );
}
