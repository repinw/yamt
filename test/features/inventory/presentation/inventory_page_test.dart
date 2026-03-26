import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

class _NoopBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  @override
  Future<bool> enqueueFingerprintLookup({
    String? itemId,
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  }) async {
    return true;
  }

  @override
  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
  }) async {
    return true;
  }

  @override
  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  ) async {
    return null;
  }

  @override
  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  }) async {
    return true;
  }
}

class _RecordingBackfillRepository
    implements CalorieBarcodeBackfillRepositoryContract {
  int enqueueCalls = 0;
  String? lastItemId;
  String? lastFingerprint;
  String? lastItemName;
  String? lastBrand;
  String? lastTrigger;
  bool lastForceRetry = false;
  int enqueueBatchCalls = 0;

  @override
  Future<bool> enqueueFingerprintLookup({
    String? itemId,
    required String fingerprint,
    required String itemName,
    String? brand,
    required String trigger,
    bool forceRetry = false,
  }) async {
    enqueueCalls += 1;
    lastItemId = itemId;
    lastFingerprint = fingerprint;
    lastItemName = itemName;
    lastBrand = brand;
    lastTrigger = trigger;
    lastForceRetry = forceRetry;
    return true;
  }

  @override
  Future<bool> enqueueBatchLookup({
    required List<BarcodeLookupBatchItem> items,
    required String trigger,
  }) async {
    enqueueBatchCalls += 1;
    return true;
  }

  @override
  Future<CalorieProductProfile?> getResolvedProfileByFingerprint(
    String fingerprint,
  ) async {
    return null;
  }

  @override
  Future<bool> submitUserProvidedBarcode({
    required String fingerprint,
    required String barcode,
    required String itemName,
    String? brand,
  }) async {
    return true;
  }
}

class _FakeFridgeItemRepository implements InventoryItemRepository {
  _FakeFridgeItemRepository({required this.onReadAll});

  final Future<List<InventoryItem>> Function() onReadAll;
  final StreamController<List<InventoryItem>> _watchController =
      StreamController<List<InventoryItem>>.broadcast();
  List<InventoryItem> _items = const <InventoryItem>[];
  bool _isInitialized = false;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.multi((controller) {
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
  Future<List<InventoryItem>> readAll() {
    return _loadItems();
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    _items = List<InventoryItem>.from(items);
    _isInitialized = true;
    _watchController.add(_items);
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  Future<void> dispose() {
    return _watchController.close();
  }

  Future<List<InventoryItem>> _loadItems() async {
    if (!_isInitialized) {
      _items = List<InventoryItem>.from(await onReadAll());
      _isInitialized = true;
    }
    return List<InventoryItem>.from(_items);
  }
}

InventoryItem _item(
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
  InventoryAmountUnit? amountUnit,
}) {
  return InventoryItem.create(
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

ShoppingListItem _shoppingItem(
  String id, {
  required String name,
  String? brand,
  int quantity = 1,
}) {
  final normalizedName = name.trim().toLowerCase();
  final normalizedBrand = (brand ?? '').trim().toLowerCase();
  return ShoppingListItem(
    id: id,
    name: name,
    brand: brand,
    normalizedName: normalizedName,
    normalizedBrand: normalizedBrand,
    quantity: quantity,
    estimatedUnitPrice: 1.0,
  );
}

Widget _buildTestApp(
  InventoryItemRepository repository, {
  List<dynamic> overrides = const <dynamic>[],
  bool includeDefaultBarcodeFlagsOverride = true,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: InventoryPage()),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(repository),
      if (includeDefaultBarcodeFlagsOverride)
        barcodeBackfillFeatureFlagsProvider.overrideWithValue(
          const BarcodeBackfillFeatureFlags(
            showInventoryBarcodeMarkers: false,
            enableEatBridge: false,
            enableQueueBackfill: false,
          ),
        ),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Finder get _inventoryScrollable => find.byType(Scrollable).first;

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: _inventoryScrollable,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _scrollUntilVisible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state when repository has no items', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
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
      onReadAll: () async => <InventoryItem>[_item('a', brand: 'Acme')],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('By receipt'), findsOneWidget);
    expect(find.text('All foods'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);

    await _scrollUntilVisible(tester, find.text('Milk'));

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('ACME'), findsOneWidget);
  });

  testWidgets('groups items under one receipt and expands on tap', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', receiptId: 'abc123999'),
        _item('b', name: 'Bread', receiptId: 'abc123999'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('By receipt'));

    expect(find.text('Receipt #abc123'), findsOneWidget);

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('all items mode shows consolidated rows', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', receiptId: 'abc123999'),
        _item('b', name: 'Bread', receiptId: 'abc123999'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Receipt #abc123'), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('consumption filters hide and show rows in all-items mode', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Apple', quantity: 0, initialQuantity: 2),
        _item('b', name: 'Banana', quantity: 2, initialQuantity: 2),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Banana'));

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Filter items'));
    await _tapVisible(tester, find.text('Consumed'));
    await _scrollUntilVisible(tester, find.text('Banana'));

    expect(find.text('Apple'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Filter items'));
    await _tapVisible(tester, find.text('Consumed'));
    await _scrollUntilVisible(tester, find.text('Banana'));

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('shows amount-based stock label when amount data exists', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item(
          'a',
          initialQuantity: 2,
          quantity: 1,
          weight: '500g',
          initialAmount: 1000,
          currentAmount: 500,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('500g / 1000g'));

    expect(find.text('500g / 1000g'), findsOneWidget);
  });

  testWidgets('shows barcode missing marker when feature flag is enabled', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 2, initialQuantity: 2),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <dynamic>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
              enableEatBridge: false,
              enableQueueBackfill: false,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _scrollUntilVisible(tester, find.text('Barcode missing'));

    expect(find.text('Barcode missing'), findsOneWidget);
  });

  testWidgets('shows barcode uncertainty marker when flag is set', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 2, initialQuantity: 2).copyWith(
          barcode: '4006381333931',
          barcodeResolvedAt: DateTime.parse('2026-02-20T10:05:00Z'),
          barcodeLookupUncertain: true,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <dynamic>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
              enableEatBridge: false,
              enableQueueBackfill: false,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _scrollUntilVisible(tester, find.text('Not sure'));

    expect(find.text('Not sure'), findsOneWidget);
  });

  testWidgets('search barcode button triggers direct item lookup', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', quantity: 2, initialQuantity: 2),
      ],
    );
    final backfillRepository = _RecordingBackfillRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <dynamic>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
              enableEatBridge: false,
              enableQueueBackfill: false,
            ),
          ),
          calorieBarcodeBackfillRepositoryProvider.overrideWithValue(
            backfillRepository,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Milk'));

    final retryButtonFinder = find.text('Swap candidate');
    expect(retryButtonFinder, findsOneWidget);
    await _tapVisible(tester, retryButtonFinder);

    expect(backfillRepository.enqueueCalls, 1);
    expect(backfillRepository.lastItemId, 'a');
    expect(backfillRepository.lastFingerprint, 'milk');
    expect(backfillRepository.lastItemName, 'Milk');
    expect(backfillRepository.lastTrigger, 'manual_search');
    expect(backfillRepository.lastForceRetry, isFalse);
  });

  testWidgets('edit action currently shows not-implemented feedback', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', quantity: 2, initialQuantity: 2),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Milk'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Edit'));

    expect(find.text('Not implemented yet'), findsOneWidget);
  });

  testWidgets('delete action shows undo snackbar and restores item', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk'),
        _item('b', name: 'Bread'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Milk'));
    await _tapVisible(tester, find.text('Delete'));

    expect(find.text('Item deleted.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Bread'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('eat action opens amount dialog and updates stock', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('3/3'));

    expect(find.text('3/3'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Eat'));

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

  testWidgets('eat action depletes item but keeps it visible', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 1, initialQuantity: 1),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('1/1'));

    expect(find.text('1/1'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Eat'));

    final amountField = find.byKey(
      const Key('inventory_item_amount_dialog_field'),
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '1');

    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
  });

  testWidgets('eat action with missing barcode opens scan-or-later prompt', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item(
          'a',
          quantity: 1,
          initialQuantity: 1,
          weight: '1000g',
          initialAmount: 1000,
          currentAmount: 1000,
          amountUnit: InventoryAmountUnit.gram,
        ),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <dynamic>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
              enableEatBridge: true,
              enableQueueBackfill: true,
            ),
          ),
          calorieBarcodeBackfillRepositoryProvider.overrideWithValue(
            _NoopBackfillRepository(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byTooltip('Eat'));
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '100',
    );
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan barcode now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets(
    'fully consumed item shows buy-again action and success feedback',
    (tester) async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item(
            'a',
            name: 'Milk',
            brand: 'Acme',
            quantity: 0,
            initialQuantity: 1,
          ),
        ],
      );
      final shoppingRepository = FakeShoppingListRepository();
      addTearDown(repository.dispose);
      addTearDown(shoppingRepository.dispose);

      await tester.pumpWidget(
        _buildTestApp(
          repository,
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(
              shoppingRepository,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Buy again'), findsOneWidget);
      expect(find.byTooltip('Eat'), findsNothing);

      await tester.tap(find.byTooltip('Buy again'));
      await tester.pumpAndSettle();

      expect(find.text('Item added to shopping list.'), findsOneWidget);
      expect(shoppingRepository.savedItems, hasLength(1));
      final addedItem = shoppingRepository.savedItems.single;
      expect(addedItem.name, 'Milk');
      expect(addedItem.brand, 'Acme');
      expect(addedItem.quantity, 1);
    },
  );

  testWidgets(
    'buy-again falls back to quantity one when initial quantity is zero',
    (tester) async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a', name: 'Milk', quantity: 0, initialQuantity: 0),
        ],
      );
      final shoppingRepository = FakeShoppingListRepository();
      addTearDown(repository.dispose);
      addTearDown(shoppingRepository.dispose);

      await tester.pumpWidget(
        _buildTestApp(
          repository,
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(
              shoppingRepository,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Buy again'));
      await tester.pumpAndSettle();

      expect(shoppingRepository.savedItems, hasLength(1));
      expect(shoppingRepository.savedItems.single.quantity, 1);
    },
  );

  testWidgets('buy-again action shows add-failed feedback on save failure', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', quantity: 0, initialQuantity: 1),
      ],
    );
    final shoppingRepository = FakeShoppingListRepository()
      ..saveAllShouldFail = true;
    addTearDown(repository.dispose);
    addTearDown(shoppingRepository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buy again'));
    await tester.pumpAndSettle();

    expect(find.text('Action failed. Please try again.'), findsOneWidget);
  });

  testWidgets('buy-again button is disabled when item is already shopping', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item(
          'a',
          name: 'Milk',
          brand: 'Acme',
          quantity: 0,
          initialQuantity: 1,
        ),
      ],
    );
    final shoppingRepository = FakeShoppingListRepository(
      initialItems: <ShoppingListItem>[
        _shoppingItem('s1', name: 'Milk', brand: 'Acme', quantity: 2),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(shoppingRepository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final buyAgainButton = find.ancestor(
      of: find.byIcon(Icons.shopping_cart_checkout_rounded),
      matching: find.byType(IconButton),
    );
    expect(buyAgainButton, findsOneWidget);
    expect(tester.widget<IconButton>(buyAgainButton).onPressed, isNull);
    expect(shoppingRepository.savedItems, isEmpty);
  });

  testWidgets('buy-again does not throw when row unmounts mid-action', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk', quantity: 0, initialQuantity: 1),
      ],
    );
    final shoppingRepository = FakeShoppingListRepository()
      ..saveDelay = const Duration(milliseconds: 80);
    addTearDown(repository.dispose);
    addTearDown(shoppingRepository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buy again'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
  });

  testWidgets('eat action validates amount above available stock', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byTooltip('Eat'));

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
      onReadAll: () async => <InventoryItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Milk'));

    await _tapVisible(tester, find.text('Throw away'));

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
