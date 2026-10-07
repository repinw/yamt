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
import 'package:yamt/features/inventory/presentation/inventory_stock_add_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_meal_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_missing_values_hint.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_meal_food_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _searchFieldKey = Key('product_search_hub_search_field');

class _FakeFoodEstimateRepository implements FoodEstimateRepository {
  @override
  Future<List<FoodEstimatePhoto>> loadPhotos({
    required bool fromCamera,
  }) async => const [];

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) async => const FoodEstimate(
    name: 'Apfel',
    portionGrams: 160,
    kcalLean: 80,
    kcalRich: 90,
    per100: GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: 52,
    ),
    ingredients: [],
  );

  @override
  Future<String> saveFoodPhoto(FoodEstimatePhoto photo) async =>
      'https://example.com/food.jpg';
}

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
  FoodEstimateRepository? foodEstimateRepository,
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
        if (foodEstimateRepository != null)
          foodEstimateRepositoryProvider.overrideWithValue(
            foodEstimateRepository,
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
            ProductSearchHubMode.selection || ProductSearchHubMode.mealFood =>
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

const _mealFoodArgs = ProductSearchHubRouteArgs(
  mode: ProductSearchHubMode.mealFood,
  initialIntent: ProductSearchHubInitialIntent.search,
);

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
    expect(find.byKey(productSearchHubEatPageEditKey), findsOneWidget);
    // Eating needs no package, so only the nutrition counts as missing.
    expect(find.text('Missing: 3 nutrition values – add'), findsOneWidget);
  });

  testWidgets('diary eat page edits the food and comes back', (tester) async {
    ManualProductSearchRouteArgs? childArgs;
    final edited = InventoryReceiptManualProductResult(
      item: _item(id: 'edited-milk', name: 'Oat milk', weight: '1 l'),
      action: InventoryReceiptManualProductAction.eatNow,
      requiresGlobalPersistence: false,
    );

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      searchResults: [_searchProduct()],
      childRouteResults: [edited],
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(productSearchHubEatPageEditKey));
    await tester.tap(find.byKey(productSearchHubEatPageEditKey));
    await tester.pumpAndSettle();

    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);

    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);
    expect(find.text('Oat milk'), findsWidgets);
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

  testWidgets('back on the eat page reopens the editor of a created product', (
    tester,
  ) async {
    final childArgs = <ManualProductSearchRouteArgs>[];

    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      childRouteResults: [_diarySheetResult(id: 'created-item', name: 'Skyr')],
      inventoryController: _SuccessfulInventoryItemsController(),
      firebaseAuth: _signedInAuth(),
      commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
      onChildRouteArgs: childArgs.add,
    );

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs.last.flow, ManualProductSearchChildFlow.editor);
    expect(childArgs.last.item.id, 'created-item');
    expect(childArgs.last.item.name, 'Skyr');
  });

  for (final (mode, args) in [
    ('diary', _diaryArgs()),
    ('meal food', _mealFoodArgs),
  ]) {
    testWidgets('$mode: back on the eat page keeps an edit of a created '
        'product', (tester) async {
      final childArgs = <ManualProductSearchRouteArgs>[];

      await _pumpRouteHarness(
        tester,
        args: args,
        childRouteResults: [
          _diarySheetResult(id: 'created-item', name: 'Skyr'),
          _diarySheetResult(id: 'created-item', name: 'Skyr natur'),
        ],
        inventoryController: _SuccessfulInventoryItemsController(),
        firebaseAuth: _signedInAuth(),
        commitStore: const _SuccessfulInventoryCalorieEntryCommitStore(),
        onChildRouteArgs: childArgs.add,
      );

      await tester.tap(
        find.byKey(const Key('product_search_hub_search_create_own_action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('return_child_result')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(productSearchHubEatPageEditKey));
      await tester.tap(find.byKey(productSearchHubEatPageEditKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('return_child_result')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('product search child route'), findsOneWidget);
      expect(childArgs.last.item.name, 'Skyr natur');
    });
  }

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

  testWidgets('inventory search result opens the Vorrat page first', (
    tester,
  ) async {
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

    expect(find.byType(InventoryStockAddPage), findsOneWidget);
    expect(find.text('product search child route'), findsNothing);
    // Without offersEatInstead, as for a cooking ingredient, it only stores.
    expect(find.byKey(EatPageScaffold.diaryButtonKey), findsNothing);

    await tester.ensureVisible(find.byKey(InventoryStockAddPage.increaseKey));
    await tester.tap(find.byKey(InventoryStockAddPage.increaseKey));
    await tester.pump();
    expect(find.text('Add to stock (2 packages)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('eat_item_action_edit')));
    await tester.tap(find.byKey(const Key('eat_item_action_edit')));
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);
  });

  testWidgets('the Vorrat page eats the product instead from its diary icon', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
        offersEatInstead: true,
      ),
      searchResults: [_searchProduct()],
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(EatPageScaffold.planButtonKey), findsOneWidget);

    await tester.tap(find.byKey(EatPageScaffold.diaryButtonKey));
    await tester.pumpAndSettle();

    // The eat page opens; it offers no way back into the Vorrat.
    expect(find.byType(InventoryStockAddPage), findsNothing);
    expect(find.byType(InventoryItemEatSheetBody), findsOneWidget);
    expect(find.byKey(EatPageScaffold.storeButtonKey), findsNothing);
    // It ends like one eaten food, so it adds no more.
    expect(
      find.byKey(const Key('inventory_item_amount_dialog_add_more_button')),
      findsNothing,
    );
  });

  testWidgets('the Vorrat page plans the product from its plan icon', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
        offersEatInstead: true,
      ),
      searchResults: [_searchProduct()],
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EatPageScaffold.planButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // The eat page plans the food, also for today.
    expect(find.byType(InventoryItemEatSheetBody), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const Key('inventory_item_amount_dialog_confirm_button'),
        ),
        matching: find.text('Plan'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the Vorrat page names a missing package size and opens the '
      'editor from it', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      searchResults: [_searchProduct(packageWeight: null)],
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Missing: Package size, 3 nutrition values – add'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(EatMissingValuesHint.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);
  });

  testWidgets('meal food search result opens the eat page, not the editor', (
    tester,
  ) async {
    Object? poppedResult;
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: _mealFoodArgs,
      searchResults: [_searchProduct()],
      onChildRouteArgs: (args) => childArgs = args,
      onPagePopped: (result) => poppedResult = result,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();

    expect(childArgs, isNull);
    expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);
    expect(find.byKey(productSearchHubEatPageEditKey), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('eat_page_amount_field')),
      '150',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
    expect(poppedResult, isA<InventoryMealFoodPick>());
    final pick = poppedResult! as InventoryMealFoodPick;
    expect(pick.result.item.name, 'Search Milk');
    expect(pick.request.inventoryAmount, 150);
  });

  testWidgets('a recent item picked for a meal gets a new id', (tester) async {
    Object? poppedResult;
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs(
        mode: ProductSearchHubMode.mealFood,
      ),
      recentItems: [
        _itemWithNutrition(
          id: 'stock-quark',
          name: 'Quark',
        ).copyWith(origin: InventoryItemOrigin.manualAdd),
      ],
      onPagePopped: (result) => poppedResult = result,
    );

    await tester.tap(
      find.byKey(
        const Key('product_search_hub_recently_selected_item_stock-quark'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory_item_amount_dialog_confirm_button')),
    );
    await tester.pumpAndSettle();

    final pick = poppedResult! as InventoryMealFoodPick;
    expect(pick.result.item.name, 'Quark');
    expect(pick.result.item.id, isNot('stock-quark'));
  });

  testWidgets('meal food eat page edits the food and comes back', (
    tester,
  ) async {
    ManualProductSearchRouteArgs? childArgs;
    final edited = InventoryReceiptManualProductResult(
      item: _item(id: 'edited-milk', name: 'Oat milk', weight: '1 l'),
      action: InventoryReceiptManualProductAction.addToInventory,
      requiresGlobalPersistence: false,
    );

    await _pumpRouteHarness(
      tester,
      args: _mealFoodArgs,
      searchResults: [_searchProduct()],
      childRouteResults: [edited],
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Milk');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(productSearchHubEatPageEditKey));
    await tester.tap(find.byKey(productSearchHubEatPageEditKey));
    await tester.pumpAndSettle();

    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);

    await tester.tap(find.byKey(const Key('return_child_result')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('eat_page_amount_field')), findsOneWidget);
    expect(find.text('Oat milk'), findsWidgets);
  });

  testWidgets('AI initial intent shows the AI page without the search', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.ai,
      ),
    );

    expect(find.byType(ManualProductAiSearchPage), findsOneWidget);
    expect(find.byKey(_searchFieldKey), findsNothing);
    expect(find.text('product search child route'), findsNothing);
  });

  testWidgets('the food from the AI intent goes back to the caller', (
    tester,
  ) async {
    Object? poppedResult;
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs(
        mode: ProductSearchHubMode.selection,
        initialIntent: ProductSearchHubInitialIntent.ai,
      ),
      foodEstimateRepository: _FakeFoodEstimateRepository(),
      onPagePopped: (result) => poppedResult = result,
    );

    await tester.enterText(
      find.byKey(ManualProductAiSearchPage.descriptionKey),
      'Apfel',
    );
    await tester.pump();
    await tester.tap(find.byKey(ManualProductAiSearchPage.analyzeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to stock'));
    await tester.pumpAndSettle();

    expect(find.text('caller'), findsOneWidget);
    expect(poppedResult, isA<InventoryReceiptManualProductResult>());
    expect(
      (poppedResult! as InventoryReceiptManualProductResult).item.name,
      'Apfel',
    );
  });

  testWidgets('"Add to stock" on the AI page stores without a second page', (
    tester,
  ) async {
    final controller = _RecordingInventoryItemsController();
    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.ai,
        offersEatInstead: true,
      ),
      inventoryController: controller,
      foodEstimateRepository: _FakeFoodEstimateRepository(),
    );

    await tester.enterText(
      find.byKey(ManualProductAiSearchPage.descriptionKey),
      'Apfel',
    );
    await tester.pump();
    await tester.tap(find.byKey(ManualProductAiSearchPage.analyzeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to stock'));
    await tester.pumpAndSettle();

    // The AI page was the confirmation; the Vorrat page does not follow.
    expect(find.byType(InventoryStockAddPage), findsNothing);
    expect(controller.addedItems.map((item) => item.name), ['Apfel']);
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

  testWidgets('create action opens an empty editor form', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      searchResults: [_searchProduct()],
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Custom Skyr');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();

    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);
    expect(childArgs?.item.name, isEmpty);
    expect(childArgs?.item.barcode, isEmpty);
    expect(childArgs?.selectedProduct, isNull);
  });

  testWidgets('empty results create button opens an empty editor form', (
    tester,
  ) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, 'Custom Skyr');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_product_button')),
    );
    await tester.pumpAndSettle();

    expect(childArgs?.flow, ManualProductSearchChildFlow.editor);
    expect(childArgs?.item.name, isEmpty);
  });

  testWidgets('create action keeps a searched barcode', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await _pumpRouteHarness(
      tester,
      args: const ProductSearchHubRouteArgs.inventory(
        initialIntent: ProductSearchHubInitialIntent.search,
      ),
      onChildRouteArgs: (args) => childArgs = args,
    );

    await _searchFor(tester, '4006381333931');
    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
    );
    await tester.pumpAndSettle();

    expect(childArgs?.item.name, isEmpty);
    expect(childArgs?.item.barcode, '4006381333931');
  });

  testWidgets('search results and recent products have no copy button', (
    tester,
  ) async {
    await _pumpRouteHarness(
      tester,
      args: _diaryArgs(),
      recentItems: [_item(id: 'recent-yogurt', name: 'Greek yogurt')],
      searchResults: [_searchProduct()],
    );

    expect(
      find.byKey(
        const Key('product_search_hub_recently_selected_item_recent-yogurt'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.content_copy_rounded), findsNothing);

    await _searchFor(tester, 'Milk');

    expect(
      find.byKey(const Key('product_search_hub_search_result_4006381333931')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.content_copy_rounded), findsNothing);
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
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    return [
      InventoryCalorieEntryCommitResult(
        itemId: pendingConsumptions.single.itemId,
        quantity: 1,
        currentAmount: 400,
      ),
    ];
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) => throw UnimplementedError();
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
  String? packageWeight = '100 g',
}) {
  return OffProductSearchResult(
    code: code,
    name: name,
    brand: 'Dairy Co',
    score: 1,
    packageWeight: packageWeight,
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
