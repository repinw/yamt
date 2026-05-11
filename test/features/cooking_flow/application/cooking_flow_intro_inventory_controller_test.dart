import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_controller.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  test('sync parses localized piece ingredient rows', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .sync(
          CookingFlowIntroInventoryInput(
            template: _template(
              recipeIngredients: const <String>['2 stueck Apfel'],
            ),
            targetPortions: 4,
            localeCode: 'de',
            initialDraft: null,
          ),
        );

    final row = container
        .read(cookingFlowIntroInventoryControllerProvider)
        .rows
        .single;
    expect(row.name, 'Apfel');
    expect(row.amountLabel, '2 stueck');
  });

  test(
    'resolves shopping label when assignment covers previous shopping row',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        cookingFlowIntroInventoryControllerProvider.notifier,
      );
      final inventoryItems = <InventoryItem>[
        _amountItem(id: 'flour', name: 'Mehl', currentAmount: 500),
      ];

      notifier.sync(
        CookingFlowIntroInventoryInput(
          template: _template(recipeIngredients: const <String>['500g Mehl']),
          targetPortions: 4,
          localeCode: 'de',
          initialDraft: const CookingFlowIntroDraft(
            rowStates: <CookingFlowIntroRowDraft>[
              CookingFlowIntroRowDraft(
                rawIngredient: '500g Mehl',
                action: CookingFlowIntroRowAction.shoppingCart,
              ),
            ],
          ),
        ),
      );

      final resolvedLabels = notifier.shoppingLabelsResolvedByAssignment(
        index: 0,
        nextSelections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'flour'),
        ],
        inventoryItems: inventoryItems,
      );
      notifier.setInventorySelections(
        index: 0,
        selections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'flour'),
        ],
      );

      expect(resolvedLabels, <String>['500 g Mehl']);
      expect(notifier.currentShoppingListLabels(inventoryItems), isEmpty);
      expect(notifier.selectionState(inventoryItems).allItemsSelected, isTrue);
    },
  );

  test('converts piece conflict into selected amount unit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final inventoryItems = <InventoryItem>[
      _amountItem(id: 'eggs', name: 'Eier', currentAmount: 120),
    ];

    notifier
      ..sync(
        CookingFlowIntroInventoryInput(
          template: _template(recipeIngredients: const <String>['2 Eier']),
          targetPortions: 4,
          localeCode: 'de',
          initialDraft: null,
        ),
      )
      ..setInventorySelections(
        index: 0,
        selections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'eggs'),
        ],
      );

    expect(
      notifier.conflictForIndex(0, inventoryItems)?.kind,
      CookingFlowInventoryConflictKind.unitConversion,
    );
    notifier.convertUnitConflict(
      index: 0,
      amountPerPiece: 60,
      inventoryItems: inventoryItems,
    );

    final row = container
        .read(cookingFlowIntroInventoryControllerProvider)
        .rows
        .single;
    expect(row.amountLabel, '120 g');
    expect(notifier.conflictForIndex(0, inventoryItems), isNull);
  });

  test('convertUnitConflict preserves decimal math in row state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final inventoryItems = <InventoryItem>[
      _amountItem(id: 'onions', name: 'Zwiebeln', currentAmount: 100),
    ];

    notifier
      ..sync(
        CookingFlowIntroInventoryInput(
          template: _template(
            recipeIngredients: const <String>['1,5 Stück Zwiebeln'],
          ),
          targetPortions: 4,
          localeCode: 'de',
          initialDraft: null,
        ),
      )
      ..setInventorySelections(
        index: 0,
        selections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'onions'),
        ],
      )
      ..convertUnitConflict(
        index: 0,
        amountPerPiece: 33.3,
        inventoryItems: inventoryItems,
      );

    final row = container
        .read(cookingFlowIntroInventoryControllerProvider)
        .rows
        .single;
    expect(row.amountLabel, '49.95 g');
    expect(row.isEdited, isTrue);
  });
}

PreparedMeal _template({
  required List<String> recipeIngredients,
}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Testgericht',
    recipeIngredients: recipeIngredients,
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

InventoryItem _amountItem({
  required String id,
  required String name,
  required int currentAmount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: currentAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
  );
}
