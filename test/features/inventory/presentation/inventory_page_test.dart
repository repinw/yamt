import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeFridgeItemRepository implements FridgeItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<FridgeItem>> Function() onReadAll;

  @override
  Future<List<FridgeItem>> readAll() {
    return onReadAll();
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<FridgeItem> items) async {
    return true;
  }
}

FridgeItem _item(String id) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1.0,
  );
}

Widget _buildTestApp(FridgeItemRepository repository) {
  return ProviderScope(
    overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: InventoryPage()),
    ),
  );
}

void main() {
  testWidgets('shows empty state when repository has no items', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <FridgeItem>[],
    );

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('No items in your fridge yet. Scan a receipt to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('renders list items when repository returns data', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[_item('a')],
    );

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
