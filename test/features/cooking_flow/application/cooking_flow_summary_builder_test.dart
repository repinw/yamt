import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_builder.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_ingredient_parser.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';

void main() {
  group('parseCookingFlowIngredient', () {
    test('keeps German piece units out of the ingredient name', () {
      final cases = <String>['2 stück Apfel', '2 stueck Apfel'];

      for (final value in cases) {
        final ingredient = parseCookingFlowIngredient(value);

        expect(ingredient?.name, 'Apfel');
      }
    });

    test('keeps English piece units out of the ingredient name', () {
      final ingredient = parseCookingFlowIngredient(
        '2 pieces apple',
        localeCode: 'en',
      );

      expect(ingredient?.name, 'apple');
    });

    test('keeps the EL unit label when scaling a spoon-measured amount', () {
      final ingredient = parseCookingFlowIngredient(
        '4 EL Milch (oder Sahne)',
        selectedPortions: 2,
        localeCode: 'de',
      );

      // Regression: this used to collapse to a bare "8" that got
      // misinterpreted downstream as 8 pieces instead of 8 tablespoons.
      expect(ingredient?.amountLabel, '8 EL');
      expect(ingredient?.name, 'Milch (oder Sahne)');
    });
  });

  group('parseCookingFlowIngredientRequirement', () {
    test('normalizes German piece units', () {
      final cases = <String>['2 stück', '2 stueck'];

      for (final value in cases) {
        final requirement = parseCookingFlowIngredientRequirement(value);

        expect(requirement?.amount, 2);
        expect(requirement?.unitCode, cookingFlowPieceUnitCode);
      }
    });

    test('strips package count prefix without whitespace', () {
      final requirement = parseCookingFlowIngredientRequirement('2x500g');

      expect(requirement?.amount, 500);
      expect(requirement?.unitCode, 'g');
    });

    test('parses German thousands and decimal separators', () {
      final requirement = parseCookingFlowIngredientRequirement('1.000,50 g');

      expect(requirement?.amount, 1000.5);
      expect(requirement?.unitCode, 'g');
    });

    test('normalizes English piece units', () {
      final requirement = parseCookingFlowIngredientRequirement(
        '2 pieces',
        localeCode: 'en',
      );

      expect(requirement?.amount, 2);
      expect(requirement?.unitCode, cookingFlowPieceUnitCode);
    });
  });

  group('piece-tracked stock', () {
    test('defaults an extra ingredient to its whole pieces', () {
      expect(defaultCookingFlowSummaryAmountForItem(_eggPack()), '10');
    });

    test('adjust-template row uses the available pieces', () {
      final rows = buildCookingFlowSummaryIngredientsFromIntro(
        template: _template(recipeIngredients: const <String>['12 Eier']),
        inventoryItems: <InventoryItem>[_eggPack()],
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '12 Eier',
              action: CookingFlowIntroRowAction.assigned,
              conflictResolution:
                  CookingFlowIntroConflictResolution.adjustTemplate,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'eggs'),
              ],
            ),
          ],
        ),
        targetPortions: 1,
        localeCode: 'de',
      );

      expect(rows.single.amount, '10');
      expect(rows.single.unitCode, cookingFlowPieceUnitCode);
    });
  });

  group('spoon-measured amounts assigned to gram-tracked stock', () {
    test('deducts in grams once the unit conflict is resolved', () {
      final rows = buildCookingFlowSummaryIngredientsFromIntro(
        template: _template(
          recipeIngredients: const <String>['4 EL Milch (oder Sahne)'],
        ),
        inventoryItems: <InventoryItem>[
          InventoryItem.create(
            id: 'milk',
            name: 'Milch',
            entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
            storeName: 'Test',
            quantity: 1,
            initialAmount: 1000,
            currentAmount: 1000,
            amountUnit: InventoryAmountUnit.gram,
          ),
        ],
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '4 EL Milch (oder Sahne)',
              action: CookingFlowIntroRowAction.assigned,
              // The user resolved the EL-vs-gram conflict on the intro
              // screen (15 g per EL default), which edits the row's amount.
              editedAmountLabel: '120 g',
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'milk'),
              ],
            ),
          ],
        ),
        targetPortions: 2,
        localeCode: 'de',
      );

      expect(rows.single.amount, '120');
      expect(rows.single.unitCode, 'g');
    });
  });
}

InventoryItem _eggPack() {
  const storedAmount = 10 * inventoryPieceAmountScale;
  return InventoryItem.create(
    id: 'eggs',
    name: 'Eier',
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: storedAmount,
    currentAmount: storedAmount,
    amountScale: inventoryPieceAmountScale,
    amountUnit: InventoryAmountUnit.piece,
  );
}

PreparedMeal _template({required List<String> recipeIngredients}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Omelett',
    recipeIngredients: recipeIngredients,
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}
