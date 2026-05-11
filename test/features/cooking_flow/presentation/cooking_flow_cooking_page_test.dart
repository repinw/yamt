import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_cooking_page.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this._items);

  final List<InventoryItem> _items;

  @override
  FutureOr<List<InventoryItem>> build() {
    return List.of(_items);
  }
}

PreparedMeal _template({
  List<String> recipeIngredients = const <String>[],
  List<String> recipeInstructions = const <String>[],
}) {
  return PreparedMeal(
    id: 'template-1',
    name: 'Herzhafter Linseneintopf',
    recipeIngredients: recipeIngredients,
    recipeInstructions: recipeInstructions,
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

Widget _buildHarness({
  required PreparedMeal template,
  required TextEditingController adjustmentController,
  CookingFlowIntroDraft? introDraft,
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(inventoryItems),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CookingFlowCookingPage(
          template: template,
          introDraft: introDraft,
          adjustmentController: adjustmentController,
          adjustments: const <String>[],
          onAddPressed: () {},
          onRemovePressed: (_) {},
        ),
      ),
    ),
  );
}

Future<void> _pumpInstructionSteps(WidgetTester tester) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
}

InventoryItem _inventoryItem({
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

InventoryItem _quantityInventoryItem({
  required String id,
  required String name,
  required int quantity,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: quantity,
  );
}

void main() {
  test('uses isolate path for very long recipes', () {
    final longInstruction = List<String>.filled(1001, 'x').join();

    final shouldUseIsolate = shouldBuildCookingInstructionStepsOffMain(
      template: _template(
        recipeIngredients: const <String>['300g Linsen'],
        recipeInstructions: <String>[longInstruction],
      ),
      inventoryItems: const <InventoryItem>[],
    );

    expect(shouldUseIsolate, isTrue);
  });

  testWidgets('renders stored template recipe instructions', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeInstructions: const <String>[
            'Wasche die Linsen gründlich.',
            'Koche alles 45 Minuten.',
          ],
        ),
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(find.textContaining('Wasche die Linsen'), findsOneWidget);
    expect(find.textContaining('Koche alles 45 Minuten'), findsOneWidget);
  });

  testWidgets('falls back to ingredient summary when steps missing', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            '300g Linsen',
            '500g Kartoffeln',
          ],
        ),
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(find.textContaining('Bereite die Zutaten vor:'), findsOneWidget);
    expect(find.textContaining('300 g Linsen'), findsOneWidget);
    expect(find.textContaining('500 g Kartoffeln'), findsOneWidget);
  });

  testWidgets('uses selected inventory weight for piece ingredients', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            '2 Zwiebeln',
            'Hackfleisch',
          ],
          recipeInstructions: const <String>[
            'Zwiebeln und Hackfleisch anbraten.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 Zwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
            CookingFlowIntroRowDraft(
              rawIngredient: 'Hackfleisch',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'mince'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'onions', name: 'Zwiebeln', currentAmount: 180),
          _inventoryItem(id: 'mince', name: 'Hackfleisch', currentAmount: 400),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('Zwiebeln (180g)', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Hackfleisch (400g)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('matches raw ingredient text inside instructions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            '500 g Hackfleisch',
            '2 Zwiebeln',
          ],
          recipeInstructions: const <String>[
            '500g Hackfleisch und 2 Zwiebeln anbraten.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500 g Hackfleisch',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'mince'),
              ],
            ),
            CookingFlowIntroRowDraft(
              rawIngredient: '2 Zwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'mince', name: 'Hackfleisch', currentAmount: 400),
          _inventoryItem(id: 'onions', name: 'Zwiebeln', currentAmount: 180),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('500g Hackfleisch', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('2 Zwiebeln (180g)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('matches German piece unit inside instructions', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            '2 stück Zwiebeln',
          ],
          recipeInstructions: const <String>[
            '2 stück Zwiebeln anbraten.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 stück Zwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'onions', name: 'Zwiebeln', currentAmount: 180),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('2 stück Zwiebeln (180g)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('uses English parser data for instruction matching', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        locale: const Locale('en'),
        template: _template(
          recipeIngredients: const <String>[
            '2 pieces onions',
          ],
          recipeInstructions: const <String>[
            'Add the onions to the pan.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 pieces onions',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _quantityInventoryItem(
            id: 'onions',
            name: 'onions',
            quantity: 2,
          ),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('onions (2 pieces)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('fuzzy matches imported ingredient aliases', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            'm.-große Zwiebeln',
          ],
          recipeInstructions: const <String>[
            'Die Zwiebeln abziehen.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: 'm.-große Zwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _quantityInventoryItem(
            id: 'onions',
            name: 'Zwiebeln',
            quantity: 2,
          ),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('Zwiebeln (2)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('parses embedded imported package weights in instructions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            'gr Dose/n Tomaten, stückig (ca 800g)',
          ],
          recipeInstructions: const <String>[
            'Die Tomaten in den Topf geben.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: 'gr Dose/n Tomaten, stückig (ca 800g)',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'tomatoes'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'tomatoes',
            name: 'Tomaten, stückig',
            currentAmount: 800,
          ),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('Tomaten (800 g)', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('shows package count and embedded weight in instructions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        template: _template(
          recipeIngredients: const <String>[
            '1 Dose Tomaten, passiert (ca 800g)',
          ],
          recipeInstructions: const <String>[
            'Die Tomaten in den Topf geben.',
          ],
        ),
        introDraft: const CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '1 Dose Tomaten, passiert (ca 800g)',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'tomatoes'),
              ],
            ),
          ],
        ),
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'tomatoes',
            name: 'Tomaten, passiert',
            currentAmount: 800,
          ),
        ],
        adjustmentController: controller,
      ),
    );
    await _pumpInstructionSteps(tester);

    expect(
      find.textContaining('Tomaten (1x 800g)', findRichText: true),
      findsOneWidget,
    );
  });
}
