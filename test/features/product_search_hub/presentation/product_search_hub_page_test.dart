import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_coordinator.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_product_search_hub_completion_handler.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> _pumpHarness(
  WidgetTester tester, {
  List<InventoryItem> recentItems = const <InventoryItem>[],
  Widget child = const ProductSearchHubPage(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          _FakeInventoryItemRepository(recentItems),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

Future<void> _pumpRouteHarness(
  WidgetTester tester, {
  required ProductSearchHubRouteArgs args,
  List<InventoryItem> recentItems = const <InventoryItem>[],
  OffProductSearchResult? searchRouteProductResult,
  List<Object?> searchRouteResults = const <Object?>[],
  ProductSearchHubEditedResult? searchRouteEditedResult,
  InventoryItemsController? inventoryController,
  FirebaseAuth? firebaseAuth,
  InventoryCalorieEntryCommitStore? commitStore,
  ValueChanged<ProductSearchHubRouteArgs>? onSearchRouteArgs,
  ValueChanged<ManualProductSearchRouteArgs>? onChildRouteArgs,
}) async {
  var searchRouteProductResultIndex = 0;

  Object? nextSearchRouteResult() {
    if (searchRouteResults.isNotEmpty) {
      final index = searchRouteProductResultIndex < searchRouteResults.length
          ? searchRouteProductResultIndex
          : searchRouteResults.length - 1;
      searchRouteProductResultIndex += 1;
      return searchRouteResults[index];
    }
    if (searchRouteEditedResult != null) {
      return searchRouteEditedResult;
    }
    return searchRouteProductResult;
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return ProductSearchHubPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHubSearch,
        builder: (context, state) {
          onSearchRouteArgs?.call(state.extra! as ProductSearchHubRouteArgs);
          return Scaffold(
            body: Column(
              children: [
                const Text('focused search route'),
                if (searchRouteProductResult != null ||
                    searchRouteResults.isNotEmpty ||
                    searchRouteEditedResult != null)
                  FilledButton(
                    key: const Key('return_search_product_result'),
                    onPressed: () {
                      context.pop<Object?>(nextSearchRouteResult());
                    },
                    child: const Text('return product'),
                  ),
              ],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        builder: (context, state) {
          final payloadStore = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(manualProductSearchRoutePayloadStoreProvider);
          final childArgs = ManualProductSearchRouteArgs.tryParse(
            state,
            payloadStore,
          );
          if (childArgs != null) {
            onChildRouteArgs?.call(childArgs);
          }
          return const Scaffold(body: Text('product search child route'));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          _FakeInventoryItemRepository(recentItems),
        ),
        if (inventoryController != null)
          inventoryItemsControllerProvider.overrideWith(
            () => inventoryController,
          ),
        if (firebaseAuth != null)
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
        if (commitStore != null)
          inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
        productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
          final container = ref.container;
          return (mode) => switch (mode) {
            ProductSearchHubMode.inventory =>
              InventoryProductSearchHubCompletionHandler(container: container),
            ProductSearchHubMode.diary =>
              DiaryProductSearchHubCompletionHandler(
                container: container,
                eatCoordinator: container.read(
                  inventoryManualProductEatCoordinatorProvider,
                ),
              ),
            ProductSearchHubMode.selection =>
              const SelectionProductSearchHubCompletionHandler(),
          };
        }),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          if (inventoryController != null) {
            ref.watch(inventoryItemsControllerProvider);
          }
          return MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders product search hub shell', (tester) async {
    await _pumpHarness(tester);
    await tester.pumpAndSettle();

    expect(find.text('Add to inventory'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_barcode_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_ai_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_receipt_action')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('product_search_hub_inventory_action')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('product_search_hub_meal_action')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('product_search_hub_create_own_action')),
      findsOneWidget,
    );
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Receipt'), findsNothing);
    expect(find.text('From inventory'), findsNothing);
    expect(find.text('Meal'), findsNothing);
    expect(find.text('Create'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_search_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_recently_selected_empty_state')),
      findsOneWidget,
    );
    expect(find.text('Recently selected'), findsOneWidget);
  });

  testWidgets('diary mode renders diary title and source actions', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      child: const ProductSearchHubPage(
        args: ProductSearchHubRouteArgs.diary(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eat food'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_receipt_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_inventory_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_meal_action')),
      findsOneWidget,
    );
    _expectOutlinedActionEnabled(
      tester,
      const Key('product_search_hub_receipt_action'),
      isEnabled: false,
    );
    _expectOutlinedActionEnabled(
      tester,
      const Key('product_search_hub_inventory_action'),
      isEnabled: false,
    );
    _expectOutlinedActionEnabled(
      tester,
      const Key('product_search_hub_meal_action'),
      isEnabled: false,
    );
  });

  testWidgets('selection mode renders generic title without source actions', (
    tester,
  ) async {
    await _pumpHarness(
      tester,
      child: ProductSearchHubPage(
        args: ProductSearchHubRouteArgs.selection(
          item: _item(id: 'item-1', name: 'Milk'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add product'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_receipt_action')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('product_search_hub_inventory_action')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('product_search_hub_meal_action')),
      findsNothing,
    );
  });

  testWidgets('renders recently selected products', (tester) async {
    await _pumpHarness(
      tester,
      recentItems: [
        _item(
          id: 'recent-yogurt',
          name: 'Greek yogurt',
          brand: 'Dairy Co',
          weight: '500 g',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('product_search_hub_recently_selected_item_recent-yogurt'),
      ),
      findsOneWidget,
    );
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('Dairy Co'), findsOneWidget);
  });

  testWidgets('renders recently selected tab', (tester) async {
    await _pumpHarness(tester);
    await tester.pumpAndSettle();

    expect(find.text('Recently selected'), findsOneWidget);
  });

  testWidgets('search initial intent opens focused search route', (
    tester,
  ) async {
    ProductSearchHubRouteArgs? searchArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      onSearchRouteArgs: (args) => searchArgs = args,
    );
    await tester.pumpAndSettle();

    expect(find.text('focused search route'), findsOneWidget);
    expect(searchArgs?.mode, ProductSearchHubMode.inventory);
    expect(searchArgs?.initialIntent, ProductSearchHubInitialIntent.search);
  });

  testWidgets('diary search result opens eat sheet without editor', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: ProductSearchHubRouteArgs.diary(
        initialIntent: ProductSearchHubInitialIntent.search,
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: DateTime(2026, 4, 13, 12),
      ),
      searchRouteProductResult: _searchProduct(),
      inventoryController: inventoryController,
      onChildRouteArgs: (args) => childArgs = args,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pumpAndSettle();

    expect(childArgs, isNull);
    expect(inventoryController.addedItems, isEmpty);
    expect(
      find.byKey(const Key('eat_page_amount_field')),
      findsOneWidget,
    );
  });

  testWidgets('diary direct search log-only save shows no overlay', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);

    await _pumpRouteHarness(
      tester,
      args: ProductSearchHubRouteArgs.diary(
        initialIntent: ProductSearchHubInitialIntent.search,
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: DateTime(2026, 4, 13, 12),
      ),
      searchRouteEditedResult: ProductSearchHubEditedResult(
        sourceKey: 'manual-source',
        result: _diaryEatResult(),
      ),
      inventoryController: inventoryController,
      firebaseAuth: firebaseAuth,
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pumpAndSettle();

    expect(find.text('focused search route'), findsNothing);
    expect(find.text('Eat food'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_selection_overlay')),
      findsNothing,
    );
    expect(inventoryController.addedItems, hasLength(1));
  });

  testWidgets('diary add-more eat stays in hub with overlay', (tester) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);

    await _pumpRouteHarness(
      tester,
      args: ProductSearchHubRouteArgs.diary(
        initialIntent: ProductSearchHubInitialIntent.search,
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: DateTime(2026, 4, 13, 12),
      ),
      searchRouteProductResult: _searchProduct(),
      inventoryController: inventoryController,
      firebaseAuth: firebaseAuth,
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pumpAndSettle();
    final addMoreButton = find.byKey(
      const Key('inventory_item_amount_dialog_add_more_button'),
    );
    await tester.ensureVisible(addMoreButton);
    await tester.tap(addMoreButton);
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      () => find
          .byKey(const Key('product_search_hub_selection_overlay'))
          .evaluate()
          .isNotEmpty,
    );

    expect(find.text('focused search route'), findsNothing);
    expect(find.text('Eat food'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_selection_overlay')),
      findsOneWidget,
    );
    expect(inventoryController.addedItems, hasLength(1));
  });

  testWidgets('diary batch mode makes next add continue to overlay', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();
    final firebaseAuth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => firebaseAuth.currentUser).thenReturn(user);

    await _pumpRouteHarness(
      tester,
      args: ProductSearchHubRouteArgs.diary(
        initialIntent: ProductSearchHubInitialIntent.search,
        preselectedMealType: MealType.lunch,
        preselectedLoggedAt: DateTime(2026, 4, 13, 12),
      ),
      searchRouteResults: [
        ProductSearchHubEditedResult(
          sourceKey: 'manual-source-1',
          result: _diarySheetResult(id: 'manual-item-1', name: 'Milk'),
        ),
        ProductSearchHubEditedResult(
          sourceKey: 'manual-source-2',
          result: _diarySheetResult(id: 'manual-item-2', name: 'Bread'),
        ),
      ],
      inventoryController: inventoryController,
      firebaseAuth: firebaseAuth,
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pumpAndSettle();
    final addMoreButton = find.byKey(
      const Key('inventory_item_amount_dialog_add_more_button'),
    );
    await tester.ensureVisible(addMoreButton);
    await tester.tap(addMoreButton);
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      () => find
          .byKey(const Key('product_search_hub_selection_overlay'))
          .evaluate()
          .isNotEmpty,
    );

    await tester.ensureVisible(
      find.byKey(const Key('product_search_hub_search_field')),
    );
    await tester.tap(find.byKey(const Key('product_search_hub_search_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pump();

    final addButton = find.byKey(
      const Key('inventory_item_amount_dialog_confirm_button'),
    );
    await _pumpUntil(tester, () => addButton.evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_add_more_button')),
      findsNothing,
    );

    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find
          .byKey(const Key('product_search_hub_selection_overlay'))
          .evaluate()
          .isNotEmpty,
    );

    expect(find.text('focused search route'), findsNothing);
    expect(
      find.byKey(const Key('product_search_hub_selection_overlay')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('product_search_hub_cart_count_button')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(inventoryController.addedItems, hasLength(2));
  });

  testWidgets('inventory search result still opens product editor', (
    tester,
  ) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      searchRouteProductResult: _searchProduct(),
      onChildRouteArgs: (args) => childArgs = args,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_search_product_result')));
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);
  });

  testWidgets('AI initial intent opens AI child route', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.ai,
      ),
      onChildRouteArgs: (args) => childArgs = args,
    );
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.aiSearch);
    expect(childArgs?.showEatImmediatelyOption, isFalse);
  });

  testWidgets('barcode initial intent opens barcode scanner sheet', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.barcode,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan barcode'), findsOneWidget);
  });

  testWidgets(
    'diary mode copy search result opens editor instead of direct eat',
    (tester) async {
      ManualProductSearchRouteArgs? childArgs;
      final inventoryController = _SuccessfulInventoryItemsController();

      await _pumpRouteHarness(
        tester,
        args: ProductSearchHubRouteArgs.diary(
          initialIntent: ProductSearchHubInitialIntent.search,
          preselectedMealType: MealType.lunch,
          preselectedLoggedAt: DateTime(2026, 4, 13, 12),
        ),
        searchRouteResults: [ProductSearchHubCopyResult(_searchProduct())],
        inventoryController: inventoryController,
        onChildRouteArgs: (args) => childArgs = args,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('return_search_product_result')));
      await tester.pumpAndSettle();

      expect(childArgs, isNotNull);
      expect(childArgs?.item.name, 'Search Milk');
      expect(childArgs?.initialInfoMessage, isNotNull);
    },
  );

  testWidgets('copying recently selected product opens editor', (tester) async {
    ManualProductSearchRouteArgs? childArgs;
    final inventoryController = _SuccessfulInventoryItemsController();

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(),
      recentItems: [
        _item(
          id: 'recent-yogurt',
          name: 'Greek yogurt',
          brand: 'Dairy Co',
          weight: '500 g',
        ),
      ],
      inventoryController: inventoryController,
      onChildRouteArgs: (args) => childArgs = args,
    );
    await tester.pumpAndSettle();

    final copyButton = find.byKey(
      const Key('product_search_hub_recently_selected_copy_recent-yogurt'),
    );
    expect(copyButton, findsOneWidget);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(childArgs, isNotNull);
    expect(childArgs?.item.name, 'Greek yogurt');
    expect(childArgs?.item.id, isNot('recent-yogurt'));
    expect(childArgs?.initialInfoMessage, isNotNull);
  });
}

void _expectOutlinedActionEnabled(
  WidgetTester tester,
  Key actionKey, {
  required bool isEnabled,
}) {
  final buttonFinder = find.descendant(
    of: find.byKey(actionKey),
    matching: find.byType(OutlinedButton),
  );
  expect(buttonFinder, findsOneWidget);
  final button = tester.widget<OutlinedButton>(buttonFinder);
  expect(button.onPressed != null, isEnabled);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempts = 0; attempts < 20 && !condition(); attempts++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const new(this._items);

  final List<InventoryItem> _items;

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    return List<InventoryItem>.from(_items.take(limit));
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield List<InventoryItem>.from(_items);
  }
}

class _RecordingInventoryItemsController extends InventoryItemsController {
  final addedItems = <InventoryItem>[];

  @override
  Future<List<InventoryItem>> build() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> addItem(InventoryItem item) async {
    addedItems.add(item);
    return true;
  }
}

class _SuccessfulInventoryItemsController
    extends _RecordingInventoryItemsController {
  @override
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) async {
    return PendingInventoryConsumption(
      id: 'pending-$itemId',
      itemId: itemId,
      amount: amount,
    );
  }
}

class _SuccessfulInventoryCalorieEntryCommitStore
    implements InventoryCalorieEntryCommitStore {
  const new();

  @override
  Future<InventoryCalorieEntryCommitResult?> commitEntryAndInventory({
    required CalorieEntry entry,
    required PendingInventoryConsumption pendingConsumption,
  }) async {
    return InventoryCalorieEntryCommitResult(
      itemId: pendingConsumption.itemId,
      quantity: 1,
      currentAmount: 400,
    );
  }
}

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  String? weight,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    brand: brand,
    weight: weight,
    entryDate: DateTime.utc(2026),
    storeName: 'Store',
    quantity: 1,
    origin: InventoryItemOrigin.manualAdd,
  );
}

OffProductSearchResult _searchProduct({
  String code = '4006381333931',
  String name = 'Search Milk',
}) {
  return OffProductSearchResult(
    code: code,
    name: name,
    brand: 'Dairy Co',
    score: 1,
    packageWeight: '100 g',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
      per100Carbs: 4.8,
      per100Protein: 3.4,
      per100Fat: 3.5,
    ),
  );
}

InventoryReceiptManualProductResult _diaryEatResult() {
  return InventoryReceiptManualProductResult(
    item: _itemWithNutrition(id: 'manual-item', name: 'Search Milk'),
    action: InventoryReceiptManualProductAction.eatNow,
    requiresGlobalPersistence: false,
    skipMissingBarcodePrompt: true,
    eatSelection: EatSelection(
      inventoryAmount: 500,
      loggedAt: DateTime(2026, 4, 13, 12),
      mealType: MealType.lunch,
    ),
  );
}

InventoryReceiptManualProductResult _diarySheetResult({
  required String id,
  required String name,
}) {
  return InventoryReceiptManualProductResult(
    item: _itemWithNutrition(id: id, name: name),
    action: InventoryReceiptManualProductAction.eatNow,
    requiresGlobalPersistence: false,
    skipMissingBarcodePrompt: true,
  );
}

InventoryItem _itemWithNutrition({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    brand: 'Dairy Co',
    entryDate: DateTime.utc(2026),
    storeName: 'Store',
    quantity: 1,
    weight: '500 g',
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
      per100Carbs: 4.8,
      per100Protein: 3.4,
      per100Fat: 3.5,
    ),
  );
}
