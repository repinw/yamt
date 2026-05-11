import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

void main() {
  group('validateCookingFlowFinalize', () {
    test('returns expected weight failures', () {
      expect(
        validateCookingFlowFinalize(
          containers: const <CookingFlowFinalizeStorageContainerInput>[],
          summaryIngredients: _summaryRows,
          assignments: const <String, String>{},
        ),
        CookingFlowFinalizeValidationFailure.missingWeight,
      );
      expect(
        validateCookingFlowFinalize(
          containers: <CookingFlowFinalizeStorageContainerInput>[
            _container(grossWeightText: '', grossWeight: 0),
          ],
          summaryIngredients: _summaryRows,
          assignments: const <String, String>{'row-rice': 'container-1'},
        ),
        CookingFlowFinalizeValidationFailure.missingGrossWeight,
      );
      expect(
        validateCookingFlowFinalize(
          containers: <CookingFlowFinalizeStorageContainerInput>[
            _container(grossWeightText: 'abc', grossWeight: 0),
          ],
          summaryIngredients: _summaryRows,
          assignments: const <String, String>{'row-rice': 'container-1'},
        ),
        CookingFlowFinalizeValidationFailure.invalidWeight,
      );
      expect(
        validateCookingFlowFinalize(
          containers: <CookingFlowFinalizeStorageContainerInput>[
            _container(taraWeight: 700, grossWeight: 700),
          ],
          summaryIngredients: _summaryRows,
          assignments: const <String, String>{'row-rice': 'container-1'},
        ),
        CookingFlowFinalizeValidationFailure.grossMustExceedTara,
      );
    });

    test('blocks containers that have no assigned ingredient', () {
      final failure = validateCookingFlowFinalize(
        containers: <CookingFlowFinalizeStorageContainerInput>[
          _container(id: 'container-1'),
          _container(id: 'container-2'),
        ],
        summaryIngredients: _summaryRows,
        assignments: const <String, String>{'row-rice': 'container-1'},
      );

      expect(
        failure,
        CookingFlowFinalizeValidationFailure.containerMissingIngredients,
      );
    });
  });

  test('buildCookingFlowFinalizeNutritionPreview divides by portions', () {
    final preview = buildCookingFlowFinalizeNutritionPreview(
      template: _template(),
      inventoryItems: <InventoryItem>[_item(id: 'rice', name: 'Rice')],
      summaryIngredients: _summaryRows,
      introDraft: null,
      targetPortions: 4,
      finalPortions: 4,
      splitIntoPortions: true,
      portionCount: 4,
      ingredientParser: const TemplateIngredientParser(),
    );

    expect(preview.kcal, closeTo(50, 0.0001));
    expect(preview.protein, closeTo(5, 0.0001));
    expect(preview.carbs, closeTo(10, 0.0001));
    expect(preview.fat, closeTo(2.5, 0.0001));
  });

  test('buildCookingFlowFinalizeSavePlan merges template and extra rows', () {
    const conversion = RecipeIngredientAmountConversion(
      amountPerPiece: 100,
      unit: InventoryAmountUnit.gram,
    );

    final plan = buildCookingFlowFinalizeSavePlan(
      template: _template(
        recipeIngredientAmountConversions:
            const <String, RecipeIngredientAmountConversion>{
              '200g Rice': conversion,
            },
      ),
      inventoryItems: <InventoryItem>[
        _item(id: 'rice', name: 'Rice'),
        _item(id: 'cheese', name: 'Cheese'),
      ],
      summaryIngredients: _summaryRowsWithExtra,
      introDraft: null,
      targetPortions: 4,
      finalPortions: 3,
    );

    expect(plan.template.recipeIngredients, <String>['200g Rice']);
    expect(plan.template.ignoredRecipeIngredients, isEmpty);
    expect(plan.template.totalPortions, 3);
    expect(plan.recipeIngredientAssignments, <String, List<String>>{
      '200g Rice': <String>['rice'],
    });
    expect(plan.recipeIngredientAmountConversions['200g Rice'], conversion);
    expect(plan.additionalItems, hasLength(1));
    expect(plan.additionalItems.single.itemId, 'cheese');
    expect(plan.additionalItems.single.usedAmount, 50);
    expect(plan.additionalItems.single.sourceKey, 'row-cheese');
    expect(plan.sourceKeysByIngredient, <String, String>{
      '200g Rice': 'row-rice',
    });
    expect(plan.totalInputCount, 2);
  });
}

const _summaryRows = <CookingFlowSummaryIngredientDraft>[
  CookingFlowSummaryIngredientDraft(
    key: 'row-rice',
    name: 'Rice',
    amount: '200',
    unitCode: 'g',
    inventoryItemIds: <String>['rice'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '200g Rice',
  ),
];

const _summaryRowsWithExtra = <CookingFlowSummaryIngredientDraft>[
  ..._summaryRows,
  CookingFlowSummaryIngredientDraft(
    key: 'row-cheese',
    name: 'Cheese',
    amount: '50',
    unitCode: 'g',
    inventoryItemIds: <String>['cheese'],
    kind: CookingFlowSummaryIngredientKind.additional,
  ),
];

CookingFlowFinalizeStorageContainerInput _container({
  String id = 'container-1',
  String grossWeightText = '700',
  int taraWeight = 100,
  int grossWeight = 700,
}) {
  return CookingFlowFinalizeStorageContainerInput(
    id: id,
    label: 'Topf',
    taraText: '$taraWeight',
    grossWeightText: grossWeightText,
    taraWeight: taraWeight,
    grossWeight: grossWeight,
    finalNetWeight: grossWeight - taraWeight,
    totalPortions: 4,
  );
}

PreparedMeal _template({
  Map<String, RecipeIngredientAmountConversion>
      recipeIngredientAmountConversions =
      const <String, RecipeIngredientAmountConversion>{},
}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Rice Bowl',
    recipeIngredients: const <String>['200g Rice'],
    recipeIngredientAmountConversions: recipeIngredientAmountConversions,
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

InventoryItem _item({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 100,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );
}
