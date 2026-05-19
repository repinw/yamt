import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_page.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/root_navigator_test_utils.dart';

Widget _buildHarness({
  required List<String> adjustments,
  List<CookingFlowSummaryIngredientDraft>? ingredients,
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  ValueChanged<CookingFlowSummaryIngredientAddSource>?
  onAddIngredientSourceSelected,
  void Function(int index, CookingFlowSummaryIngredientAddSource source)?
  onAdjustmentSourceSelected,
  List<CookingFlowStorageContainerView>? storageContainers,
  Map<String, String> ingredientContainerAssignments = const <String, String>{},
  void Function(String rowKey, String containerId)?
  onIngredientContainerChanged,
}) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CookingFlowSummaryPage(
        ingredients:
            ingredients ??
            const <CookingFlowSummaryIngredientDraft>[
              CookingFlowSummaryIngredientDraft(
                key: 'template:300g Linsen',
                name: 'Linsen',
                amount: '300',
                unitCode: 'g',
                inventoryItemIds: <String>[],
                kind: CookingFlowSummaryIngredientKind.template,
              ),
            ],
        inventoryItems: inventoryItems,
        adjustments: adjustments,
        onAmountChanged: (_, _) {},
        onRemoveIngredient: (_) {},
        onAddIngredientSourceSelected: onAddIngredientSourceSelected ?? (_) {},
        onAdjustmentSourceSelected: onAdjustmentSourceSelected ?? (_, _) {},
        storageContainers: storageContainers ?? _storageContainers(),
        ingredientContainerAssignments: ingredientContainerAssignments,
        onIngredientContainerChanged: onIngredientContainerChanged ?? (_, _) {},
      ),
    ),
  );
}

List<CookingFlowStorageContainerView> _storageContainers() {
  return <CookingFlowStorageContainerView>[
    CookingFlowStorageContainerView(
      id: 'container-1',
      labelController: TextEditingController(text: 'Topf 1'),
      taraController: TextEditingController(text: '500'),
      grossWeightController: TextEditingController(),
      portionController: TextEditingController(text: '4'),
      selectedTaraUtensilId: 'pot-1',
      canRemove: false,
    ),
  ];
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int amount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: amount,
    currentAmount: amount,
    amountUnit: InventoryAmountUnit.gram,
  );
}

void main() {
  testWidgets('add ingredient menu opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: CookingFlowSummaryPage(
            ingredients: const <CookingFlowSummaryIngredientDraft>[
              CookingFlowSummaryIngredientDraft(
                key: 'template:300g Linsen',
                name: 'Linsen',
                amount: '300',
                unitCode: 'g',
                inventoryItemIds: <String>[],
                kind: CookingFlowSummaryIngredientKind.template,
              ),
            ],
            inventoryItems: const <InventoryItem>[],
            adjustments: const <String>[],
            onAmountChanged: (_, _) {},
            onRemoveIngredient: (_) {},
            onAddIngredientSourceSelected: (_) {},
            onAdjustmentSourceSelected: (_, _) {},
            storageContainers: _storageContainers(),
            ingredientContainerAssignments: const <String, String>{},
            onIngredientContainerChanged: (_, _) {},
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_ingredient_button')),
    );
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(
      find.byKey(const Key('cookflow_summary_add_source_inventory')),
      findsOneWidget,
    );
  });

  testWidgets('does not render placeholder adjustment when list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(adjustments: const <String>[]));

    expect(find.text('Ungelöste Anpassungen'), findsNothing);
    expect(find.textContaining('200g Gurken'), findsNothing);
  });

  testWidgets('renders user adjustments when present', (tester) async {
    await tester.pumpWidget(
      _buildHarness(adjustments: const <String>['50g Petersilie']),
    );

    expect(find.text('Ungelöste Anpassungen'), findsOneWidget);
    expect(find.textContaining('50g Petersilie'), findsOneWidget);
  });

  testWidgets('shows inventory subtract and remaining amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        adjustments: const <String>[],
        ingredients: const <CookingFlowSummaryIngredientDraft>[
          CookingFlowSummaryIngredientDraft(
            key: 'template:1 Dose Tomaten, passiert (ca 800g)',
            name: 'Tomaten, passiert',
            amount: '800',
            unitCode: 'g',
            inventoryItemIds: <String>['tomatoes'],
            kind: CookingFlowSummaryIngredientKind.template,
          ),
        ],
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'tomatoes',
            name: 'Tomaten, passiert',
            amount: 1000,
          ),
        ],
      ),
    );

    expect(find.text('Abzug 800g · übrig 200g'), findsOneWidget);
  });

  testWidgets('renders add ingredient action as final ingredient row', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(adjustments: const <String>[]));

    final ingredientTop = tester.getTopLeft(find.text('Linsen')).dy;
    final addRowTop = tester
        .getTopLeft(
          find.byKey(const Key('cookflow_summary_add_ingredient_button')),
        )
        .dy;

    expect(addRowTop, greaterThan(ingredientTop));
    expect(find.text('Zutat hinzufügen'), findsOneWidget);
  });

  testWidgets('add ingredient menu reports selected source', (tester) async {
    CookingFlowSummaryIngredientAddSource? selectedSource;

    await tester.pumpWidget(
      _buildHarness(
        adjustments: const <String>[],
        onAddIngredientSourceSelected: (source) {
          selectedSource = source;
        },
      ),
    );

    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_ingredient_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_source_inventory')).last,
    );
    await tester.pumpAndSettle();

    expect(selectedSource, CookingFlowSummaryIngredientAddSource.inventory);
  });

  testWidgets('unresolved adjustment menu reports source and index', (
    tester,
  ) async {
    int? selectedIndex;
    CookingFlowSummaryIngredientAddSource? selectedSource;

    await tester.pumpWidget(
      _buildHarness(
        adjustments: const <String>['50g Petersilie'],
        onAdjustmentSourceSelected: (index, source) {
          selectedIndex = index;
          selectedSource = source;
        },
      ),
    );

    final adjustmentButton = find.byKey(
      const Key('cookflow_summary_adjustment_add_button'),
    );
    await tester.ensureVisible(adjustmentButton);
    await tester.pumpAndSettle();
    await tester.tap(adjustmentButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_source_manualSearch')).last,
    );
    await tester.pumpAndSettle();

    expect(selectedIndex, 0);
    expect(selectedSource, CookingFlowSummaryIngredientAddSource.manualSearch);
  });

  testWidgets('ingredient rows can be assigned to storage containers', (
    tester,
  ) async {
    String? changedRowKey;
    String? changedContainerId;

    await tester.pumpWidget(
      _buildHarness(
        adjustments: const <String>[],
        ingredients: const <CookingFlowSummaryIngredientDraft>[
          CookingFlowSummaryIngredientDraft(
            key: 'template:pasta',
            name: 'Spaghetti',
            amount: '500',
            unitCode: 'g',
            inventoryItemIds: <String>['pasta'],
            kind: CookingFlowSummaryIngredientKind.template,
          ),
        ],
        storageContainers: <CookingFlowStorageContainerView>[
          ..._storageContainers(),
          CookingFlowStorageContainerView(
            id: 'container-2',
            labelController: TextEditingController(text: 'Sauce'),
            taraController: TextEditingController(text: '300'),
            grossWeightController: TextEditingController(),
            portionController: TextEditingController(text: '4'),
            selectedTaraUtensilId: 'pot-2',
            canRemove: true,
          ),
        ],
        ingredientContainerAssignments: const <String, String>{
          'template:pasta': 'container-1',
        },
        onIngredientContainerChanged: (rowKey, containerId) {
          changedRowKey = rowKey;
          changedContainerId = containerId;
        },
      ),
    );

    await tester.tap(find.text('Topf 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauce').last);
    await tester.pumpAndSettle();

    expect(changedRowKey, 'template:pasta');
    expect(changedContainerId, 'container-2');
  });
}
