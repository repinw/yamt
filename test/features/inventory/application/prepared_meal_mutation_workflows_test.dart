import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_calorie_log_bridge.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_support.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_workflows.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  group('prepared meal mutation workflows', () {
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
          ingredientParser: const TemplateIngredientParser(),
        );

        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.invalidInput,
        );
        expect(harness.loadCalls, 0);
      },
    );

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
          ingredientParser: const TemplateIngredientParser(),
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
    : _meals = meals ?? <PreparedMeal>[];

  final List<PreparedMeal> _meals;
  int loadCalls = 0;
  int saveCalls = 0;
  List<PreparedMeal> lastSavedMeals = const <PreparedMeal>[];

  PreparedMealMutationWorkflows get workflows {
    return PreparedMealMutationWorkflows(
      loadMeals: () async {
        loadCalls += 1;
        return List<PreparedMeal>.from(_meals);
      },
      saveMeals: ({required previousMeals, required nextMeals}) async {
        saveCalls += 1;
        lastSavedMeals = List<PreparedMeal>.from(nextMeals);
        return true;
      },
      restoreInventory:
          ({
            required inventoryRepository,
            required previousItems,
          }) async {},
      publishMeals: (_) {},
      buildId: () => 'generated-id',
      buildNow: () => DateTime(2026, 4, 19),
      logName: 'test',
    );
  }
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  int readCount = 0;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    readCount += 1;
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }
}

class _FakeDiscardEventRepository implements InventoryDiscardEventRepository {
  int saveCount = 0;

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return const <InventoryDiscardEvent>[];
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    saveCount += 1;
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
  String? imageAssetId,
  List<String> pendingRecipeIngredients = const <String>[],
}) {
  return PreparedMeal(
    id: id,
    name: name,
    imageAssetId: imageAssetId,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime(2026, 4, 19),
    updatedAt: DateTime(2026, 4, 19),
    pendingRecipeIngredients: pendingRecipeIngredients,
    components: components,
  );
}
