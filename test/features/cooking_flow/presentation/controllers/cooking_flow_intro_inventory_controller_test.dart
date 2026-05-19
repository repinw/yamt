import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_intro_inventory_controller.dart';
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

  test('sync builds rows from prepared meal components and scales amounts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .sync(
          CookingFlowIntroInventoryInput(
            template: _template(
              recipeIngredients: const <String>[],
              components: <PreparedMealComponent>[
                _component(name: 'Rice', usedAmount: 200),
              ],
            ),
            targetPortions: 2,
            localeCode: 'en',
            initialDraft: null,
          ),
        );

    final row = container
        .read(cookingFlowIntroInventoryControllerProvider)
        .rows
        .single;
    expect(row.rawIngredient, '200g Rice');
    expect(row.name, 'Rice');
    expect(row.amountLabel, '100g');
    expect(row.imageUrl, 'https://example.test/rice.png');
  });

  test('sync applies edited row data from initial draft', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(cookingFlowIntroInventoryControllerProvider.notifier)
        .sync(
          CookingFlowIntroInventoryInput(
            template: _template(
              recipeIngredients: const <String>['500g Rice'],
            ),
            targetPortions: 4,
            localeCode: 'en',
            initialDraft: const CookingFlowIntroDraft(
              rowStates: <CookingFlowIntroRowDraft>[
                CookingFlowIntroRowDraft(
                  rawIngredient: '500g Rice',
                  action: CookingFlowIntroRowAction.assigned,
                  editedName: 'Brown rice',
                  editedAmountLabel: '450 g',
                  selections: <CookingFlowIntroSelectionDraft>[
                    CookingFlowIntroSelectionDraft(itemId: 'rice'),
                  ],
                  conflictResolution:
                      CookingFlowIntroConflictResolution.adjustTemplate,
                ),
              ],
            ),
          ),
        );

    final state = container.read(cookingFlowIntroInventoryControllerProvider);
    expect(state.rows.single.name, 'Brown rice');
    expect(state.rows.single.amountLabel, '450 g');
    expect(state.rows.single.isEdited, isTrue);
    expect(
      state.selectedActions.single,
      CookingFlowInventoryRowAction.assigned,
    );
    expect(state.selectedInventorySelections.single.single.itemId, 'rice');
    expect(
      state.conflictResolutions.single,
      CookingFlowInventoryConflictResolution.adjustTemplate,
    );
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

  test('weighUnitConflictLater records zero amount in selected unit', () {
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
      )
      ..weighUnitConflictLater(index: 0, inventoryItems: inventoryItems);

    final state = container.read(cookingFlowIntroInventoryControllerProvider);
    expect(state.rows.single.amountLabel, '0 g');
    expect(state.rows.single.isEdited, isTrue);
    expect(
      state.conflictResolutions.single,
      CookingFlowInventoryConflictResolution.weighLater,
    );
  });

  test('selectAction clears assigned selections and conflict resolution', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final sync = notifier.sync;
    final setInventorySelections = notifier.setInventorySelections;
    final setConflictResolution = notifier.setConflictResolution;
    final selectAction = notifier.selectAction;

    sync(
      CookingFlowIntroInventoryInput(
        template: _template(recipeIngredients: const <String>['500g Mehl']),
        targetPortions: 4,
        localeCode: 'de',
        initialDraft: null,
      ),
    );
    setInventorySelections(
      index: 0,
      selections: const <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: 'flour'),
      ],
    );
    setConflictResolution(
      index: 0,
      resolution: CookingFlowInventoryConflictResolution.buyRemaining,
    );
    selectAction(0, CookingFlowInventoryRowAction.ignored);

    final state = container.read(cookingFlowIntroInventoryControllerProvider);
    expect(state.selectedActions.single, CookingFlowInventoryRowAction.ignored);
    expect(state.selectedInventorySelections.single, isEmpty);
    expect(state.conflictResolutions.single, isNull);
  });

  test('applySuggestedInventoryItem appends to existing assignment', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final sync = notifier.sync;
    final setInventorySelections = notifier.setInventorySelections;
    final applySuggestedInventoryItem = notifier.applySuggestedInventoryItem;

    sync(
      CookingFlowIntroInventoryInput(
        template: _template(recipeIngredients: const <String>['500g Mehl']),
        targetPortions: 4,
        localeCode: 'de',
        initialDraft: null,
      ),
    );
    setInventorySelections(
      index: 0,
      selections: const <CookingFlowInventoryAssignmentSelection>[
        CookingFlowInventoryAssignmentSelection(itemId: 'flour-old'),
      ],
    );
    applySuggestedInventoryItem(index: 0, itemId: 'flour-new');

    final selections = container
        .read(cookingFlowIntroInventoryControllerProvider)
        .selectedInventorySelections
        .single;
    expect(selections.map((selection) => selection.itemId), <String>[
      'flour-old',
      'flour-new',
    ]);
  });

  test('suggestedInventoryItem skips baseline and selected items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      cookingFlowIntroInventoryControllerProvider.notifier,
    );
    final inventoryItems = <InventoryItem>[
      _amountItem(id: 'baseline-flour', name: 'Mehl', currentAmount: 500),
      _amountItem(id: 'selected-flour', name: 'Mehl', currentAmount: 500),
      _amountItem(id: 'new-flour', name: 'Mehl Type 550', currentAmount: 500),
    ];

    notifier
      ..sync(
        CookingFlowIntroInventoryInput(
          template: _template(recipeIngredients: const <String>['500g Mehl']),
          targetPortions: 4,
          localeCode: 'de',
          initialDraft: null,
        ),
      )
      ..setInventorySelections(
        index: 0,
        selections: const <CookingFlowInventoryAssignmentSelection>[
          CookingFlowInventoryAssignmentSelection(itemId: 'selected-flour'),
        ],
      )
      ..setConflictResolution(
        index: 0,
        resolution: CookingFlowInventoryConflictResolution.buyRemaining,
      );

    final suggestedItem = notifier.suggestedInventoryItem(
      index: 0,
      baselineInventoryItemIds: const <String>['baseline-flour'],
      inventoryItems: inventoryItems,
    );

    expect(suggestedItem?.id, 'new-flour');
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
  List<PreparedMealComponent> components = const <PreparedMealComponent>[],
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
    components: components,
  );
}

PreparedMealComponent _component({
  required String name,
  required int usedAmount,
}) {
  return PreparedMealComponent(
    inventoryItemId: 'source-$name',
    name: name,
    brand: null,
    imageUrl: null,
    usedAmount: usedAmount,
    usedUnit: InventoryAmountUnit.gram,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    sourceItemSnapshot: InventoryItem.create(
      id: 'source-$name',
      name: name,
      entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
      storeName: 'Test',
      quantity: 1,
      initialAmount: usedAmount,
      currentAmount: usedAmount,
      amountUnit: InventoryAmountUnit.gram,
      imageUrl: 'https://example.test/rice.png',
    ),
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
