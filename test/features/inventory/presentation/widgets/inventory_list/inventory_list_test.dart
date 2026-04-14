import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
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
  AppPreferences? preferences,
}) {
  return ProviderScope(
    overrides: [
      if (preferences != null)
        appPreferencesProvider.overrideWithValue(preferences),
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
  int totalPortions = 2,
  int remainingPortions = 1,
}) {
  final timestamp = createdAt ?? DateTime.parse('2026-02-20T08:00:00Z');
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
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

class _MemoryAppPreferences implements AppPreferences {
  final Map<String, String> _strings = <String, String>{};
  final Map<String, int> _ints = <String, int>{};

  @override
  String? getStringSync(String key) => _strings[key];

  @override
  int? getIntSync(String key) => _ints[key];

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<bool> setString(String key, String value) async {
    _strings[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _ints[key] = value;
    return true;
  }
}

class _InventoryListPersistenceHarness extends StatefulWidget {
  const _InventoryListPersistenceHarness({
    required this.items,
    required this.preparedMeals,
  });

  final List<InventoryItem> items;
  final List<PreparedMeal> preparedMeals;

  @override
  State<_InventoryListPersistenceHarness> createState() =>
      _InventoryListPersistenceHarnessState();
}

class _InventoryListPersistenceHarnessState
    extends State<_InventoryListPersistenceHarness> {
  var _showList = true;

  @override
  Widget build(BuildContext context) {
    return Column(
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

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );

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
      expect(find.text('Added - Descending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>['Zucchini', 'Apple']);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('inventory_items_sort_added_direction_button')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Foods'), findsOneWidget);
      expect(find.text('Added - Ascending'), findsOneWidget);
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
      await _tapVisible(
        tester,
        find.byKey(const Key('inventory_items_sort_eaten_option')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Eaten - Descending'), findsOneWidget);
      expect(_visibleInventoryItemNames(tester), <String>[
        'Recent',
        'Old',
        'Never',
      ]);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('inventory_items_sort_eaten_direction_button')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Eaten - Ascending'), findsOneWidget);
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
      await _tapVisible(
        tester,
        find.byKey(const Key('inventory_items_sort_quantity_option')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(_visibleInventoryItemNames(tester), <String>[
        'Empty',
        'Half',
        'Full',
      ]);
      expect(find.text('Amount - Ascending'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('inventory_items_sort_quantity_direction_button')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(_visibleInventoryItemNames(tester), <String>[
        'Full',
        'Half',
        'Empty',
      ]);
      expect(find.text('Amount - Descending'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('prepared_meals_filter_button')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_filter_button')),
    );

    final before = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(before.value, isFalse);

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Fresh Pasta'), findsOneWidget);
    expect(find.text('Gone Soup'), findsNothing);
  });

  testWidgets(
    'prepared meals sort can switch between added descending and ascending',
    (tester) async {
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
      expect(find.text('Added - Descending'), findsOneWidget);

      await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('prepared_meals_sort_added_direction_button')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(visibleMealNames(), <String>['Old Meal', 'New Meal']);
      expect(find.text('Added - Ascending'), findsOneWidget);
    },
  );

  testWidgets(
    'prepared meals sort can switch between eaten descending and ascending',
    (tester) async {
      await tester.pumpWidget(
        _buildInventoryTestApp(
          items: const <InventoryItem>[],
          preparedMeals: <PreparedMeal>[
            _preparedMeal(
              id: 'old-eaten',
              name: 'Old Eaten',
              createdAt: DateTime.parse('2026-02-22T08:00:00Z'),
            ).copyWith(updatedAt: DateTime.parse('2026-02-19T08:00:00Z')),
            _preparedMeal(
              id: 'new-eaten',
              name: 'New Eaten',
              createdAt: DateTime.parse('2026-02-18T08:00:00Z'),
            ).copyWith(updatedAt: DateTime.parse('2026-02-22T08:00:00Z')),
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

      expect(visibleMealNames(), <String>['Old Eaten', 'New Eaten']);

      await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('prepared_meals_sort_eaten_option')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(visibleMealNames(), <String>['New Eaten', 'Old Eaten']);

      await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('prepared_meals_sort_eaten_direction_button')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(visibleMealNames(), <String>['Old Eaten', 'New Eaten']);
    },
  );

  testWidgets(
    'prepared meals sort can switch between alphabetical directions',
    (tester) async {
      await tester.pumpWidget(
        _buildInventoryTestApp(
          items: const <InventoryItem>[],
          preparedMeals: <PreparedMeal>[
            _preparedMeal(
              id: 'meal-b',
              name: 'Banana Bowl',
              createdAt: DateTime.parse('2026-02-18T08:00:00Z'),
            ),
            _preparedMeal(
              id: 'meal-a',
              name: 'Apple Pie',
              createdAt: DateTime.parse('2026-02-21T08:00:00Z'),
            ),
            _preparedMeal(
              id: 'meal-c',
              name: 'Carrot Soup',
              createdAt: DateTime.parse('2026-02-17T08:00:00Z'),
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

      expect(visibleMealNames(), <String>[
        'Apple Pie',
        'Banana Bowl',
        'Carrot Soup',
      ]);

      await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('prepared_meals_sort_alphabetical_option')),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(visibleMealNames(), <String>[
        'Apple Pie',
        'Banana Bowl',
        'Carrot Soup',
      ]);

      await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(
          const Key('prepared_meals_sort_alphabetical_direction_button'),
        ),
      );

      Navigator.of(tester.element(find.byType(InventoryList))).pop();
      await tester.pumpAndSettle();

      expect(visibleMealNames(), <String>[
        'Carrot Soup',
        'Banana Bowl',
        'Apple Pie',
      ]);
    },
  );

  testWidgets('prepared meals sort can switch between quantity directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: <PreparedMeal>[
          _preparedMeal(
            id: 'meal-low',
            name: 'Low Meal',
            totalPortions: 4,
            remainingPortions: 1,
          ),
          _preparedMeal(
            id: 'meal-mid',
            name: 'Mid Meal',
            totalPortions: 4,
            remainingPortions: 2,
          ),
          _preparedMeal(
            id: 'meal-high',
            name: 'High Meal',
            totalPortions: 4,
            remainingPortions: 4,
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('prepared_meals_filter_button')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_filter_button')),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_sort_quantity_option')),
    );

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(visibleMealNames(), <String>['Low Meal', 'Mid Meal', 'High Meal']);

    await tester.scrollUntilVisible(
      find.byKey(const Key('prepared_meals_filter_button')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_filter_button')),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_sort_quantity_direction_button')),
    );

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    expect(visibleMealNames(), <String>['High Meal', 'Mid Meal', 'Low Meal']);
  });

  testWidgets('inventory view preferences persist across remount', (
    tester,
  ) async {
    final preferences = _MemoryAppPreferences();
    final items = <InventoryItem>[
      _item(id: 'apple', name: 'Apple', quantity: 1, initialQuantity: 2),
      _item(id: 'banana', name: 'Banana', quantity: 1, initialQuantity: 2),
      _item(id: 'gone', name: 'Gone Milk', quantity: 0, initialQuantity: 2),
    ];

    await tester.pumpWidget(
      _buildInventoryTestApp(items: items, preferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('inventory_items_filter_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('inventory_items_filter_button')));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const Key('inventory_items_sort_alphabetical_option')),
    );
    await _tapVisible(
      tester,
      find.byKey(
        const Key('inventory_items_sort_alphabetical_direction_button'),
      ),
    );
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _buildInventoryTestApp(items: items, preferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(_visibleInventoryItemNames(tester), <String>['Banana', 'Apple']);
    expect(find.text('Gone Milk'), findsNothing);
  });

  testWidgets('prepared meal view preferences persist across remount', (
    tester,
  ) async {
    final preferences = _MemoryAppPreferences();
    final preparedMeals = <PreparedMeal>[
      _preparedMeal(
        id: 'meal-low',
        name: 'Ready Low',
        totalPortions: 4,
        remainingPortions: 1,
      ),
      _preparedMeal(
        id: 'meal-high',
        name: 'Ready High',
        totalPortions: 4,
        remainingPortions: 4,
      ),
      _preparedMeal(
        id: 'meal-incomplete',
        name: 'Incomplete Meal',
      ).copyWith(pendingRecipeIngredients: const <String>['Cheese']),
    ];

    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: preparedMeals,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prepared_meals_filter_button')));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_sort_quantity_option')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_sort_quantity_direction_button')),
    );
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_ready_only_toggle')),
        matching: find.byType(Switch),
      ),
    );

    Navigator.of(tester.element(find.byType(InventoryList))).pop();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _buildInventoryTestApp(
        items: const <InventoryItem>[],
        preparedMeals: preparedMeals,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<PreparedMealCard>(find.byType(PreparedMealCard))
          .map((card) => card.meal.name)
          .toList(growable: false),
      <String>['Ready High', 'Ready Low'],
    );
    expect(find.text('Incomplete Meal'), findsNothing);
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

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_ready_only_toggle')),
        matching: find.byType(Switch),
      ),
    );

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

    await _tapVisible(tester, readySwitch());

    expect(tester.widget<Switch>(readySwitch()).value, isTrue);
    expect(tester.widget<Switch>(incompleteSwitch()).value, isFalse);

    await _tapVisible(tester, incompleteSwitch());

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

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_incomplete_only_toggle')),
        matching: find.byType(Switch),
      ),
    );

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

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_depleted_only_toggle')),
        matching: find.byType(Switch),
      ),
    );

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
    'inventory items section restores collapse state from preferences',
    (tester) async {
      final preferences = _MemoryAppPreferences();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
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
              body: _InventoryListPersistenceHarness(
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
    'prepared meals section restores collapse state from preferences',
    (tester) async {
      final preferences = _MemoryAppPreferences();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
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
              body: _InventoryListPersistenceHarness(
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
