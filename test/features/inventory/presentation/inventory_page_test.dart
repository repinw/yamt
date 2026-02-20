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

FridgeItem _item(
  String id, {
  String? brand,
  String? name,
  String? receiptId,
  DateTime? receiptDate,
}) {
  return FridgeItem(
    id: id,
    name: name ?? 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1.0,
    brand: brand,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

Widget _buildTestApp(FridgeItemRepository repository) {
  return ProviderScope(
    overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      locale: const Locale('en'),
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
      onReadAll: () async => <FridgeItem>[_item('a', brand: 'Acme')],
    );

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('No receipt'), findsOneWidget);
    expect(find.textContaining('Store'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('Total quantity'), findsOneWidget);
    expect(find.text('Estimated value'), findsOneWidget);

    await tester.tap(find.text('No receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('ACME'), findsOneWidget);
  });

  testWidgets('groups items under one receipt and expands on tap', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[
        _item('a', name: 'Milk', receiptId: 'abc123999'),
        _item('b', name: 'Bread', receiptId: 'abc123999'),
      ],
    );

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Receipt #abc123'), findsOneWidget);
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Bread'), findsNothing);

    await tester.tap(find.text('Receipt #abc123'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });
}
