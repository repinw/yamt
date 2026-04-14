import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item({
  required String id,
  required String name,
  required int quantity,
  required int initialQuantity,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1,
  );
}

Widget _buildTestApp({required List<InventoryItem> items}) {
  return _buildInventoryTestApp(items: items);
}

Widget _buildInventoryTestApp({
  required List<InventoryItem> items,
  List<PreparedMeal> preparedMeals = const <PreparedMeal>[],
  VoiceSearchService? speechService,
}) {
  return ProviderScope(
    overrides: [
      barcodeBackfillFeatureFlagsProvider.overrideWithValue(
        const BarcodeBackfillFeatureFlags(
          showInventoryBarcodeMarkers: false,
          enableQueueBackfill: false,
        ),
      ),
      activeShoppingListItemKeysProvider.overrideWithValue(
        const <ShoppingListItemMatchKey>{},
      ),
      if (speechService != null)
        voiceSearchServiceProvider.overrideWithValue(speechService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: _buildInventoryListBody(
          items: items,
          preparedMeals: preparedMeals,
        ),
      ),
    ),
  );
}

Widget _buildInventoryListBody({
  required List<InventoryItem> items,
  required List<PreparedMeal> preparedMeals,
}) {
  return InventoryList(
    items: items,
    preparedMeals: preparedMeals,
    emptyStateActionButton: const SizedBox.shrink(),
    onDeleteItem: (itemId) async => true,
    onEatItem: (itemId, request) async => true,
    onThrowAwayItem: (itemId, amount, reason) async => true,
    onEatPreparedMeal:
        ({
          required mealId,
          required portions,
          required mealType,
          required loggedDay,
        }) async => true,
    onThrowAwayPreparedMeal: (mealId, portions, reason) async => true,
    onFillPendingPreparedMealIngredient:
        (mealId, ingredient, inventoryItemIds) async => true,
    onIgnorePendingPreparedMealIngredient: (mealId, ingredient) async => true,
    onUnbundlePreparedMeal: (mealId) async => true,
    onEditPreparedMeal: (mealId, name, imageChanged, imageBytes) async => true,
    onSavePreparedMealTemplate: (meal) async => true,
    isSelectionMode: false,
    selectedItemIds: const <String>{},
    onItemLongPress: (itemId) {},
    onSelectionToggle: (itemId) {},
  );
}

PreparedMeal _preparedMeal({
  required String id,
  required String name,
  DateTime? createdAt,
}) {
  final timestamp = createdAt ?? DateTime.parse('2026-02-20T08:00:00Z');
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: 2,
    remainingPortions: 1,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 50,
    totalFat: 15,
    createdAt: timestamp,
    updatedAt: timestamp,
    components: const [],
  );
}

List<String> _visibleInventoryItemNames(WidgetTester tester) {
  return tester
      .widgetList<InventoryItemRowListEntry>(
        find.byType(InventoryItemRowListEntry),
      )
      .map((entry) => entry.item.name)
      .toList(growable: false);
}

class _FakeManualProductSpeechService implements VoiceSearchService {
  bool _isListening = false;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<VoiceSearchFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _onError = onError;
    _isListening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() async {
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  void emitTranscript(String transcript) {
    _onResult?.call(
      VoiceSearchRecognition(transcript: transcript, isFinal: true),
    );
  }

  void emitError(VoiceSearchFailure failure) {
    _onError?.call(failure);
  }
}

class _InventoryListPageStorageHarness extends StatefulWidget {
  const _InventoryListPageStorageHarness({
    required this.items,
    required this.preparedMeals,
  });

  final List<InventoryItem> items;
  final List<PreparedMeal> preparedMeals;

  @override
  State<_InventoryListPageStorageHarness> createState() =>
      _InventoryListPageStorageHarnessState();
}

class _InventoryListPageStorageHarnessState
    extends State<_InventoryListPageStorageHarness> {
  final _bucket = PageStorageBucket();
  var _showList = true;

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: _bucket,
      child: Column(
        children: [
          TextButton(
            key: const Key('toggle_inventory_list_mount'),
            onPressed: () {
              setState(() {
                _showList = !_showList;
              });
            },
            child: const Text('toggle'),
          ),
          Expanded(
            child: _showList
                ? _buildInventoryListBody(
                    items: widget.items,
                    preparedMeals: widget.preparedMeals,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('filter switch updates in sheet and hides fully consumed items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        items: <InventoryItem>[
          _item(
            id: 'partial',
            name: 'Open milk',
            quantity: 1,
            initialQuantity: 2,
          ),
          _item(
            id: 'empty',
            name: 'Empty jar',
            quantity: 0,
            initialQuantity: 2,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open milk'), findsOneWidget);
    expect(find.text('Empty jar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
    await tester.pumpAndSettle();

    final before = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(before.value, isFalse);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    final after = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(after.value, isTrue);

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Open milk'), findsOneWidget);
    expect(find.text('Empty jar'), findsNothing);
  });

  testWidgets('inventory search filters items and prepared meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: <InventoryItem>[
          _item(
            id: 'apple',
            name: 'Apple Juice',
            quantity: 1,
            initialQuantity: 1,
          ),
          _item(
            id: 'beans',
            name: 'Kidney Beans',
            quantity: 1,
            initialQuantity: 1,
          ),
        ],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'meal-1', name: 'Pasta Bowl'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventory_list_search_field')),
      'beans',
    );
    await tester.pumpAndSettle();

    expect(find.text('Kidney Beans'), findsOneWidget);
    expect(find.text('Apple Juice'), findsNothing);
    expect(find.text('Pasta Bowl'), findsNothing);
  });

  testWidgets(
    'inventory items sort can switch between added descending and ascending',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          items: <InventoryItem>[
            _item(
              id: 'apple',
              name: 'Apple',
              quantity: 1,
              initialQuantity: 1,
            ).copyWith(entryDate: DateTime.parse('2026-02-20T08:00:00Z')),
            _item(
              id: 'zucchini',
              name: 'Zucchini',
              quantity: 1,
              initialQuantity: 1,
            ).copyWith(entryDate: DateTime.parse('2026-02-21T08:00:00Z')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Foods'), findsOneWidget);
      expect(find.text('Recently added descending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>['Zucchini', 'Apple']);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('inventory_items_sort_recently_added_ascending_option'),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Foods'), findsOneWidget);
      expect(find.text('Recently added ascending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>['Apple', 'Zucchini']);
    },
  );

  testWidgets(
    'inventory items sort can switch between eaten descending and ascending',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          items: <InventoryItem>[
            _item(
              id: 'old',
              name: 'Old',
              quantity: 1,
              initialQuantity: 1,
            ).copyWith(lastConsumedAt: DateTime.parse('2026-02-21T08:00:00Z')),
            _item(
              id: 'recent',
              name: 'Recent',
              quantity: 1,
              initialQuantity: 1,
            ).copyWith(lastConsumedAt: DateTime.parse('2026-02-22T08:00:00Z')),
            _item(id: 'never', name: 'Never', quantity: 1, initialQuantity: 1),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('inventory_items_sort_recently_eaten_descending_option'),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Recently eaten descending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>[
        'Recent',
        'Old',
        'Never',
      ]);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('inventory_items_sort_recently_eaten_ascending_option'),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Recently eaten ascending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>[
        'Old',
        'Recent',
        'Never',
      ]);
    },
  );

  testWidgets(
    'inventory items sort can switch by available amount percentage',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          items: <InventoryItem>[
            _item(id: 'full', name: 'Full', quantity: 4, initialQuantity: 4),
            _item(id: 'half', name: 'Half', quantity: 2, initialQuantity: 4),
            _item(id: 'empty', name: 'Empty', quantity: 0, initialQuantity: 4),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('inventory_items_sort_available_amount_ascending_option'),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(_visibleInventoryItemNames(tester), <String>[
        'Empty',
        'Half',
        'Full',
      ]);
      expect(find.text('Available amount ascending'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('inventory_items_sort_available_amount_descending_option'),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(_visibleInventoryItemNames(tester), <String>[
        'Full',
        'Half',
        'Empty',
      ]);
      expect(find.text('Available amount descending'), findsOneWidget);
    },
  );

  testWidgets('prepared meals filter hides fully consumed meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'meal-1', name: 'Fresh Pasta'),
          _preparedMeal(
            id: 'meal-2',
            name: 'Gone Soup',
          ).copyWith(remainingPortions: 0),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fresh Pasta'), findsOneWidget);
    expect(find.text('Gone Soup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    final before = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(before.value, isFalse);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Fresh Pasta'), findsOneWidget);
    expect(find.text('Gone Soup'), findsNothing);
  });

  testWidgets('prepared meals sort can switch between newest and oldest', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(
            id: 'old-meal',
            name: 'Old Meal',
            createdAt: DateTime.parse('2026-02-18T08:00:00Z'),
          ),
          _preparedMeal(
            id: 'new-meal',
            name: 'New Meal',
            createdAt: DateTime.parse('2026-02-21T08:00:00Z'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    List<String> visibleMealNames() {
      return tester
          .widgetList<PreparedMealCard>(find.byType(PreparedMealCard))
          .map((card) => card.meal.name)
          .toList(growable: false);
    }

    expect(visibleMealNames(), <String>['New Meal', 'Old Meal']);

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_sort_newest_button')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(visibleMealNames(), <String>['Old Meal', 'New Meal']);
  });

  testWidgets('prepared meals ready-only filter hides incomplete meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'ready-meal', name: 'Ready Meal'),
          _preparedMeal(
            id: 'incomplete-meal',
            name: 'Incomplete Meal',
          ).copyWith(pendingRecipeIngredients: const <String>['Cheese']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready Meal'), findsOneWidget);
    expect(find.text('Incomplete Meal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_ready_only_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Ready Meal'), findsOneWidget);
    expect(find.text('Incomplete Meal'), findsNothing);
  });

  testWidgets('prepared meals filter toggles are mutually exclusive', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'ready-meal', name: 'Ready Meal'),
          _preparedMeal(
            id: 'incomplete-meal',
            name: 'Incomplete Meal',
          ).copyWith(pendingRecipeIngredients: const <String>['Cheese']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    Finder readySwitch() {
      return find.descendant(
        of: find.byKey(const Key('prepared_meals_ready_only_toggle')),
        matching: find.byType(Switch),
      );
    }

    Finder incompleteSwitch() {
      return find.descendant(
        of: find.byKey(const Key('prepared_meals_incomplete_only_toggle')),
        matching: find.byType(Switch),
      );
    }

    await tester.tap(readySwitch());
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(readySwitch()).value, isTrue);
    expect(tester.widget<Switch>(incompleteSwitch()).value, isFalse);

    await tester.tap(incompleteSwitch());
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(readySwitch()).value, isFalse);
    expect(tester.widget<Switch>(incompleteSwitch()).value, isTrue);
  });

  testWidgets('prepared meals incomplete-only filter hides ready meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'ready-meal', name: 'Ready Meal'),
          _preparedMeal(
            id: 'incomplete-meal',
            name: 'Incomplete Meal',
          ).copyWith(pendingRecipeIngredients: const <String>['Cheese']),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_incomplete_only_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Ready Meal'), findsNothing);
    expect(find.text('Incomplete Meal'), findsOneWidget);
  });

  testWidgets('prepared meals depleted-only filter hides remaining meals', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'ready-meal', name: 'Ready Meal'),
          _preparedMeal(
            id: 'depleted-meal',
            name: 'Depleted Meal',
          ).copyWith(remainingPortions: 0),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_depleted_only_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Ready Meal'), findsNothing);
    expect(find.text('Depleted Meal'), findsOneWidget);
  });

  testWidgets('inventory items section can be collapsed', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        items: <InventoryItem>[
          _item(id: 'milk', name: 'Open milk', quantity: 1, initialQuantity: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final initialRotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_items_section_expand_indicator')),
    );
    expect(initialRotation.turns, 0.5);
    expect(find.text('Open milk'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('inventory_items_section_expand_button')),
    );
    await tester.pumpAndSettle();

    final collapsedRotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_items_section_expand_indicator')),
    );
    expect(collapsedRotation.turns, 0);
    expect(find.text('Open milk'), findsNothing);
  });

  testWidgets(
    'inventory items section restores collapse state from page storage',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            barcodeBackfillFeatureFlagsProvider.overrideWithValue(
              const BarcodeBackfillFeatureFlags(
                showInventoryBarcodeMarkers: false,
                enableQueueBackfill: false,
              ),
            ),
            activeShoppingListItemKeysProvider.overrideWithValue(
              const <ShoppingListItemMatchKey>{},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: _InventoryListPageStorageHarness(
                items: <InventoryItem>[
                  _item(
                    id: 'milk',
                    name: 'Open milk',
                    quantity: 1,
                    initialQuantity: 2,
                  ),
                ],
                preparedMeals: const <PreparedMeal>[],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('inventory_items_section_expand_button')),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const Key('inventory_items_section_expand_indicator')),
            )
            .turns,
        0,
      );
      expect(find.text('Open milk'), findsNothing);

      await tester.tap(find.byKey(const Key('toggle_inventory_list_mount')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_inventory_list_mount')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const Key('inventory_items_section_expand_indicator')),
            )
            .turns,
        0,
      );
      expect(find.text('Open milk'), findsNothing);
    },
  );

  testWidgets('prepared meals section can be collapsed', (tester) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(id: 'meal-1', name: 'Pasta Bowl'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final initialRotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('prepared_meals_section_expand_indicator')),
    );
    expect(initialRotation.turns, 0.5);
    expect(find.text('Pasta Bowl'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('prepared_meals_section_expand_button')),
    );
    await tester.pumpAndSettle();

    final collapsedRotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('prepared_meals_section_expand_indicator')),
    );
    expect(collapsedRotation.turns, 0);
    expect(find.text('Pasta Bowl'), findsNothing);
  });

  testWidgets(
    'prepared meals section restores collapse state from page storage',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            barcodeBackfillFeatureFlagsProvider.overrideWithValue(
              const BarcodeBackfillFeatureFlags(
                showInventoryBarcodeMarkers: false,
                enableQueueBackfill: false,
              ),
            ),
            activeShoppingListItemKeysProvider.overrideWithValue(
              const <ShoppingListItemMatchKey>{},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: _InventoryListPageStorageHarness(
                items: const <InventoryItem>[],
                preparedMeals: <PreparedMeal>[
                  _preparedMeal(id: 'meal-1', name: 'Pasta Bowl'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('prepared_meals_section_expand_button')),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const Key('prepared_meals_section_expand_indicator')),
            )
            .turns,
        0,
      );
      expect(find.text('Pasta Bowl'), findsNothing);

      await tester.tap(find.byKey(const Key('toggle_inventory_list_mount')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_inventory_list_mount')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const Key('prepared_meals_section_expand_indicator')),
            )
            .turns,
        0,
      );
      expect(find.text('Pasta Bowl'), findsNothing);
    },
  );

  testWidgets(
    'inventory search matches compact voice query against spaced OCR name',
    (tester) async {
      await tester.pumpWidget(
        _buildInventoryTestApp(
          items: <InventoryItem>[
            _item(
              id: 'bread',
              name: 'Eiweiß Bort',
              quantity: 1,
              initialQuantity: 1,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inventory_list_search_field')),
        'eiweißbrot',
      );
      await tester.pumpAndSettle();

      expect(find.text('Eiweiß Bort'), findsOneWidget);
    },
  );

  testWidgets('inventory search can be cleared with broom button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: <InventoryItem>[
          _item(
            id: 'apple',
            name: 'Apple Juice',
            quantity: 1,
            initialQuantity: 1,
          ),
          _item(
            id: 'beans',
            name: 'Kidney Beans',
            quantity: 1,
            initialQuantity: 1,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('inventory_list_search_field')),
      'beans',
    );
    await tester.pumpAndSettle();

    expect(find.text('Kidney Beans'), findsOneWidget);
    expect(find.text('Apple Juice'), findsNothing);

    await tester.tap(
      find.byKey(const Key('inventory_list_search_clear_button')),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('inventory_list_search_field')),
    );
    expect(textField.controller?.text, isEmpty);
    expect(find.text('Kidney Beans'), findsOneWidget);
    expect(find.text('Apple Juice'), findsOneWidget);
  });

  testWidgets('inventory voice search fills query and filters list', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService();

    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: <InventoryItem>[
          _item(
            id: 'apple',
            name: 'Apple Juice',
            quantity: 1,
            initialQuantity: 1,
          ),
          _item(
            id: 'beans',
            name: 'Kidney Beans',
            quantity: 1,
            initialQuantity: 1,
          ),
        ],
        speechService: speechService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('inventory_list_voice_search_button')),
    );
    await tester.pumpAndSettle();

    speechService.emitTranscript('apple');
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(
      find.byKey(const Key('inventory_list_search_field')),
    );
    expect(textField.controller?.text, 'apple');
    expect(find.text('Apple Juice'), findsOneWidget);
    expect(find.text('Kidney Beans'), findsNothing);
  });
}
