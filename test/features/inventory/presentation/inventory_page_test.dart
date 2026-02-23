import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeFridgeItemRepository implements FridgeItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<FridgeItem>> Function() onReadAll;
  final StreamController<List<FridgeItem>> _watchController =
      StreamController<List<FridgeItem>>.broadcast();
  List<FridgeItem> _items = const <FridgeItem>[];
  bool _isInitialized = false;

  @override
  Stream<List<FridgeItem>> watchAll() {
    return Stream<List<FridgeItem>>.multi((controller) {
      final watchSubscription = _watchController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      _loadItems().then(controller.add, onError: controller.addError);
      controller.onCancel = () {
        unawaited(watchSubscription.cancel());
      };
    });
  }

  @override
  Future<List<FridgeItem>> readAll() {
    return _loadItems();
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) async {
    _items = List<FridgeItem>.from(items);
    _isInitialized = true;
    _watchController.add(_items);
    return true;
  }

  @override
  Future<bool> appendAll(List<FridgeItem> items) async {
    return true;
  }

  Future<void> dispose() {
    return _watchController.close();
  }

  Future<List<FridgeItem>> _loadItems() async {
    if (!_isInitialized) {
      _items = List<FridgeItem>.from(await onReadAll());
      _isInitialized = true;
    }
    return List<FridgeItem>.from(_items);
  }
}

FridgeItem _item(
  String id, {
  String? brand,
  String? name,
  String? receiptId,
  DateTime? receiptDate,
  int quantity = 2,
  int initialQuantity = 2,
  String? weight,
  int initialAmount = 0,
  int currentAmount = 0,
  FridgeAmountUnit? amountUnit,
}) {
  return FridgeItem(
    id: id,
    name: name ?? 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1.0,
    weight: weight,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    brand: brand,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

Widget _buildTestApp(FridgeItemRepository repository) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: InventoryPage()),
      ),
    ],
  );

  return ProviderScope(
    overrides: [fridgeItemRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('shows empty state when repository has no items', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <FridgeItem>[],
    );
    addTearDown(repository.dispose);

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
    addTearDown(repository.dispose);

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
    expect(find.textContaining('Store'), findsOneWidget);
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
    addTearDown(repository.dispose);

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

  testWidgets('shows amount-based stock label when amount data exists', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[
        _item(
          'a',
          initialQuantity: 2,
          quantity: 1,
          weight: '500g',
          initialAmount: 1000,
          currentAmount: 500,
          amountUnit: FridgeAmountUnit.gram,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No receipt'));
    await tester.pumpAndSettle();

    expect(find.text('500g / 1000g'), findsOneWidget);
  });

  testWidgets('eat action opens amount dialog and updates stock', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No receipt'));
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.byTooltip('Eat'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(
      const Key('inventory_item_amount_dialog_field'),
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '2');

    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsNothing,
    );
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('eat action validates amount above available stock', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No receipt'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eat'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(
      const Key('inventory_item_amount_dialog_field'),
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '999');

    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsOneWidget);
    expect(amountField, findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets('throw away action opens amount dialog and updates stock', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <FridgeItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No receipt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Throw away'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(
      const Key('inventory_item_amount_dialog_field'),
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '1');

    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsNothing,
    );
    expect(find.text('2/3'), findsOneWidget);
  });
}
