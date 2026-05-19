import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_inventory.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('shows empty ingredient message for templates without rows', (
    tester,
  ) async {
    var latestSelectionState = const CookingFlowIntroSelectionState(
      allItemsSelected: true,
      hasShoppingSelections: false,
      hasUnresolvedConflicts: false,
      shoppingListLabels: <String>[],
      draft: CookingFlowIntroDraft(),
    );

    await tester.pumpWidget(
      _harness(
        template: _template(recipeIngredients: const <String>[]),
        onSelectionStateChanged: (state) {
          latestSelectionState = state;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Inventory check'), findsOneWidget);
    expect(find.text('No ingredients available.'), findsOneWidget);
    expect(latestSelectionState.allItemsSelected, isTrue);
  });

  testWidgets('shows reset action when restored draft has selections', (
    tester,
  ) async {
    var restartCount = 0;

    await tester.pumpWidget(
      _harness(
        template: _template(recipeIngredients: const <String>['500g Flour']),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'flour', name: 'Flour'),
        ],
        shoppingBaselineInventoryItemIds: const <String>['old-flour'],
        initialDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500g Flour',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'flour'),
              ],
            ),
          ],
        ),
        onRestartPressed: () async {
          restartCount += 1;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Reset'));
    await tester.pump();

    expect(restartCount, 1);
  });

  testWidgets('shopping and ignore actions update selection state', (
    tester,
  ) async {
    var latestSelectionState = const CookingFlowIntroSelectionState(
      allItemsSelected: false,
      hasShoppingSelections: false,
      hasUnresolvedConflicts: false,
      shoppingListLabels: <String>[],
      draft: CookingFlowIntroDraft(),
    );

    await tester.pumpWidget(
      _harness(
        template: _template(
          recipeIngredients: const <String>['500g Flour', '2 Eggs'],
        ),
        onSelectionStateChanged: (state) {
          latestSelectionState = state;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Shopping cart').first);
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Ignore').last);
    await tester.tap(find.byTooltip('Ignore').last);
    await tester.pump();

    expect(latestSelectionState.allItemsSelected, isTrue);
    expect(latestSelectionState.hasShoppingSelections, isTrue);
    expect(latestSelectionState.shoppingListLabels, <String>[
      '500 g Flour',
    ]);
  });

  testWidgets('assign sheet clears matching shopping labels', (tester) async {
    var latestSelectionState = const CookingFlowIntroSelectionState(
      allItemsSelected: false,
      hasShoppingSelections: false,
      hasUnresolvedConflicts: false,
      shoppingListLabels: <String>[],
      draft: CookingFlowIntroDraft(),
    );
    var resolvedLabels = const <String>[];

    await tester.pumpWidget(
      _harness(
        template: _template(recipeIngredients: const <String>['500g Flour']),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'flour', name: 'Flour'),
        ],
        shoppingBaselineInventoryItemIds: const <String>['old-flour'],
        initialDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500g Flour',
              action: CookingFlowIntroRowAction.shoppingCart,
            ),
          ],
        ),
        onShoppingLabelsResolved: (labels) async {
          resolvedLabels = labels;
        },
        onSelectionStateChanged: (state) {
          latestSelectionState = state;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Assign'));
    await tester.pumpAndSettle();
    expect(find.text('Choose inventory'), findsOneWidget);

    await tester.tap(find.text('Flour').last);
    await tester.pump();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(resolvedLabels, <String>['500 g Flour']);
    expect(latestSelectionState.allItemsSelected, isTrue);
    expect(latestSelectionState.hasShoppingSelections, isFalse);
  });

  testWidgets('suggested inventory item can be applied', (tester) async {
    var latestSelectionState = const CookingFlowIntroSelectionState(
      allItemsSelected: false,
      hasShoppingSelections: false,
      hasUnresolvedConflicts: false,
      shoppingListLabels: <String>[],
      draft: CookingFlowIntroDraft(),
    );

    await tester.pumpWidget(
      _harness(
        template: _template(recipeIngredients: const <String>['500g Flour']),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'flour', name: 'Flour'),
        ],
        shoppingBaselineInventoryItemIds: const <String>['old-flour'],
        initialDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500g Flour',
              action: CookingFlowIntroRowAction.shoppingCart,
            ),
          ],
        ),
        onSelectionStateChanged: (state) {
          latestSelectionState = state;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Found a new inventory match.'), findsOneWidget);

    await tester.tap(find.text('Apply'));
    await tester.pump();

    final rowState = latestSelectionState.draft.rowStates.single;
    expect(rowState.action, CookingFlowIntroRowAction.assigned);
    expect(rowState.selections.single.itemId, 'flour');
  });

  testWidgets('shortage resolution clears unresolved conflict flag', (
    tester,
  ) async {
    var latestSelectionState = const CookingFlowIntroSelectionState(
      allItemsSelected: false,
      hasShoppingSelections: false,
      hasUnresolvedConflicts: false,
      shoppingListLabels: <String>[],
      draft: CookingFlowIntroDraft(),
    );

    await tester.pumpWidget(
      _harness(
        template: _template(recipeIngredients: const <String>['500g Flour']),
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'flour',
            name: 'Flour',
            currentAmount: 100,
          ),
        ],
        initialDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500g Flour',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'flour'),
              ],
            ),
          ],
        ),
        onSelectionStateChanged: (state) {
          latestSelectionState = state;
        },
      ),
    );
    await tester.pump();

    expect(find.textContaining('Not enough in inventory'), findsOneWidget);
    expect(latestSelectionState.hasUnresolvedConflicts, isTrue);

    await tester.tap(find.text('BUY REMAINDER'));
    await tester.pump();

    expect(latestSelectionState.hasUnresolvedConflicts, isFalse);
    expect(
      latestSelectionState.draft.rowStates.single.conflictResolution,
      CookingFlowIntroConflictResolution.buyRemaining,
    );
  });
}

Widget _harness({
  required PreparedMeal template,
  int targetPortions = 4,
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  CookingFlowIntroDraft? initialDraft,
  List<String> shoppingBaselineInventoryItemIds = const <String>[],
  Future<void> Function()? onRestartPressed,
  Future<void> Function(List<String> labels)? onShoppingLabelsResolved,
  ValueChanged<CookingFlowIntroSelectionState>? onSelectionStateChanged,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CookingFlowInventoryCheckCard(
            template: template,
            targetPortions: targetPortions,
            inventoryItems: inventoryItems,
            localeCode: 'en',
            initialDraft: initialDraft,
            shoppingBaselineInventoryItemIds: shoppingBaselineInventoryItemIds,
            resetSignal: 0,
            onRestartPressed: onRestartPressed ?? () async {},
            onShoppingLabelsResolved: onShoppingLabelsResolved ?? (_) async {},
            onSelectionStateChanged: onSelectionStateChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

PreparedMeal _template({required List<String> recipeIngredients}) {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Test meal',
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

InventoryItem _inventoryItem({
  required String id,
  required String name,
  int currentAmount = 500,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: 500,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
  );
}
