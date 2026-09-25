import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
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
    'product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _searchFieldKey = Key('product_search_hub_search_field');

Future<void> _pumpHarness(
  WidgetTester tester, {
  List<InventoryItem> recentItems = const <InventoryItem>[],
  ProductSearchHubRouteArgs args = const ProductSearchHubRouteArgs.inventory(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceSearchServiceProvider.overrideWithValue(_FakeVoiceSearchService()),
        inventoryItemRepositoryProvider.overrideWithValue(
          _FakeInventoryItemRepository(recentItems),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProductSearchHubPage(args: args),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _pumpKeyboardDelay(tester);
}

/// Opens the page on top of a caller route, like the app does.
Future<void> _pumpRouteHarness(
  WidgetTester tester, {
  required ProductSearchHubRouteArgs args,
  List<InventoryItem> recentItems = const <InventoryItem>[],
  List<OffProductSearchResult> searchResults = const <OffProductSearchResult>[],
  List<InventoryReceiptManualProductResult> childRouteResults =
      const <InventoryReceiptManualProductResult>[],
  InventoryItemsController? inventoryController,
  FirebaseAuth? firebaseAuth,
  InventoryCalorieEntryCommitStore? commitStore,
  ValueChanged<ManualProductSearchRouteArgs>? onChildRouteArgs,
  ValueChanged<Object?>? onPagePopped,
}) async {
  var childRouteResultIndex = 0;

  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const Scaffold(body: Text('caller')),
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => ProductSearchHubPage(
          args: args,
          lookupProducts:
              ({required query, required limit, store, brand, weight}) async {
                return ProductSearchHubSearchLookupResult.success(
                  searchResults,
                );
              },
        ),
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
          return Scaffold(
            body: Column(
              children: [
                const Text('product search child route'),
                if (childRouteResults.isNotEmpty)
                  FilledButton(
                    key: const Key('return_child_result'),
                    onPressed: () =>
                        context.pop(childRouteResults[childRouteResultIndex++]),
                    child: const Text('return product'),
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        voiceSearchServiceProvider.overrideWithValue(_FakeVoiceSearchService()),
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
  await tester.pumpAndSettle();
  unawaited(
    router
        .push<Object?>(AppRoutes.homeProductSearchHub)
        .then((result) => onPagePopped?.call(result)),
  );
  await tester.pumpAndSettle();
  await _pumpKeyboardDelay(tester);
}

Future<void> _pumpKeyboardDelay(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _searchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(_searchFieldKey), query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

bool _searchFieldHasFocus(WidgetTester tester) {
  final field = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(_searchFieldKey),
      matching: find.byType(EditableText),
    ),
  );
  return field.focusNode.hasFocus;
}

ProductSearchHubRouteArgs _diaryArgs({
  ProductSearchHubInitialIntent initialIntent =
      ProductSearchHubInitialIntent.search,
}) {
  return ProductSearchHubRouteArgs.diary(
    initialIntent: initialIntent,
    preselectedMealType: MealType.lunch,
    preselectedLoggedAt: DateTime(2026, 4, 13, 12),
  );
}

_MockFirebaseAuth _signedInAuth() {
  final firebaseAuth = _MockFirebaseAuth();
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  when(() => firebaseAuth.currentUser).thenReturn(user);
  return firebaseAuth;
}

Future<void> _tapAddMore(WidgetTester tester) async {
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
}

void main() {
  testWidgets('renders search page with actions and recent products', (
    tester,
  ) async {
    await _pumpHarness(tester);

    expect(find.text('Add to inventory'), findsOneWidget);
    expect(find.byKey(_searchFieldKey), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_search_barcode_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_search_ai_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
      findsOneWidget,
    );
    expect(find.text('Recently selected'), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_recently_selected_empty_state')),
      findsOneWidget,
    );
  });

  testWidgets('diary mode renders diary title', (tester) async {
    await _pumpHarness(tester, args: const ProductSearchHubRouteArgs.diary());

    expect(find.text('Eat food'), findsOneWidget);
  });

  testWidgets('selection mode renders generic title', (tester) async {
    await _pumpHarness(
      tester,
      args: ProductSearchHubRouteArgs.selection(
        item: _item(id: 'item-1', name: 'Milk'),
      ),
    );

    expect(find.text('Add product'), findsOneWidget);
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

    expect(
      find.byKey(
        const Key('product_search_hub_recently_selected_item_recent-yogurt'),
      ),
      findsOneWidget,
    );
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('Dairy Co'), findsOneWidget);
  });

  testWidgets('search intent focuses the search field', (tester) async {
    await _pumpHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
    );

    expect(_searchFieldHasFocus(tester), isTrue);
  });

  testWidgets('launcher intent leaves the keyboard closed', (tester) async {
    await _pumpHarness(tester);

    expect(_searchFieldHasFocus(tester), isFalse);
  });

  testWidgets('back with nothing selected returns to the caller', (
    tester,
  ) async {
    await _pumpRouteHarness(tester, args: _diaryArgs());

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
    expect(find.byType(ProductSearchHubPage), findsNothing);
  });

  testWidgets('diary search result opens eat sheet without editor', (
    tester,
  ) async {
    final inventoryController = _RecordingInventoryItemsController();
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      searchResults: [_searchProduct()],
      inventoryController: inventoryController,
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();

    expect(childArgs, isNull);
    expect(inventoryController.addedItems, isEmpty);
    expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);
  });

  testWidgets('diary created product log-only save closes the page', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      childRouteResults: [_diaryEatResult()],
      inventoryController: inventoryController,
      firebaseAuth: _signedInAuth(),
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
    expect(inventoryController.addedItems, hasLength(1));
  });

  testWidgets('diary add-more eat stays on the page with overlay', (
    tester,
  ) async {
    final inventoryController = _SuccessfulInventoryItemsController();

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      searchResults: [_searchProduct()],
      inventoryController: inventoryController,
      firebaseAuth: _signedInAuth(),
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    await _tapAddMore(tester);

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

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      childRouteResults: [
        _diarySheetResult(id: 'manual-item-1', name: 'Milk'),
        _diarySheetResult(id: 'manual-item-2', name: 'Bread'),
      ],
      inventoryController: inventoryController,
      firebaseAuth: _signedInAuth(),
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
    );

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();
    await _tapAddMore(tester);

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_child_result')));
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

    expect(
      find.descendant(
        of: find.byKey(const Key('product_search_hub_cart_count_button')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(inventoryController.addedItems, hasLength(2));
  });

  testWidgets('selection mode returns the edited product to the caller', (
    tester,
  ) async {
    Object? poppedResult;
    final editedResult = _diarySheetResult(id: 'picked-item', name: 'Milk');

    await _pumpRouteHarness(
      tester,
      args: ProductSearchHubRouteArgs.selection(
        item: _item(id: 'receipt-item', name: 'Milk'),
      ),
      searchResults: [_searchProduct()],
      childRouteResults: [editedResult],
      onPagePopped: (result) => poppedResult = result,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
    expect(poppedResult, same(editedResult));
  });

  testWidgets('inventory search result opens product editor', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      searchResults: [_searchProduct()],
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
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

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.aiSearch);
    expect(childArgs?.showEatImmediatelyOption, isFalse);
  });

  testWidgets('cancelled AI initial intent returns to the caller', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.ai,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
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

    expect(find.text('Scan barcode'), findsOneWidget);
  });

  testWidgets('cancelled barcode initial intent returns to the caller', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.barcode,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
  });

  testWidgets('diary copy search result opens editor instead of direct eat', (
    tester,
  ) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      searchResults: [_searchProduct()],
      inventoryController: _SuccessfulInventoryItemsController(),
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(
        const Key('product_search_hub_search_result_copy_4006381333931'),
      ),
    );
    await tester.pumpAndSettle();

    expect(childArgs?.item.name, 'Search Milk');
    expect(childArgs?.initialInfoMessage, isNotNull);
  });

  testWidgets('diary recent product opens recent item flow', (tester) async {
    ManualProductSearchRouteArgs? childArgs;
    final inventoryController = _SuccessfulInventoryItemsController();

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      recentItems: [
        _item(id: 'recent-yogurt', name: 'Greek yogurt', weight: '500 g'),
      ],
      inventoryController: inventoryController,
      onChildRouteArgs: (args) => childArgs = args,
    );

    await tester.tap(
      find.byKey(
        const Key('product_search_hub_recently_selected_item_recent-yogurt'),
      ),
    );
    await tester.pumpAndSettle();

    // Without nutrition the recent item opens its editor, not a copy.
    expect(childArgs?.initialRecentItem?.id, 'recent-yogurt');
    expect(childArgs?.initialInfoMessage, isNull);
    expect(inventoryController.addedItems, isEmpty);
  });

  testWidgets('copying recently selected product opens editor', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

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
      inventoryController: _SuccessfulInventoryItemsController(),
      onChildRouteArgs: (args) => childArgs = args,
    );

    await tester.tap(
      find.byKey(
        const Key('product_search_hub_recently_selected_copy_recent-yogurt'),
      ),
    );
    await tester.pumpAndSettle();

    expect(childArgs?.item.name, 'Greek yogurt');
    expect(childArgs?.item.id, isNot('recent-yogurt'));
    expect(childArgs?.initialInfoMessage, isNotNull);
  });
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

class _FakeVoiceSearchService implements VoiceSearchService {
  @override
  bool get isListening => false;

  @override
  Future<void> cancelListening() async {}

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    return VoiceSearchFailure.unavailable;
  }

  @override
  Future<void> stopListening() async {}
}
