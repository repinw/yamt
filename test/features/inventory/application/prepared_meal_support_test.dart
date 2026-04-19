import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_support.dart';
import 'package:yamt/features/inventory/application/'
    'template_ingredient_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  const parser = TemplateIngredientParser();
  final now = DateTime(2026, 4, 19);

  group('prepared meal support', () {
    test('buildPreparedMealCreationResult uses manual nutrition override', () {
      final result = buildPreparedMealCreationResult(
        currentItems: <InventoryItem>[
          _pieceItem(id: 'apple', name: 'Apple', quantity: 3),
        ],
        preparedMealId: 'meal-1',
        now: now,
        name: 'Fruit Plate',
        imageAssetId: '  fruit ',
        totalPortions: 2,
        inputs: const <PreparedMealItemInput>[
          PreparedMealItemInput(
            itemId: 'apple',
            usedAmount: 2,
            manualNutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 10,
              per100Protein: 1,
              per100Carbs: 2,
              per100Fat: 3,
            ),
          ),
        ],
      );

      expect(result.nextItems.single.quantity, 1);
      expect(result.preparedMeal.imageAssetId, 'fruit');
      expect(result.preparedMeal.totalKcal, 20);
      expect(result.preparedMeal.totalProtein, 2);
      expect(result.preparedMeal.components.single.totalFat, 6);
    });

    test('buildPreparedMealCreationResult throws on missing nutrition', () {
      expect(
        () => buildPreparedMealCreationResult(
          currentItems: <InventoryItem>[
            _pieceItem(id: 'apple', name: 'Apple', quantity: 3),
          ],
          preparedMealId: 'meal-1',
          now: now,
          name: 'Fruit Plate',
          imageAssetId: null,
          totalPortions: 1,
          inputs: const <PreparedMealItemInput>[
            PreparedMealItemInput(itemId: 'apple', usedAmount: 1),
          ],
        ),
        throwsA(
          isA<PreparedMealBuildException>().having(
            (error) => error.reason,
            'reason',
            PreparedMealCreationFailureReason.missingNutrition,
          ),
        ),
      );
    });

    test(
      'buildPreparedMealCreationFromTemplateResult keeps missing remainder '
      'pending',
      () {
        final rice = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 150,
          initialAmount: 200,
          initialQuantity: 1,
        );
        final template = PreparedMeal(
          id: 'template-1',
          name: 'Rice Bowl',
          totalPortions: 1,
          remainingPortions: 1,
          totalKcal: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          createdAt: now,
          updatedAt: now,
          components: const <PreparedMealComponent>[],
          recipeIngredients: const <String>['200 g rice', '1 onion'],
        );

        final result = buildPreparedMealCreationFromTemplateResult(
          currentItems: <InventoryItem>[rice],
          preparedMealId: 'meal-1',
          now: now,
          template: template,
          totalPortions: 1,
          recipeIngredientAssignments: const <String, List<String>>{
            '200 g rice': <String>['rice'],
          },
          recipeIngredientAmountConversions:
              const <String, RecipeIngredientAmountConversion>{},
          ingredientParser: parser,
        );

        expect(result.nextItems.single.currentAmount, 0);
        expect(
          result.preparedMeal.pendingRecipeIngredients,
          containsAll(<String>['50 g rice', '1 pc onion']),
        );
      },
    );

    test(
      'buildPreparedMealPendingIngredientFillResult returns remainder label',
      () {
        final rice = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 150,
          initialAmount: 200,
          initialQuantity: 1,
        );

        final result = buildPreparedMealPendingIngredientFillResult(
          currentItems: <InventoryItem>[rice],
          ingredient: '200 g rice',
          inventoryItemIds: const <String>['rice'],
          ingredientParser: parser,
        );

        expect(result, isNotNull);
        expect(result!.nextItems.single.currentAmount, 0);
        expect(result.components, hasLength(1));
        expect(result.remainingIngredient, '50 g rice');
      },
    );

    test('applyPreparedMealPortionReduction removes depleted meal', () {
      final nextMeals = applyPreparedMealPortionReduction(
        currentMeals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Meal',
            totalPortions: 2,
            remainingPortions: 1,
            components: const <PreparedMealComponent>[],
          ),
        ],
        mealIndex: 0,
        removedPortions: 1,
        updatedAt: now,
      );

      expect(nextMeals, isEmpty);
    });

    test('restoreItemsFromPreparedMeal recreates missing snapshot item', () {
      final sourceItem = _measuredItem(
        id: 'rice',
        name: 'Rice',
        currentAmount: 400,
        initialAmount: 400,
        initialQuantity: 2,
      );
      final meal = _meal(
        id: 'meal-1',
        name: 'Rice Bowl',
        totalPortions: 4,
        remainingPortions: 2,
        components: <PreparedMealComponent>[
          PreparedMealComponent(
            inventoryItemId: 'rice',
            name: sourceItem.name,
            brand: sourceItem.brand,
            imageUrl: sourceItem.imageUrl,
            usedAmount: 200,
            usedUnit: InventoryAmountUnit.gram,
            totalKcal: 200,
            totalProtein: 10,
            totalCarbs: 20,
            totalFat: 5,
            sourceItemSnapshot: sourceItem,
          ),
        ],
      );

      final restoredItems = restoreItemsFromPreparedMeal(
        currentItems: const <InventoryItem>[],
        meal: meal,
      );

      expect(restoredItems, hasLength(1));
      expect(restoredItems.single.currentAmount, 100);
      expect(restoredItems.single.quantity, 1);
    });
  });
}

InventoryItem _pieceItem({
  required String id,
  required String name,
  required int quantity,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 19),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
    nutrition: nutrition,
  );
}

InventoryItem _measuredItem({
  required String id,
  required String name,
  required int currentAmount,
  required int initialAmount,
  required int initialQuantity,
  GlobalFoodNutrition? nutrition,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 4, 19),
    storeName: 'Store',
    quantity: initialQuantity,
    initialQuantity: initialQuantity,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    nutrition:
        nutrition ??
        const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
          per100Protein: 10,
          per100Carbs: 20,
          per100Fat: 5,
        ),
  );
}

PreparedMeal _meal({
  required String id,
  required String name,
  required int totalPortions,
  required int remainingPortions,
  required List<PreparedMealComponent> components,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime(2026, 4, 19),
    updatedAt: DateTime(2026, 4, 19),
    components: components,
  );
}
