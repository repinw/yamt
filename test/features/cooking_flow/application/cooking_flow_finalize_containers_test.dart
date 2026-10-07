import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_creation.dart';
import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Replays the 2026-09-27 device run: a two-portion recipe scaled to four
/// portions, split into two containers.

import '../../../helpers/fake_prepared_meal_repository.dart';

void main() {
  test('every assigned row lands in its container meal', () async {
    final repository = _FakeInventoryItemRepository(<InventoryItem>[
      _pieceItem(id: 'eggs', name: 'Eier', pieces: 10, per100Kcal: 155),
      _gramItem(id: 'milk', name: 'Milch', grams: 1000, per100Kcal: 64),
      _gramItem(id: 'butter', name: 'Butter', grams: 250, per100Kcal: 741),
      _gramItem(id: 'tomatoes', name: 'Tomaten', grams: 500, per100Kcal: 18),
    ]);
    final meals = FakePreparedMealRepository();

    final savePlan = buildCookingFlowFinalizeSavePlan(
      template: _template(),
      inventoryItems: await repository.readAll(),
      summaryIngredients: _summaryRows,
      introDraft: null,
      targetPortions: 4,
      finalPortions: 4,
    );
    final containers = buildCookingFlowPreparedMealContainers(
      savePlan: savePlan,
      containers: _containers,
      ingredientContainerAssignments: const <String, String>{
        'template:4 Eier': 'container-1',
        'template:4 EL Milch': 'container-1',
        'template:20 g Butter': 'container-1',
        'template:200 g kleine Tomaten': 'container-2',
      },
    );
    final result = await _workflows(meals)
        .createPreparedMealsFromTemplateContainers(
          template: savePlan.template,
          totalPortions: savePlan.template.totalPortions,
          recipeIngredientAssignments: savePlan.recipeIngredientAssignments,
          recipeIngredientAmountConversions:
              savePlan.recipeIngredientAmountConversions,
          inventoryRepository: repository,
          ingredientParser: const TemplateIngredientParser(),
          containers: containers,
          sourceKeysByIngredient: savePlan.sourceKeysByIngredient,
          additionalItems: savePlan.additionalItems,
        );

    expect(result.isSuccess, isTrue);
    final savedMeals = meals.meals;
    expect(savedMeals, hasLength(2));

    final first = savedMeals[0];
    expect(first.name, 'Rührei - Behälter 1');
    expect(
      first.components.map((component) => component.inventoryItemId),
      <String>['eggs', 'butter'],
    );
    expect(first.components.first.usedAmount, 8000);
    expect(first.pendingRecipeIngredients, <String>['8 pc Milch']);
    expect(first.recipeIngredients, <String>[
      '8 pc Eier',
      '8 pc Milch',
      '40g Butter',
    ]);
    expect(first.totalKcal, closeTo(155 * 8 + 741 * 0.4, 0.001));

    final second = savedMeals[1];
    expect(
      second.components.map((component) => component.inventoryItemId),
      <String>['tomatoes'],
    );
    expect(second.pendingRecipeIngredients, isEmpty);

    final eggs = repository.items.firstWhere((item) => item.id == 'eggs');
    expect(eggs.currentAmount, 2000);
  });
}

const _summaryRows = <CookingFlowSummaryIngredientDraft>[
  CookingFlowSummaryIngredientDraft(
    key: 'template:4 Eier',
    name: 'Eier',
    amount: '8',
    unitCode: 'pc',
    inventoryItemIds: <String>['eggs'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '4 Eier',
  ),
  CookingFlowSummaryIngredientDraft(
    key: 'template:4 EL Milch',
    name: 'Milch',
    amount: '8',
    unitCode: 'pc',
    inventoryItemIds: <String>['milk'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '4 EL Milch',
  ),
  CookingFlowSummaryIngredientDraft(
    key: 'template:20 g Butter',
    name: 'Butter',
    amount: '40',
    unitCode: 'g',
    inventoryItemIds: <String>['butter'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '20 g Butter',
  ),
  CookingFlowSummaryIngredientDraft(
    key: 'template:200 g kleine Tomaten',
    name: 'kleine Tomaten',
    amount: '400',
    unitCode: 'g',
    inventoryItemIds: <String>['tomatoes'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '200 g kleine Tomaten',
  ),
];

const _containers = <CookingFlowFinalizeStorageContainerInput>[
  CookingFlowFinalizeStorageContainerInput(
    id: 'container-1',
    label: 'Behälter 1',
    taraText: '350',
    grossWeightText: '750',
    taraWeight: 350,
    grossWeight: 750,
    finalNetWeight: 400,
    totalPortions: 2,
  ),
  CookingFlowFinalizeStorageContainerInput(
    id: 'container-2',
    label: 'Behälter 2',
    taraText: '300',
    grossWeightText: '650',
    taraWeight: 300,
    grossWeight: 650,
    finalNetWeight: 350,
    totalPortions: 2,
  ),
];

PreparedMealCreation _workflows(FakePreparedMealRepository meals) {
  var nextId = 0;
  return PreparedMealCreation(
    writer: PreparedMealWriter(
      meals: meals,
      clock: () => DateTime(2026, 9, 27),
      logName: 'test',
      newId: () => 'meal-${nextId++}',
    ),
  );
}

PreparedMeal _template() {
  final now = DateTime(2026, 9, 27);
  return PreparedMeal(
    id: 'template-1',
    name: 'Rührei',
    recipeIngredients: const <String>[
      '4 Eier',
      '4 EL Milch',
      '20 g Butter',
      '200 g kleine Tomaten',
    ],
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

InventoryItem _pieceItem({
  required String id,
  required String name,
  required int pieces,
  required double per100Kcal,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 9, 20),
    storeName: 'Store',
    quantity: 1,
    initialAmount: pieces * inventoryPieceAmountScale,
    currentAmount: pieces * inventoryPieceAmountScale,
    amountScale: inventoryPieceAmountScale,
    amountUnit: InventoryAmountUnit.piece,
    nutrition: _nutrition(per100Kcal),
  );
}

InventoryItem _gramItem({
  required String id,
  required String name,
  required int grams,
  required double per100Kcal,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 9, 20),
    storeName: 'Store',
    quantity: 1,
    initialAmount: grams,
    currentAmount: grams,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: _nutrition(per100Kcal),
  );
}

GlobalFoodNutrition _nutrition(double per100Kcal) {
  return GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: per100Kcal,
    per100Protein: 1,
    per100Carbs: 1,
    per100Fat: 1,
  );
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  new(List<InventoryItem> items) : items = List<InventoryItem>.from(items);

  List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> nextItems) async {
    items = List<InventoryItem>.from(nextItems);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> newItems) async {
    items = <InventoryItem>[...items, ...newItems];
    return true;
  }
}
