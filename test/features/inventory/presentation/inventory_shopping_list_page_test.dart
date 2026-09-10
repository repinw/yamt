import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_shopping_list_page.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

class _StockRepository implements InventoryItemRepository {
  bool fail = false;
  int watchCount = 0;
  @override
  Stream<List<InventoryItem>> watchAll() {
    watchCount++;
    return fail
        ? Stream.error(StateError('offline'))
        : Stream.value([
            InventoryItem.create(
              id: 'milk',
              name: 'Milk',
              entryDate: DateTime.now(),
              storeName: 'Shop',
              quantity: 0,
            ),
          ]);
  }

  @override
  Future<List<InventoryItem>> readAll() async => [];
  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;
  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

@Dependencies([inventoryShoppingSuggestions])
Future<FakeShoppingListRepository> _pump(
  WidgetTester tester,
  _StockRepository stock,
) async {
  final repository = FakeShoppingListRepository();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(stock),
      shoppingListRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InventoryShoppingListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

@Dependencies([inventoryShoppingSuggestions])
void main() {
  testWidgets(
    'integrated page reads inventory and adds a low-stock suggestion',
    (tester) async {
      final repository = await _pump(tester, _StockRepository());
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Low stock'), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
      await tester.tap(find.byTooltip('Add item'));
      await tester.pumpAndSettle();
      expect(repository.savedItems.single.name, 'Milk');
      expect(find.text('Out of stock'), findsNothing);
    },
  );

  testWidgets(
    'source errors keep shopping usable and retry reloads inventory',
    (tester) async {
      final stock = _StockRepository()..fail = true;
      await _pump(tester, stock);
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
      expect(find.text('Reload suggestions'), findsOneWidget);
      stock.fail = false;
      await tester.tap(find.text('Reload suggestions'));
      await tester.pumpAndSettle();
      expect(stock.watchCount, 2);
      expect(find.text('Milk'), findsOneWidget);
    },
  );
}
