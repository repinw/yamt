import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_detail_page.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../shoppinglist/support/fake_shopping_list_repository.dart';

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  _FakePreparedMealTemplateRepository({
    required List<PreparedMeal> initialTemplates,
  }) : _templates = List<PreparedMeal>.from(initialTemplates);

  final _controller = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates;

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> saveAll(List<PreparedMeal> templates) async {
    _templates = List<PreparedMeal>.from(templates);
    _controller.add(List<PreparedMeal>.from(_templates));
    return true;
  }

  Future<void> dispose() => _controller.close();
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  const _FakeInventoryItemRepository({this.items = const <InventoryItem>[]});

  final List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(items);
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return items;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }
}

PreparedMeal _recipeTemplate({
  List<String> recipeIngredients = const <String>[
    '1 kg Potatoes',
    '500 ml Broth',
  ],
  Map<String, List<String>> recipeIngredientAssignments =
      const <String, List<String>>{},
  Map<String, RecipeIngredientAmountConversion>
      recipeIngredientAmountConversions =
      const <String, RecipeIngredientAmountConversion>{},
  int totalPortions = 4,
}) {
  return PreparedMeal(
    id: 'template-1',
    name: 'Potato soup',
    recipeUrl: 'https://www.chefkoch.de/rezepte/1234/potato-soup.html',
    recipeIngredients: recipeIngredients,
    recipeIngredientAssignments: recipeIngredientAssignments,
    recipeIngredientAmountConversions: recipeIngredientAmountConversions,
    totalPortions: totalPortions,
    remainingPortions: totalPortions,
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
  required PreparedMealTemplateRepository templateRepository,
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  FakeShoppingListRepository? shoppingListRepository,
}) {
  return ProviderScope(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templateRepository,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(items: inventoryItems),
      ),
      if (shoppingListRepository != null)
        shoppingListRepositoryProvider.overrideWithValue(
          shoppingListRepository,
        ),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MealTemplateDetailPage(templateId: 'template-1'),
    ),
  );
}

Widget _buildStandaloneHarness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  int quantity = 1,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: quantity,
  );
}

InventoryItem _weightedInventoryItem({
  required String id,
  required String name,
  required int amount,
  int? currentAmount,
  int? initialAmount,
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: initialAmount ?? amount,
    currentAmount: currentAmount ?? amount,
    amountUnit: unit,
  );
}

InkWell _inkWellForText(WidgetTester tester, String text) {
  final finder = find.ancestor(
    of: find.text(text),
    matching: find.byType(InkWell),
  );
  return tester.widget<InkWell>(finder.first);
}

void main() {
  testWidgets('renders localized meal template detail content', (tester) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[_recipeTemplate()],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(templateRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Ingredient Matching: Potato soup'), findsOneWidget);
    expect(find.text('Base: 4 portions'), findsOneWidget);
    expect(find.text('4 portions'), findsOneWidget);
    expect(find.text('1 kg Potatoes'), findsOneWidget);
  });

  testWidgets('shows localized not-found state', (tester) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: const <PreparedMeal>[],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(templateRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Template not found.'), findsOneWidget);
  });

  testWidgets(
    'automatically matches recipe ingredients from inventory on first load',
    (tester) async {
      final repository = _FakePreparedMealTemplateRepository(
        initialTemplates: <PreparedMeal>[_recipeTemplate()],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          templateRepository: repository,
          inventoryItems: <InventoryItem>[
            _weightedInventoryItem(
              id: 'item-potatoes',
              name: 'Potatoes',
              amount: 1000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Swap'), findsOneWidget);
      expect(find.text('Potatoes - 1000 g'), findsOneWidget);
    },
  );

  testWidgets(
    'automatically matches german ingredient synonyms from inventory',
    (tester) async {
      final repository = _FakePreparedMealTemplateRepository(
        initialTemplates: <PreparedMeal>[
          _recipeTemplate(
            recipeIngredients: const <String>['2 Möhren'],
            totalPortions: 1,
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          templateRepository: repository,
          inventoryItems: <InventoryItem>[
            _inventoryItem(id: 'item-carrots', name: 'Karotten'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Karotten - 1x'), findsOneWidget);
    },
  );

  testWidgets(
    'replaces stale ingredient assignments with current inventory matches',
    (tester) async {
      final repository = _FakePreparedMealTemplateRepository(
        initialTemplates: <PreparedMeal>[
          _recipeTemplate(
            recipeIngredients: const <String>['2 Möhren'],
            recipeIngredientAssignments: const <String, List<String>>{
              '2 Möhren': <String>['missing-item'],
            },
            totalPortions: 1,
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          templateRepository: repository,
          inventoryItems: <InventoryItem>[
            _inventoryItem(id: 'item-carrots', name: 'Karotten'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Karotten - 1x'), findsOneWidget);
      expect(find.text('1 assigned item no longer exists.'), findsNothing);
    },
  );

  testWidgets('adds only uncovered ingredient remainder to the shopping list', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _recipeTemplate(
          recipeIngredients: const <String>['1000 g Ground beef'],
          recipeIngredientAssignments: const <String, List<String>>{
            '1000 g Ground beef': <String>['item-beef'],
          },
          totalPortions: 1,
        ),
      ],
    );
    final shoppingRepository = FakeShoppingListRepository();
    addTearDown(repository.dispose);
    addTearDown(shoppingRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        templateRepository: repository,
        shoppingListRepository: shoppingRepository,
        inventoryItems: <InventoryItem>[
          _weightedInventoryItem(
            id: 'item-beef',
            name: 'Ground beef',
            amount: 1000,
            currentAmount: 800,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ingredients to shopping list'));
    await tester.pumpAndSettle();

    expect(shoppingRepository.savedItems, hasLength(1));
    expect(shoppingRepository.savedItems.single.name, '200 g Ground beef');
  });

  testWidgets(
    'assigns measured inventory to piece ingredients with conversion input',
    (tester) async {
      final repository = _FakePreparedMealTemplateRepository(
        initialTemplates: <PreparedMeal>[
          _recipeTemplate(
            recipeIngredients: const <String>['2 Carrots'],
            totalPortions: 1,
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          templateRepository: repository,
          inventoryItems: <InventoryItem>[
            _weightedInventoryItem(
              id: 'item-carrots',
              name: 'Carrots',
              amount: 2000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Carrots'));
      await tester.pumpAndSettle();

      expect(find.text('Amount per pc (g)'), findsNothing);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Amount per pc (g)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Carrots - 2000 g'), findsOneWidget);
      expect(find.text('1 pc = 100 g'), findsOneWidget);
    },
  );

  testWidgets('offers gram conversion for tablespoon ingredients', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _recipeTemplate(
          recipeIngredients: const <String>['4 EL Tomatenmark'],
          totalPortions: 1,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        templateRepository: repository,
        inventoryItems: <InventoryItem>[
          _weightedInventoryItem(
            id: 'item-paste',
            name: 'Tomatenmark',
            amount: 500,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tomatenmark'));
    await tester.pumpAndSettle();

    expect(find.text('Amount per EL (g)'), findsNothing);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Amount per EL (g)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '15');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('1 EL = 15 g'), findsOneWidget);
  });

  testWidgets('keeps conversion input visible when keyboard insets change', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _recipeTemplate(
          recipeIngredients: const <String>['2 Carrots'],
          totalPortions: 1,
        ),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      _buildHarness(
        templateRepository: repository,
        inventoryItems: <InventoryItem>[
          _weightedInventoryItem(
            id: 'item-carrots',
            name: 'Carrots',
            amount: 2000,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Carrots'));
    await tester.pumpAndSettle();

    expect(find.text('Amount per pc (g)'), findsNothing);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Amount per pc (g)'), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(find.text('Amount per pc (g)'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.enterText(find.byType(TextField), '100');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('1 pc = 100 g'), findsOneWidget);
  });

  testWidgets('scales unitless ingredient amounts when portions increase', (
    tester,
  ) async {
    final repository = _FakePreparedMealTemplateRepository(
      initialTemplates: <PreparedMeal>[
        _recipeTemplate(
          recipeIngredients: const <String>['2 Carrots'],
          totalPortions: 1,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(templateRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('2 Carrots'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('4 Carrots'), findsOneWidget);
    expect(find.text('2 Carrots'), findsNothing);
  });

  testWidgets('renders ignored ingredient state with struck-through text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateIngredientCardTestHarness(
          name: 'Parsley',
          amountLabel: '1 kg',
          rawIngredient: '1 kg Parsley',
          isIgnored: true,
          inventoryItems: <InventoryItem>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('1 kg Parsley'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('renders matched ingredient state with check icon and swap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        MealTemplateIngredientCardTestHarness(
          name: 'Ground beef',
          amountLabel: '500 g',
          rawIngredient: '500 g Ground beef',
          assignedInventoryItemIds: const <String>['item-1'],
          inventoryItems: <InventoryItem>[
            _inventoryItem(id: 'item-1', name: 'Grass-fed Beef'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Swap'), findsOneWidget);
    expect(find.text('500 g Ground beef'), findsOneWidget);
    expect(find.text('Grass-fed Beef - 1x'), findsOneWidget);
  });

  testWidgets('renders missing ingredient state with error and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        MealTemplateIngredientCardTestHarness(
          name: 'Cream',
          amountLabel: '200 ml',
          rawIngredient: '200 ml Cream',
          inventoryItems: const <InventoryItem>[],
          onAddToShoppingListPressed: _completedFuture,
          onToggleIgnoredPressed: _completedFuture,
          onAssignmentChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(find.text('200 ml Cream'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Ignore'), findsOneWidget);
  });

  testWidgets('search selection drops stale assigned item ids before saving', (
    tester,
  ) async {
    final selectedIds = ValueNotifier<List<String>>(const <String>[
      'missing-item',
    ]);
    addTearDown(selectedIds.dispose);

    await tester.pumpWidget(
      _buildStandaloneHarness(
        ValueListenableBuilder<List<String>>(
          valueListenable: selectedIds,
          builder: (context, value, _) {
            return MealTemplateIngredientCardTestHarness(
              name: 'Broth',
              amountLabel: '1 l',
              rawIngredient: '1 l Broth',
              assignedInventoryItemIds: value,
              inventoryItems: <InventoryItem>[
                _inventoryItem(id: 'item-1', name: 'Vegetable stock'),
              ],
              onAssignmentChanged: (selection) {
                selectedIds.value = selection.inventoryItemIds;
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vegetable stock'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(selectedIds.value, <String>['item-1']);
    expect(find.text('Vegetable stock - 1x'), findsOneWidget);
    expect(
      find.text('1 assigned items are no longer in inventory.'),
      findsNothing,
    );
  });

  testWidgets('shows save button in footer only when assignments changed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateFooterTestHarness(
          hasAssignmentChanges: false,
          isCreatingMeal: false,
          isSavingTemplate: false,
          canCreateMeal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update template'), findsNothing);

    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateFooterTestHarness(
          hasAssignmentChanges: true,
          isCreatingMeal: false,
          isSavingTemplate: false,
          canCreateMeal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update template'), findsOneWidget);
  });

  testWidgets('disables footer action buttons while template is saving', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateFooterTestHarness(
          hasAssignmentChanges: true,
          isCreatingMeal: false,
          isSavingTemplate: true,
          canCreateMeal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _inkWellForText(tester, 'Ingredients to shopping list').onTap,
      isNull,
    );
    expect(_inkWellForText(tester, 'Create meal').onTap, isNull);
  });

  testWidgets('disables footer action buttons while meal creation runs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateFooterTestHarness(
          hasAssignmentChanges: false,
          isCreatingMeal: true,
          isSavingTemplate: false,
          canCreateMeal: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _inkWellForText(tester, 'Ingredients to shopping list').onTap,
      isNull,
    );
    expect(_inkWellForText(tester, 'Create meal').onTap, isNull);
  });

  testWidgets('shows footer hint when meal creation is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildStandaloneHarness(
        const MealTemplateFooterTestHarness(
          hasAssignmentChanges: false,
          isCreatingMeal: false,
          isSavingTemplate: false,
          canCreateMeal: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This template needs at least one ingredient before you can create a meal.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _completedFuture() async {}
