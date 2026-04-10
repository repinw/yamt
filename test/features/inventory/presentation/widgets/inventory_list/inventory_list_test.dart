import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list.dart';
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
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryList(
          items: items,
          preparedMeals: const <PreparedMeal>[],
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
}
