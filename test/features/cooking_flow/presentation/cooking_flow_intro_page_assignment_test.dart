import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  test('formats amount labels from tracked amount or quantity', () {
    final gramItem = _item(
      id: 'grams',
      name: 'Mehl',
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    final quantityItem = _item(id: 'pieces', name: 'Dose', quantity: 3);

    expect(cookingFlowInventoryAmountLabel(gramItem), '500 g');
    expect(cookingFlowInventoryAmountLabel(quantityItem), '3x');
  });

  test('maps inventory assignment selections to session drafts', () {
    const selection = CookingFlowInventoryAssignmentSelection(
      itemId: 'item-1',
      isAdditionalIngredient: true,
    );

    final draft = cookingFlowSessionIntroSelectionDraft(selection);
    final restored = cookingFlowInventoryAssignmentSelection(draft);

    expect(draft.itemId, 'item-1');
    expect(draft.isAdditionalIngredient, isTrue);
    expect(restored.itemId, 'item-1');
    expect(restored.isAdditionalIngredient, isTrue);
  });

  test('maps row actions in both directions', () {
    expect(
      cookingFlowInventoryRowAction(CookingFlowIntroRowAction.assigned),
      CookingFlowInventoryRowAction.assigned,
    );
    expect(
      cookingFlowInventoryRowAction(CookingFlowIntroRowAction.shoppingCart),
      CookingFlowInventoryRowAction.shoppingCart,
    );
    expect(
      cookingFlowInventoryRowAction(CookingFlowIntroRowAction.ignored),
      CookingFlowInventoryRowAction.ignored,
    );
    expect(cookingFlowInventoryRowAction(null), isNull);
    expect(
      cookingFlowSessionIntroRowAction(
        CookingFlowInventoryRowAction.assigned,
      ),
      CookingFlowIntroRowAction.assigned,
    );
    expect(
      cookingFlowSessionIntroRowAction(
        CookingFlowInventoryRowAction.shoppingCart,
      ),
      CookingFlowIntroRowAction.shoppingCart,
    );
    expect(
      cookingFlowSessionIntroRowAction(CookingFlowInventoryRowAction.ignored),
      CookingFlowIntroRowAction.ignored,
    );
    expect(cookingFlowSessionIntroRowAction(null), isNull);
  });

  test('maps conflict resolutions in both directions', () {
    expect(
      cookingFlowInventoryConflictResolution(
        CookingFlowIntroConflictResolution.buyRemaining,
      ),
      CookingFlowInventoryConflictResolution.buyRemaining,
    );
    expect(
      cookingFlowInventoryConflictResolution(
        CookingFlowIntroConflictResolution.adjustTemplate,
      ),
      CookingFlowInventoryConflictResolution.adjustTemplate,
    );
    expect(
      cookingFlowInventoryConflictResolution(
        CookingFlowIntroConflictResolution.weighLater,
      ),
      CookingFlowInventoryConflictResolution.weighLater,
    );
    expect(cookingFlowInventoryConflictResolution(null), isNull);
    expect(
      cookingFlowSessionConflictResolution(
        CookingFlowInventoryConflictResolution.buyRemaining,
      ),
      CookingFlowIntroConflictResolution.buyRemaining,
    );
    expect(
      cookingFlowSessionConflictResolution(
        CookingFlowInventoryConflictResolution.adjustTemplate,
      ),
      CookingFlowIntroConflictResolution.adjustTemplate,
    );
    expect(
      cookingFlowSessionConflictResolution(
        CookingFlowInventoryConflictResolution.weighLater,
      ),
      CookingFlowIntroConflictResolution.weighLater,
    );
    expect(cookingFlowSessionConflictResolution(null), isNull);
  });

  test('row data copyWith preserves immutable source fields', () {
    const row = CookingFlowInventoryCheckRowData(
      rawIngredient: '2 stueck Apfel',
      name: 'Apfel',
      amountLabel: '2 stueck',
      imageUrl: 'https://example.test/apple.png',
    );

    final updated = row.copyWith(
      name: 'Roter Apfel',
      amountLabel: '3 stück',
      isEdited: true,
    );

    expect(updated.rawIngredient, '2 stueck Apfel');
    expect(updated.name, 'Roter Apfel');
    expect(updated.amountLabel, '3 stück');
    expect(updated.isEdited, isTrue);
    expect(updated.imageUrl, row.imageUrl);
  });

  test('splits amount labels after package prefixes', () {
    expect(
      cookingFlowSplitIngredientAmountLabel('2x 300 g'),
      (amount: '300', unit: 'g'),
    );
    expect(
      cookingFlowSplitIngredientAmountLabel('2x300 g'),
      (amount: '300', unit: 'g'),
    );
    expect(
      cookingFlowSplitIngredientAmountLabel('1,5 stück'),
      (amount: '1,5', unit: 'stück'),
    );
    expect(
      cookingFlowSplitIngredientAmountLabel('nach Geschmack'),
      (amount: 'nach Geschmack', unit: ''),
    );
  });

  test('builds shopping list labels and strips package prefixes', () {
    expect(
      cookingFlowShoppingListLabelForRow(
        const CookingFlowInventoryCheckRowData(
          rawIngredient: '2x 300 g Mehl',
          name: 'Mehl',
          amountLabel: '300 g',
        ),
      ),
      '300 g Mehl',
    );
    expect(
      cookingFlowShoppingListLabelForRow(
        const CookingFlowInventoryCheckRowData(
          rawIngredient: 'Salz',
          name: 'Salz',
          amountLabel: '',
        ),
      ),
      'Salz',
    );
    expect(cookingFlowStripInventoryPackageCountPrefix('2x 500 g'), '500 g');
    expect(cookingFlowStripInventoryPackageCountPrefix('2x500 g'), '500 g');
  });

  test('known unit pattern includes German piece spellings', () {
    final unitPattern = RegExp('^(?:$cookingFlowKnownAmountUnitsPattern)\$');

    expect(unitPattern.hasMatch('stück'), isTrue);
    expect(unitPattern.hasMatch('stueck'), isTrue);
    expect(cookingFlowPieceUnitCode, 'pc');
  });

  testWidgets('assignment sheet returns selected inventory item', (
    tester,
  ) async {
    final l10n = await _loadGermanLocalizations();
    List<CookingFlowInventoryAssignmentSelection>? result;

    await tester.pumpWidget(
      _harness(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCookingFlowInventoryAssignmentSheet(
                  context: context,
                  ingredient: 'Mehl',
                  inventoryItems: <InventoryItem>[
                    _item(
                      id: 'flour',
                      name: 'Mehl',
                      currentAmount: 500,
                      amountUnit: InventoryAmountUnit.gram,
                    ),
                  ],
                  localeCode: 'de',
                  initialSelections:
                      const <CookingFlowInventoryAssignmentSelection>[],
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.cookflowInventorySelectionTitle), findsOneWidget);
    expect(find.text('Mehl'), findsWidgets);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cookflowInventorySelectionSaveButton));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result!.single.itemId, 'flour');
    expect(result!.single.isAdditionalIngredient, isFalse);
  });

  testWidgets('assignment sheet adds manual inventory selection', (
    tester,
  ) async {
    final l10n = await _loadGermanLocalizations();
    List<CookingFlowInventoryAssignmentSelection>? result;

    await tester.pumpWidget(
      _harness(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCookingFlowInventoryAssignmentSheet(
                  context: context,
                  ingredient: 'Sauce',
                  inventoryItems: <InventoryItem>[
                    _item(id: 'tomato', name: 'Tomaten'),
                    _item(id: 'zucchini', name: 'Zucchini'),
                  ],
                  localeCode: 'de',
                  initialSelections:
                      const <CookingFlowInventoryAssignmentSelection>[],
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cookflowInventorySelectionAddIngredient));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomaten').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cookflowInventorySelectionAddConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.cookflowInventorySelectionWeightLater),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.cookflowInventorySelectionSaveButton));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result!.single.itemId, 'tomato');
    expect(result!.single.isAdditionalIngredient, isTrue);
  });

  testWidgets('ingredient edit sheet returns edited row', (tester) async {
    final l10n = await _loadGermanLocalizations();
    CookingFlowInventoryCheckRowData? result;

    await tester.pumpWidget(
      _harness(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCookingFlowIngredientEditSheet(
                  context: context,
                  row: const CookingFlowInventoryCheckRowData(
                    rawIngredient: '2x 300 g Mehl',
                    name: 'Mehl',
                    amountLabel: '2x 300 g',
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.cookflowEditIngredientTitle), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Dinkelmehl');
    await tester.enterText(find.byType(TextFormField).at(1), '350');
    await tester.enterText(find.byType(TextFormField).at(2), 'g');
    await tester.tap(find.text(l10n.cookflowEditIngredientSaveAction));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.rawIngredient, '2x 300 g Mehl');
    expect(result!.name, 'Dinkelmehl');
    expect(result!.amountLabel, '350 g');
    expect(result!.isEdited, isTrue);
  });

  testWidgets('ingredient edit sheet validates required fields', (
    tester,
  ) async {
    final l10n = await _loadGermanLocalizations();
    CookingFlowInventoryCheckRowData? result;

    await tester.pumpWidget(
      _harness(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCookingFlowIngredientEditSheet(
                  context: context,
                  row: const CookingFlowInventoryCheckRowData(
                    rawIngredient: '2x 300 g Mehl',
                    name: 'Mehl',
                    amountLabel: '2x 300 g',
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.tap(find.text(l10n.cookflowEditIngredientSaveAction));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text(l10n.cookflowEditIngredientTitle), findsOneWidget);
    expect(
      find.text(l10n.cookflowEditIngredientRequiredField),
      findsNWidgets(2),
    );
  });
}

Future<AppLocalizations> _loadGermanLocalizations() {
  return AppLocalizations.delegate.load(const Locale('de'));
}

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

InventoryItem _item({
  required String id,
  required String name,
  int quantity = 1,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026),
    storeName: 'Store',
    quantity: quantity,
    initialAmount: currentAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
  );
}
