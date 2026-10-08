import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/application/prepared_meal_creation.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/application/prepared_meal_writer.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

import '../../../helpers/fake_prepared_meal_repository.dart';
import '../../../helpers/inventory_item_whole_list_writes.dart';

void main() {
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

      final result = await harness
          .mutations(inventory: inventoryRepository)
          .createPreparedMeal(
            name: 'Rice Bowl',
            totalPortions: 2,
            items: const <PreparedMealItemInput>[
              PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
            ],
            imageAssetId: ' hero ',
          );

      expect(result.isSuccess, isTrue);
      expect(result.preparedMealId, 'generated-id');
      expect(inventoryRepository.readCount, 1);
      expect(inventoryRepository.saveCount, 1);
      expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
      expect(harness.meals.writeCount, 1);
      expect(harness.meals.meals.single.name, 'Rice Bowl');
      expect(harness.meals.meals.single.imageAssetId, 'hero');
      expect(harness.meals.meals.single.components, hasLength(1));
    });

    test(
      'a rollback keeps an item that another device wrote meanwhile',
      () async {
        final harness = _WorkflowHarness(saveMealsResults: <bool>[false]);
        final milk = _measuredItem(
          id: 'milk',
          name: 'Milk',
          currentAmount: 1000,
          initialAmount: 1000,
          initialQuantity: 1,
        );
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
        )..writtenByOtherDevice = milk;

        final result = await harness
            .mutations(inventory: inventoryRepository)
            .createPreparedMeal(
              name: 'Rice Bowl',
              totalPortions: 2,
              items: const <PreparedMealItemInput>[
                PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
              ],
            );

        expect(result.isSuccess, isFalse);
        final stored = await inventoryRepository.storedItems();
        expect(
          stored.map((item) => item.id),
          unorderedEquals(['rice', 'milk']),
        );
        expect(
          stored.singleWhere((item) => item.id == 'rice').currentAmount,
          200,
        );
      },
    );

    test(
      'createPreparedMeal returns invalid input before touching repository',
      () async {
        final harness = _WorkflowHarness();
        final inventoryRepository = _FakeInventoryItemRepository();

        final result = await harness
            .mutations(inventory: inventoryRepository)
            .createPreparedMeal(
              name: ' ',
              totalPortions: 0,
              items: const <PreparedMealItemInput>[],
            );

        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.invalidInput,
        );
        // Only the read that remembers the stock for the history.
        expect(inventoryRepository.readCount, 1);
        expect(harness.meals.readCount, 0);
      },
    );

    test(
      'createPreparedMeal restores inventory when meal save fails',
      () async {
        final harness = _WorkflowHarness(saveMealsResults: <bool>[false]);
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

        final result = await harness
            .mutations(inventory: inventoryRepository)
            .createPreparedMeal(
              name: 'Rice Bowl',
              totalPortions: 2,
              items: const <PreparedMealItemInput>[
                PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
              ],
            );

        expect(result.isSuccess, isFalse);
        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.mealSaveFailed,
        );
        expect(harness.meals.writeCount, 1);
        expect(inventoryRepository.saveCount, 2);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 200);
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

        final result = await harness.creation().createPreparedMealFromTemplate(
          inventoryRepository: inventoryRepository,
          ingredientParser: const TemplateIngredientParser(),
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
        );

        expect(result.isSuccess, isTrue);
        expect(inventoryRepository.saveCount, 1);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
        expect(harness.meals.writeCount, 1);
        expect(harness.meals.meals.single.components, hasLength(1));
        expect(harness.meals.meals.single.pendingRecipeIngredients, isEmpty);
        expect(
          harness.meals.meals.single.recipeIngredientAssignments['100 g rice'],
          equals(<String>['rice']),
        );
      },
    );

    test(
      'createPreparedMealFromTemplate returns invalid input early',
      () async {
        final harness = _WorkflowHarness();
        final result = await harness.creation().createPreparedMealFromTemplate(
          inventoryRepository: _FakeInventoryItemRepository(),
          ingredientParser: const TemplateIngredientParser(),
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
        );

        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.invalidInput,
        );
        expect(harness.meals.readCount, 0);
      },
    );

    test(
      'createPreparedMealFromTemplate restores inventory when meal save fails',
      () async {
        final harness = _WorkflowHarness(saveMealsResults: <bool>[false]);
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

        final result = await harness.creation().createPreparedMealFromTemplate(
          inventoryRepository: inventoryRepository,
          ingredientParser: const TemplateIngredientParser(),
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
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.mealSaveFailed,
        );
        expect(harness.meals.writeCount, 1);
        expect(inventoryRepository.saveCount, 2);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 200);
      },
    );

    test('createPreparedMealsFromTemplateContainers consumes once '
        'and saves splits', () async {
      final harness = _WorkflowHarness();
      final inventoryRepository = _FakeInventoryItemRepository(
        items: <InventoryItem>[
          _measuredItem(
            id: 'pasta',
            name: 'Pasta',
            currentAmount: 200,
            initialAmount: 200,
            initialQuantity: 1,
          ),
          _measuredItem(
            id: 'sauce',
            name: 'Sauce',
            currentAmount: 100,
            initialAmount: 100,
            initialQuantity: 1,
          ),
        ],
      );

      final result = await harness
          .mutations(inventory: inventoryRepository)
          .createPreparedMealsFromTemplateContainers(
            template: _meal(
              id: 'template',
              name: 'Spaghetti',
              totalPortions: 4,
              remainingPortions: 4,
              recipeIngredients: const <String>['100 g pasta', '50 g sauce'],
              components: const <PreparedMealComponent>[],
            ),
            totalPortions: 4,
            recipeIngredientAssignments: const <String, List<String>>{
              '100 g pasta': <String>['pasta'],
              '50 g sauce': <String>['sauce'],
            },
            recipeIngredientAmountConversions:
                const <String, RecipeIngredientAmountConversion>{},
            sourceKeysByIngredient: const <String, String>{
              '100 g pasta': 'row-pasta',
              '50 g sauce': 'row-sauce',
            },
            containers: const <PreparedMealContainerInput>[
              PreparedMealContainerInput(
                id: 'container-1',
                label: 'Pasta',
                totalPortions: 4,
                finalNetWeight: 700,
                sourceKeys: <String>['row-pasta'],
              ),
              PreparedMealContainerInput(
                id: 'container-2',
                label: 'Sauce',
                totalPortions: 4,
                finalNetWeight: 300,
                sourceKeys: <String>['row-sauce'],
              ),
            ],
          );

      expect(result.isSuccess, isTrue);
      expect(inventoryRepository.saveCount, 2);
      expect(inventoryRepository.lastSavedItems[0].currentAmount, 100);
      expect(inventoryRepository.lastSavedItems[1].currentAmount, 50);
      // One document per split meal.
      expect(harness.meals.writeCount, 2);
      expect(harness.meals.meals, hasLength(2));

      final pastaMeal = harness.meals.meals[0];
      expect(pastaMeal.name, 'Spaghetti - Pasta');
      expect(pastaMeal.totalPortions, 4);
      expect(pastaMeal.finalNetWeight, 700);
      expect(pastaMeal.components.single.inventoryItemId, 'pasta');
      expect(pastaMeal.totalKcal, 100);

      final sauceMeal = harness.meals.meals[1];
      expect(sauceMeal.name, 'Spaghetti - Sauce');
      expect(sauceMeal.totalPortions, 4);
      expect(sauceMeal.finalNetWeight, 300);
      expect(sauceMeal.components.single.inventoryItemId, 'sauce');
      expect(sauceMeal.totalKcal, 50);
    });

    test(
      'createPreparedMealsFromTemplateContainers restores inventory on failure',
      () async {
        final harness = _WorkflowHarness(saveMealsResults: <bool>[false]);
        final inventoryRepository = _FakeInventoryItemRepository(
          items: <InventoryItem>[
            _measuredItem(
              id: 'pasta',
              name: 'Pasta',
              currentAmount: 200,
              initialAmount: 200,
              initialQuantity: 1,
            ),
          ],
        );

        final result = await harness
            .mutations(inventory: inventoryRepository)
            .createPreparedMealsFromTemplateContainers(
              template: _meal(
                id: 'template',
                name: 'Spaghetti',
                totalPortions: 4,
                remainingPortions: 4,
                recipeIngredients: const <String>['100 g pasta'],
                components: const <PreparedMealComponent>[],
              ),
              totalPortions: 4,
              recipeIngredientAssignments: const <String, List<String>>{
                '100 g pasta': <String>['pasta'],
              },
              recipeIngredientAmountConversions:
                  const <String, RecipeIngredientAmountConversion>{},
              sourceKeysByIngredient: const <String, String>{
                '100 g pasta': 'row-pasta',
              },
              containers: const <PreparedMealContainerInput>[
                PreparedMealContainerInput(
                  id: 'container-1',
                  label: 'Pasta',
                  totalPortions: 4,
                  finalNetWeight: 700,
                  sourceKeys: <String>['row-pasta'],
                ),
              ],
            );

        expect(result.isSuccess, isFalse);
        expect(
          result.failureReason,
          PreparedMealCreationFailureReason.mealSaveFailed,
        );
        expect(inventoryRepository.saveCount, 2);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 200);
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

      final saved = await harness.mutations().updatePreparedMealDetails(
        mealId: 'meal-1',
        name: 'Tomato Soup',
        imageChanged: true,
        imageAssetId: 'hero-new',
      );

      expect(saved, isTrue);
      expect(harness.meals.writeCount, 1);
      expect(harness.meals.meals.single.name, 'Tomato Soup');
      expect(harness.meals.meals.single.imageAssetId, 'hero-new');
    });

    test('new portions void the last pot weighing', () async {
      final rice = _measuredItem(
        id: 'rice',
        name: 'Rice',
        currentAmount: 100,
        initialAmount: 100,
        initialQuantity: 1,
      );
      final harness = _WorkflowHarness(
        meals: <PreparedMeal>[
          _meal(
            id: 'meal-1',
            name: 'Rice Bowl',
            totalPortions: 2,
            remainingPortions: 2,
            components: <PreparedMealComponent>[
              _component(item: rice, usedAmount: 100),
            ],
          ).copyWith(
            potTareWeight: 1180,
            potWeighing: PreparedMealPotWeighing(
              netWeight: 900,
              weighedAt: DateTime(2026, 4, 19),
              remainingPortions: 2,
            ),
          ),
        ],
      );

      final saved = await harness
          .mutations(inventory: _FakeInventoryItemRepository())
          .updatePreparedMealDetails(
            mealId: 'meal-1',
            name: 'Rice Bowl',
            totalPortions: 4,
            items: const <PreparedMealItemInput>[
              PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
            ],
          );

      expect(saved, isTrue);
      expect(harness.meals.meals.single.totalPortions, 4);
      expect(harness.meals.meals.single.potWeighing, isNull);
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

        final saved = await harness.mutations().updatePreparedMealDetails(
          mealId: 'meal-1',
          name: 'Soup',
          imageChanged: true,
          imageAssetId: 'hero',
        );

        expect(saved, isTrue);
        expect(harness.meals.writeCount, 0);
      },
    );

    test(
      'updatePreparedMealDetails skips inventory when only metadata changes',
      () async {
        final rice = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 100,
          initialAmount: 100,
          initialQuantity: 1,
        );
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Rice Bowl',
              totalPortions: 2,
              remainingPortions: 2,
              components: <PreparedMealComponent>[
                _component(item: rice, usedAmount: 100),
              ],
            ),
          ],
        );
        final inventoryRepository = _FakeInventoryItemRepository();

        final saved = await harness
            .mutations(inventory: inventoryRepository)
            .updatePreparedMealDetails(
              mealId: 'meal-1',
              name: 'Updated Rice Bowl',
              totalPortions: 2,
              items: const <PreparedMealItemInput>[
                PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
              ],
            );

        expect(saved, isTrue);
        // Only the read that remembers the stock for the history.
        expect(inventoryRepository.readCount, 1);
        expect(inventoryRepository.saveCount, 0);
        expect(harness.meals.meals.single.name, 'Updated Rice Bowl');
      },
    );

    test(
      'updatePreparedMealDetails reconciles edited ingredients with inventory',
      () async {
        final rice = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 100,
          initialAmount: 100,
          initialQuantity: 1,
        );
        final beans = _measuredItem(
          id: 'beans',
          name: 'Beans',
          currentAmount: 100,
          initialAmount: 100,
          initialQuantity: 1,
        );
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Rice Bowl',
              totalPortions: 2,
              remainingPortions: 2,
              totalKcal: 100,
              components: <PreparedMealComponent>[
                _component(item: rice, usedAmount: 100, totalKcal: 100),
              ],
            ),
          ],
        );
        final inventoryRepository = _FakeInventoryItemRepository(
          items: <InventoryItem>[beans],
        );

        final saved = await harness
            .mutations(inventory: inventoryRepository)
            .updatePreparedMealDetails(
              mealId: 'meal-1',
              name: 'Bean Bowl',
              totalPortions: 3,
              items: const <PreparedMealItemInput>[
                PreparedMealItemInput(itemId: 'beans', usedAmount: 90),
              ],
            );

        expect(saved, isTrue);
        expect(inventoryRepository.saveCount, 2);
        expect(
          inventoryRepository.lastSavedItems
              .singleWhere((item) => item.id == 'beans')
              .currentAmount,
          10,
        );
        expect(
          inventoryRepository.lastSavedItems
              .singleWhere((item) => item.id == 'rice')
              .currentAmount,
          100,
        );
        expect(harness.meals.meals.single.name, 'Bean Bowl');
        expect(harness.meals.meals.single.totalPortions, 3);
        expect(harness.meals.meals.single.remainingPortions, 3);
        expect(harness.meals.meals.single.components.single.name, 'Beans');
        expect(harness.meals.meals.single.totalKcal, 90);
      },
    );

    test(
      'updatePreparedMealDetails reconciles pending recipe data on edit',
      () async {
        final rice = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 100,
          initialAmount: 100,
          initialQuantity: 1,
        );
        final beans = _measuredItem(
          id: 'beans',
          name: 'Beans',
          currentAmount: 100,
          initialAmount: 100,
          initialQuantity: 1,
        );
        final harness = _WorkflowHarness(
          meals: <PreparedMeal>[
            _meal(
              id: 'meal-1',
              name: 'Rice Bowl',
              totalPortions: 2,
              remainingPortions: 2,
              recipeIngredients: const <String>['100 g rice', '50 g peas'],
              pendingRecipeIngredients: const <String>[
                '100 g rice',
                '50 g peas',
              ],
              components: <PreparedMealComponent>[
                _component(item: beans, usedAmount: 50),
              ],
            ),
          ],
        );
        final inventoryRepository = _FakeInventoryItemRepository(
          items: <InventoryItem>[rice],
        );

        final saved = await harness
            .mutations(inventory: inventoryRepository)
            .updatePreparedMealDetails(
              mealId: 'meal-1',
              name: 'Rice Bowl',
              totalPortions: 2,
              items: const <PreparedMealItemInput>[
                PreparedMealItemInput(itemId: 'beans', usedAmount: 50),
                PreparedMealItemInput(itemId: 'rice', usedAmount: 100),
              ],
            );

        expect(saved, isTrue);
        expect(
          harness.meals.meals.single.pendingRecipeIngredients,
          const <String>['50 g peas'],
        );
        expect(harness.meals.meals.single.recipeIngredients, const <String>[
          '100 g rice',
          '50 g peas',
        ]);
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

        final saved = await harness
            .mutations(inventory: inventoryRepository)
            .fillPreparedMealPendingIngredient(
              mealId: 'meal-1',
              ingredient: '100 g rice',
              inventoryItemIds: const <String>['rice'],
            );

        expect(saved, isTrue);
        expect(inventoryRepository.saveCount, 1);
        expect(inventoryRepository.lastSavedItems.single.currentAmount, 50);
        expect(harness.meals.writeCount, 1);
        expect(harness.meals.meals.single.pendingRecipeIngredients, isEmpty);
        expect(harness.meals.meals.single.components, hasLength(1));
        expect(harness.meals.meals.single.totalKcal, 100);
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

        final saved = await harness
            .mutations(inventory: _FakeInventoryItemRepository())
            .fillPreparedMealPendingIngredient(
              mealId: 'meal-1',
              ingredient: '100 g rice',
              inventoryItemIds: const <String>['   '],
            );

        expect(saved, isFalse);
        expect(harness.meals.readCount, 0);
      },
    );

    test('fillPreparedMealPendingIngredient restores inventory '
        'when meal save fails', () async {
      final harness = _WorkflowHarness(
        saveMealsResults: <bool>[false],
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

      final saved = await harness
          .mutations(inventory: inventoryRepository)
          .fillPreparedMealPendingIngredient(
            mealId: 'meal-1',
            ingredient: '100 g rice',
            inventoryItemIds: const <String>['rice'],
          );

      expect(saved, isFalse);
      expect(harness.meals.writeCount, 1);
      expect(inventoryRepository.saveCount, 2);
      expect(inventoryRepository.lastSavedItems.single.currentAmount, 150);
    });

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

      final saved = await harness
          .mutations()
          .ignorePreparedMealPendingIngredient(
            mealId: 'meal-1',
            ingredient: '100 g rice',
          );

      expect(saved, isTrue);
      expect(harness.meals.writeCount, 1);
      expect(harness.meals.meals.single.pendingRecipeIngredients, isEmpty);
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

        final saved = await harness
            .mutations(discardEvents: discardRepository)
            .throwAwayPreparedMeal(
              mealId: 'meal-1',
              discardedPortions: 1,
              reason: InventoryDiscardReason.spoiled,
            );

        expect(saved, isTrue);
        expect(harness.meals.writeCount, 1);
        expect(harness.meals.meals.single.remainingPortions, 3);
        expect(discardRepository.saveCount, 1);
        expect(discardRepository.lastSavedEvent?.sourceId, 'meal-1');
        expect(
          discardRepository.lastSavedEvent?.reason,
          InventoryDiscardReason.spoiled,
        );
      },
    );

    test('throwAwayPreparedMeal supports fractional portions', () async {
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
            remainingPortions: 2,
            components: <PreparedMealComponent>[
              _component(item: sourceItem, usedAmount: 400, totalKcal: 400),
            ],
          ),
        ],
      );
      final discardRepository = _FakeDiscardEventRepository();

      final saved = await harness
          .mutations(discardEvents: discardRepository)
          .throwAwayPreparedMeal(
            mealId: 'meal-1',
            discardedPortions: 0.5,
            reason: InventoryDiscardReason.spoiled,
          );

      expect(saved, isTrue);
      expect(harness.meals.meals.single.remainingPortions, 1.5);
      expect(discardRepository.lastSavedEvent?.discardedAmount, 0.5);
      expect(discardRepository.lastSavedEvent?.discardedValue, 0.5);
    });

    test('throwAwayPreparedMeal returns false for invalid portions', () async {
      final harness = _WorkflowHarness();
      final discardRepository = _FakeDiscardEventRepository();

      final saved = await harness
          .mutations(discardEvents: discardRepository)
          .throwAwayPreparedMeal(
            mealId: 'meal-1',
            discardedPortions: 0,
            reason: InventoryDiscardReason.spoiled,
          );

      expect(saved, isFalse);
      expect(discardRepository.saveCount, 0);
      expect(harness.meals.readCount, 0);
    });

    test('throwAwayPreparedMeal restores previous meal state '
        'when event save fails', () async {
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
      final discardRepository = _FakeDiscardEventRepository(shouldSave: false);

      final saved = await harness
          .mutations(discardEvents: discardRepository)
          .throwAwayPreparedMeal(
            mealId: 'meal-1',
            discardedPortions: 1,
            reason: InventoryDiscardReason.spoiled,
          );

      expect(saved, isFalse);
      expect(discardRepository.saveCount, 1);
      expect(harness.meals.writeCount, 2);
      expect(harness.meals.meals.single.remainingPortions, 4);
    });

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

      final saved = await harness
          .mutations(inventory: inventoryRepository)
          .unbundlePreparedMeal('meal-1');

      expect(saved, isTrue);
      expect(inventoryRepository.readCount, 1);
      expect(inventoryRepository.saveCount, 1);
      expect(inventoryRepository.lastSavedItems.single.currentAmount, 100);
      expect(harness.meals.writeCount, 1);
      expect(harness.meals.meals, isEmpty);
    });

    test(
      'weighPot stores the food in the pot with the portions left',
      () async {
        final meal = _meal(
          id: 'soup',
          name: 'Linsensuppe',
          totalPortions: 4,
          remainingPortions: 3,
          components: const <PreparedMealComponent>[],
        ).copyWith(potTareWeight: 1180, finalNetWeight: 1400);
        final harness = _WorkflowHarness(meals: [meal]);

        final weighed = await harness.mutations().weighPot(
          mealId: 'soup',
          netWeight: 990,
        );

        final stored = harness.meals.meals.single;
        expect(weighed, stored);
        expect(stored.potWeighing?.netWeight, 990);
        expect(stored.potWeighing?.remainingPortions, 3);
        expect(stored.potWeighing?.weighedAt, DateTime(2026, 4, 19));
        expect(PreparedMeal.fromJson(stored.toJson()), stored);
      },
    );

    test('weighPot refuses a meal without an empty pot weight', () async {
      final harness = _WorkflowHarness(
        meals: [
          _meal(
            id: 'soup',
            name: 'Linsensuppe',
            totalPortions: 4,
            remainingPortions: 3,
            components: const <PreparedMealComponent>[],
          ),
        ],
      );

      await expectLater(
        harness.mutations().weighPot(mealId: 'soup', netWeight: 990),
        throwsStateError,
      );
      expect(harness.meals.writeCount, 0);
    });

    test('unbundlePreparedMeal returns false when meal is missing', () async {
      final harness = _WorkflowHarness();
      final inventoryRepository = _FakeInventoryItemRepository();

      final saved = await harness
          .mutations(inventory: inventoryRepository)
          .unbundlePreparedMeal('missing');

      expect(saved, isFalse);
      // Only the read that remembers the stock for the history.
      expect(inventoryRepository.readCount, 1);
    });

    test(
      'unbundlePreparedMeal restores inventory when meal save fails',
      () async {
        final sourceItem = _measuredItem(
          id: 'rice',
          name: 'Rice',
          currentAmount: 200,
          initialAmount: 200,
          initialQuantity: 1,
        );
        final harness = _WorkflowHarness(
          saveMealsResults: <bool>[false],
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

        final saved = await harness
            .mutations(inventory: inventoryRepository)
            .unbundlePreparedMeal('meal-1');

        expect(saved, isFalse);
        expect(harness.meals.writeCount, 1);
        expect(inventoryRepository.saveCount, 2);
        expect(inventoryRepository.lastSavedItems, isEmpty);
      },
    );
  });
}

class _WorkflowHarness {
  new({List<PreparedMeal>? meals, List<bool>? saveMealsResults})
    : meals = FakePreparedMealRepository(
        meals: meals ?? const <PreparedMeal>[],
        writeResults: saveMealsResults ?? const <bool>[true],
      );

  final FakePreparedMealRepository meals;
  var _ids = 0;

  /// The creation part alone, for the template creation that only the
  /// cooking service uses.
  PreparedMealCreation creation() => PreparedMealCreation(
    writer: PreparedMealWriter(
      meals: meals,
      clock: () => DateTime(2026, 4, 19),
      logName: 'test',
      newId: () => 'generated-id',
    ),
  );

  PreparedMealMutationService mutations({
    InventoryItemRepository? inventory,
    InventoryDiscardEventRepository? discardEvents,
  }) {
    return PreparedMealMutationService(
      queue: SerializedMutationQueue(),
      meals: meals,
      inventory: inventory ?? _FakeInventoryItemRepository(),
      discardEvents: discardEvents ?? _FakeDiscardEventRepository(),
      activity: _FakeActivityRepository(),
      actor: null,
      ingredientParser: const TemplateIngredientParser(),
      clock: () => DateTime(2026, 4, 19),
      newId: () => _ids++ == 0 ? 'generated-id' : 'generated-id-$_ids',
    );
  }
}

class _FakeInventoryItemRepository with InventoryItemWholeListWrites {
  new({List<InventoryItem>? items})
    : _items = List<InventoryItem>.from(items ?? const <InventoryItem>[]);

  final List<InventoryItem> _items;
  int readCount = 0;
  int saveCount = 0;
  List<InventoryItem> lastSavedItems = const <InventoryItem>[];

  /// An item that another device writes right after this one's first write.
  InventoryItem? writtenByOtherDevice;

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
  Future<List<InventoryItem>> storedItems() async =>
      List<InventoryItem>.from(_items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    saveCount += 1;
    lastSavedItems = List<InventoryItem>.from(items);
    _items
      ..clear()
      ..addAll(items);
    final other = writtenByOtherDevice;
    if (other != null) {
      writtenByOtherDevice = null;
      _items.add(other);
    }
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    _items.addAll(items);
    return true;
  }
}

class _FakeActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 0}) =>
      const Stream<List<InventoryActivityEvent>>.empty();

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}

class _FakeDiscardEventRepository implements InventoryDiscardEventRepository {
  new({this.shouldSave = true});

  final bool shouldSave;
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
    return shouldSave;
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
  required num remainingPortions,
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
