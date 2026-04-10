import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
import 'package:yamt/features/product_search/data/'
    'manual_product_speech_service.dart';
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
  ManualProductSpeechService? speechService,
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
        manualProductSpeechServiceProvider.overrideWithValue(speechService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryList(
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
          onIgnorePendingPreparedMealIngredient: (mealId, ingredient) async =>
              true,
          onUnbundlePreparedMeal: (mealId) async => true,
          onEditPreparedMeal: (mealId, name, imageChanged, imageBytes) async =>
              true,
          onSavePreparedMealTemplate: (meal) async => true,
          isSelectionMode: false,
          selectedItemIds: const <String>{},
          onItemLongPress: (itemId) {},
          onSelectionToggle: (itemId) {},
        ),
      ),
    ),
  );
}

PreparedMeal _preparedMeal({required String id, required String name}) {
  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: 2,
    remainingPortions: 1,
    totalKcal: 500,
    totalProtein: 20,
    totalCarbs: 50,
    totalFat: 15,
    createdAt: DateTime.parse('2026-02-20T08:00:00Z'),
    updatedAt: DateTime.parse('2026-02-20T08:00:00Z'),
    components: const [],
  );
}

class _FakeManualProductSpeechService implements ManualProductSpeechService {
  bool _isListening = false;
  ValueChanged<ManualProductSpeechRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<ManualProductSpeechFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<ManualProductSpeechFailure?> startListening({
    required ValueChanged<ManualProductSpeechRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<ManualProductSpeechFailure> onError,
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
      ManualProductSpeechRecognition(transcript: transcript, isFinal: true),
    );
  }

  void emitError(ManualProductSpeechFailure failure) {
    _onError?.call(failure);
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

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    final before = tester.widget<Switch>(find.byType(Switch));
    expect(before.value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final after = tester.widget<Switch>(find.byType(Switch));
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
