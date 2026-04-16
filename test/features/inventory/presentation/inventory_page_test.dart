import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../calories/support/fake_calories_repositories.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _FakeInventoryDiscardEventRepository
    implements InventoryDiscardEventRepository {
  final List<InventoryDiscardEvent> savedEvents = <InventoryDiscardEvent>[];

  @override
  Future<List<InventoryDiscardEvent>> readAll() async {
    return List<InventoryDiscardEvent>.from(savedEvents);
  }

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async {
    savedEvents.add(event);
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
    return Stream<List<InventoryItem>>.multi((controller) async {
      final watchSubscription = _watchController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      await _loadItems().then(controller.add, onError: controller.addError);
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

class _RecordingGlobalFoodItemRepository implements GlobalFoodItemRepository {
  final List<GlobalFoodItem> appendedItems = <GlobalFoodItem>[];

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async {
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return const <GlobalFoodItem>[];
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() {
    return const Stream<List<GlobalFoodItem>>.empty();
  }
}

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastQuery;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    lastQuery = query;
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return results;
  }
}

class _RecordingCommitStore implements InventoryCalorieEntryCommitStore {
  PendingInventoryConsumption? pendingConsumption;
  CalorieEntry? entry;

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    this.entry = entry;
    this.pendingConsumption = pendingConsumption;
    return InventoryCalorieEntryCommitResult(
      itemId: pendingConsumption.itemId,
      quantity: 1,
      currentAmount: 1000 - pendingConsumption.amount,
    );
  }
}

class _DelayedStageInventoryItemsController extends InventoryItemsController {
  _DelayedStageInventoryItemsController({
    required List<InventoryItem> initialItems,
    required Future<void> Function() waitForStage,
    this.onStageStarted,
  }) : _initialItems = initialItems,
       _waitForStage = waitForStage;

  final List<InventoryItem> _initialItems;
  final Future<void> Function() _waitForStage;
  final VoidCallback? onStageStarted;
  final List<String> discardedPendingIds = <String>[];

  @override
  FutureOr<List<InventoryItem>> build() => _initialItems;

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    onStageStarted?.call();
    await _waitForStage();
    return PendingInventoryConsumption(
      id: 'pending-delayed',
      itemId: itemId,
      amount: amount,
    );
  }

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    discardedPendingIds.add(draftId);
    return true;
  }
}

class _RecordingInventoryItemsController extends InventoryItemsController {
  _RecordingInventoryItemsController({
    required List<InventoryItem> initialItems,
  }) : _initialItems = initialItems;

  final List<InventoryItem> _initialItems;
  final List<String> discardedPendingIds = <String>[];

  @override
  FutureOr<List<InventoryItem>> build() => _initialItems;

  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    return PendingInventoryConsumption(
      id: 'pending-recorded',
      itemId: itemId,
      amount: amount,
    );
  }

  @override
  Future<bool> discardPendingConsumption(String draftId) async {
    discardedPendingIds.add(draftId);
    return true;
  }
}

InventoryItem _item(
  String id, {
  String? brand,
  String? name,
  String? ocrName,
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
    unitPrice: 1,
    weight: weight,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    brand: brand,
    ocrName: ocrName,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

InventoryItem _itemWithNutrition(
  String id, {
  int initialAmount = 1000,
  int currentAmount = 1000,
}) {
  return InventoryItem.create(
    id: id,
    globalFoodItemId: 'off-4061458029995',
    name: 'Milk',
    brand: 'Acme',
    barcode: '4061458029995',
    imageUrl: 'https://example.com/milk.png',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
      per100Protein: 3.3,
      per100Carbs: 4.8,
      per100Fat: 3.5,
    ),
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
    weight: '1000g',
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _amountItemWithoutNutrition(String id) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
    weight: '1000g',
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
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
    estimatedUnitPrice: 1,
  );
}

@Dependencies([InventoryItemsController, PreparedMealsController])
Widget _buildTestApp(
  InventoryItemRepository repository, {
  List<Override> overrides = const <Override>[],
  bool includeDefaultBarcodeFlagsOverride = true,
  GoRoute? calorieEntryRoute,
  Widget Function(Widget child)? shellBuilder,
}) {
  final routes = <RouteBase>[
    GoRoute(
      path: AppRoutes.root,
      builder: (context, state) {
        const page = InventoryPage();
        if (shellBuilder == null) {
          return const Scaffold(body: InventoryPage());
        }
        return shellBuilder(page);
      },
    ),
  ];
  if (calorieEntryRoute != null) {
    routes.add(calorieEntryRoute);
  }
  final router = GoRouter(routes: routes);
  return ProviderScope(
    overrides: <Override>[
      inventoryItemRepositoryProvider.overrideWithValue(repository),
      inventoryDiscardEventRepositoryProvider.overrideWithValue(
        _FakeInventoryDiscardEventRepository(),
      ),
      if (includeDefaultBarcodeFlagsOverride)
        barcodeBackfillFeatureFlagsProvider.overrideWithValue(
          const BarcodeBackfillFeatureFlags(
            showInventoryBarcodeMarkers: false,
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

Finder _stockLabel(String text) => find.text(text, findRichText: true);

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _scrollUntilVisible(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapAmountDialogConfirm(WidgetTester tester) async {
  final confirmButton = find.byKey(
    const Key('inventory_item_amount_dialog_confirm_button'),
  );
  await tester.ensureVisible(confirmButton);
  await tester.tap(confirmButton);
  await tester.pumpAndSettle();
}

@Dependencies([InventoryItemsController, PreparedMealsController])
void main() {
  testWidgets('shows empty state when repository has no items', (tester) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No items in your fridge yet. Scan a receipt or add foods manually.',
      ),
      findsOneWidget,
    );
    expect(find.byType(InventoryActionFab), findsOneWidget);
    expect(
      find.byKey(const Key('inventory_empty_state_fab_highlight')),
      findsOneWidget,
    );
  });

  testWidgets('empty state card stays above fab overlay chrome', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        shellBuilder: (child) {
          return Scaffold(
            body: child,
            floatingActionButton: const SizedBox.square(
              key: Key('test_inventory_fab'),
              dimension: 64,
            ),
            bottomNavigationBar: const SizedBox(height: 96),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final emptyStateText = find.text(
      'No items in your fridge yet. Scan a receipt or add foods manually.',
    );
    final emptyStateCard = find.ancestor(
      of: emptyStateText,
      matching: find.byType(DecoratedBox),
    );
    final fab = find.byKey(const Key('test_inventory_fab'));

    expect(emptyStateCard, findsWidgets);
    expect(
      tester.getRect(emptyStateCard.first).bottom,
      lessThan(tester.getRect(fab).top),
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
        _item('a', name: 'Apple', quantity: 0),
        _item('b', name: 'Banana'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('Banana'));

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Filter items'));
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    await _tapVisible(tester, find.byTooltip('Close'));
    await _scrollUntilVisible(tester, find.text('Banana'));

    expect(find.text('Apple'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Filter items'));
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
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

    await _scrollUntilVisible(tester, _stockLabel('500g / 1000g'));

    expect(_stockLabel('500g / 1000g'), findsOneWidget);
  });

  testWidgets('shows barcode missing marker when feature flag is enabled', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a'),
      ],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <Override>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
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
        _item('a').copyWith(
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
        overrides: <Override>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
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

  testWidgets('swap candidate opens picker and persists the selected item', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item(
          'a',
          name: 'Milk',
          ocrName: 'MILCH 3,5%',
        ),
      ],
    );
    final globalRepository = _RecordingGlobalFoodItemRepository();
    final offRepository = _RecordingOffProductSearchRepository(
      <OffProductSearchResult>[
        const OffProductSearchResult(
          code: '4061458029995',
          name: 'Oat Drink',
          brand: 'Oatly',
          packageWeight: '1000 ml',
          score: 34,
        ),
      ],
    );
    final matcher = GlobalFoodItemMatcher(
      offProductSearchRepository: offRepository,
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <Override>[
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: true,
              enableQueueBackfill: false,
            ),
          ),
          globalFoodItemRepositoryProvider.overrideWithValue(globalRepository),
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Milk'));

    await _tapVisible(tester, find.text('Swap candidate'));

    expect(find.text('Select product'), findsOneWidget);
    expect(find.text('Oat Drink'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Oat Drink').last);
    await tester.pumpAndSettle();

    final savedItems = await repository.readAll();
    expect(savedItems.single.name, 'Oat Drink');
    expect(savedItems.single.brand, 'Oatly');
    expect(savedItems.single.globalFoodItemId, 'off-4061458029995');
    expect(savedItems.single.weight, '1000 ml');
    expect(savedItems.single.initialAmount, 2000);
    expect(savedItems.single.currentAmount, 2000);
    expect(globalRepository.appendedItems, hasLength(1));
    expect(offRepository.lastQuery, 'MILCH 3,5%');
  });

  testWidgets(
    'swap candidate shows feedback when the item is no longer complete',
    (tester) async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => <InventoryItem>[
          _item('a', name: 'Milk', quantity: 1),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Milk'));
      await _tapVisible(tester, find.text('Swap candidate'));

      expect(
        find.text(
          'You can swap the candidate only while the item is still fully '
          'available.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('edit action currently shows not-implemented feedback', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[
        _item('a', name: 'Milk'),
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

    expect(find.text('Item deleted.'), findsNothing);
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
  });

  testWidgets('delete undo snackbar dismisses itself after its timeout', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_item('a', name: 'Milk')],
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Milk'));
    await _tapVisible(tester, find.text('Delete'));

    expect(find.text('Item deleted.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Item deleted.'), findsNothing);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('eat action direct-saves local nutrition', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_itemWithNutrition('a')],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final commitStore = _RecordingCommitStore();
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    CalorieEntryCreateArgs? openedArgs;
    addTearDown(repository.dispose);
    addTearDown(calorieLogRepository.dispose);

    when(() => user.uid).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        calorieEntryRoute: GoRoute(
          path: AppRoutes.homeCaloriesEntryCreate,
          builder: (context, state) {
            openedArgs = state.extra as CalorieEntryCreateArgs?;
            return const Scaffold(body: Text('editor'));
          },
        ),
        overrides: <Override>[
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, _stockLabel('1000g / 1000g'));

    expect(_stockLabel('1000g / 1000g'), findsOneWidget);

    await _tapVisible(tester, find.byTooltip('Eat'));

    expect(find.text('LOG FOOD'), findsOneWidget);
    expect(find.text('Milk'), findsWidgets);
    expect(find.text('All'), findsOneWidget);

    final amountField = find.byKey(
      const Key('inventory_item_amount_dialog_field'),
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '120');

    await _tapAmountDialogConfirm(tester);

    expect(find.text('editor'), findsNothing);
    expect(openedArgs, isNull);
    expect(commitStore.pendingConsumption?.amount, 120);
    expect(commitStore.entry?.consumedAmount, 120);
    expect(commitStore.entry?.mealType, MealType.breakfast);
  });

  testWidgets('eat action quick select all direct-saves remaining amount', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => <InventoryItem>[_itemWithNutrition('a')],
    );
    final calorieLogRepository = FakeCalorieLogRepository();
    final commitStore = _RecordingCommitStore();
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    CalorieEntryCreateArgs? openedArgs;
    addTearDown(repository.dispose);
    addTearDown(calorieLogRepository.dispose);

    when(() => user.uid).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        calorieEntryRoute: GoRoute(
          path: AppRoutes.homeCaloriesEntryCreate,
          builder: (context, state) {
            openedArgs = state.extra as CalorieEntryCreateArgs?;
            return const Scaffold(body: Text('editor'));
          },
        ),
        overrides: <Override>[
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
          firebaseAuthProvider.overrideWithValue(auth),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, _stockLabel('1000g / 1000g'));
    await _tapVisible(tester, find.byTooltip('Eat'));
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    await _tapAmountDialogConfirm(tester);

    expect(find.text('editor'), findsNothing);
    expect(openedArgs, isNull);
    expect(commitStore.pendingConsumption?.amount, 1000);
    expect(commitStore.entry?.consumedAmount, 1000);
  });

  testWidgets(
    'eat action with missing local nutrition discards pending consumption '
    'and shows feedback',
    (tester) async {
      final repository = _FakeFridgeItemRepository(
        onReadAll: () async => const <InventoryItem>[],
      );
      final controller = _RecordingInventoryItemsController(
        initialItems: <InventoryItem>[_amountItemWithoutNutrition('a')],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildTestApp(
          repository,
          overrides: <Override>[
            inventoryItemsControllerProvider.overrideWith(() => controller),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byTooltip('Eat'));

      final amountField = find.byKey(
        const Key('inventory_item_amount_dialog_field'),
      );
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '100');

      await _tapAmountDialogConfirm(tester);

      expect(controller.discardedPendingIds, <String>['pending-recorded']);
      expect(find.text('Action failed. Please try again.'), findsOneWidget);
    },
  );

  testWidgets('unmount during staged eat discards pending consumption', (
    tester,
  ) async {
    final repository = _FakeFridgeItemRepository(
      onReadAll: () async => const <InventoryItem>[],
    );
    final stageCompleter = Completer<void>();
    final stageStartedCompleter = Completer<void>();
    final controller = _DelayedStageInventoryItemsController(
      initialItems: <InventoryItem>[
        _item('a', quantity: 3, initialQuantity: 3),
      ],
      waitForStage: () => stageCompleter.future,
      onStageStarted: () {
        if (!stageStartedCompleter.isCompleted) {
          stageStartedCompleter.complete();
        }
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildTestApp(
        repository,
        includeDefaultBarcodeFlagsOverride: false,
        overrides: <Override>[
          inventoryItemsControllerProvider.overrideWith(() => controller),
          barcodeBackfillFeatureFlagsProvider.overrideWithValue(
            const BarcodeBackfillFeatureFlags(
              showInventoryBarcodeMarkers: false,
              enableQueueBackfill: true,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byTooltip('Eat'));
    await tester.enterText(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      '1',
    );
    final confirmButton = find.byKey(
      const Key('inventory_item_amount_dialog_confirm_button'),
    );
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    while (!stageStartedCompleter.isCompleted) {
      await tester.pump();
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    stageCompleter.complete();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.discardedPendingIds, <String>['pending-delayed']);
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
          overrides: <Override>[
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
          overrides: <Override>[
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
        overrides: <Override>[
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
        overrides: <Override>[
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
        overrides: <Override>[
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

    await _tapAmountDialogConfirm(tester);

    expect(find.text('Please enter valid numbers.'), findsOneWidget);
    expect(amountField, findsOneWidget);
    expect(_stockLabel('3 /3'), findsOneWidget);
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

    await _tapAmountDialogConfirm(tester);
    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_item_amount_dialog_field')),
      findsNothing,
    );
    expect(_stockLabel('2 /3'), findsOneWidget);
  });
}
