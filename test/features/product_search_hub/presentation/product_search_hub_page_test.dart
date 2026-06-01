import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
Widget _buildHarness({
  List<InventoryItem> recentItems = const <InventoryItem>[],
  Widget child = const ProductSearchHubPage(),
}) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(recentItems),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
Widget _buildRouteHarness({
  required ProductSearchHubRouteArgs args,
  ValueChanged<ProductSearchHubRouteArgs>? onSearchRouteArgs,
  ValueChanged<ManualProductSearchRouteArgs>? onChildRouteArgs,
}) {
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
          return const Scaffold(body: Text('focused search route'));
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

  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(<InventoryItem>[]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
void main() {
  testWidgets('renders product search hub shell', (tester) async {
    await tester.pumpWidget(_buildHarness());
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
      find.byKey(
        const Key('product_search_hub_recently_selected_empty_state'),
      ),
      findsOneWidget,
    );
    expect(find.text('Recently selected'), findsOneWidget);
  });

  testWidgets('diary mode renders diary title and source actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: const ProductSearchHubPage(
          args: ProductSearchHubRouteArgs.diary(),
        ),
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
    await tester.pumpWidget(
      _buildHarness(
        child: ProductSearchHubPage(
          args: ProductSearchHubRouteArgs.selection(
            item: _item(id: 'item-1', name: 'Milk'),
          ),
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
    await tester.pumpWidget(
      _buildHarness(
        recentItems: [
          _item(
            id: 'recent-yogurt',
            name: 'Greek yogurt',
            brand: 'Dairy Co',
            weight: '500 g',
          ),
        ],
      ),
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
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    expect(find.text('Recently selected'), findsOneWidget);
  });

  testWidgets('search initial intent opens focused search route', (
    tester,
  ) async {
    ProductSearchHubRouteArgs? searchArgs;

    await tester.pumpWidget(
      _buildRouteHarness(
        args: const ProductSearchHubRouteArgs.inventory(
          initialIntent: ProductSearchHubInitialIntent.search,
        ),
        onSearchRouteArgs: (args) => searchArgs = args,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('focused search route'), findsOneWidget);
    expect(searchArgs?.mode, ProductSearchHubMode.inventory);
    expect(searchArgs?.initialIntent, ProductSearchHubInitialIntent.search);
  });

  testWidgets('AI initial intent opens AI child route', (tester) async {
    ManualProductSearchRouteArgs? childArgs;

    await tester.pumpWidget(
      _buildRouteHarness(
        args: const ProductSearchHubRouteArgs.inventory(
          initialIntent: ProductSearchHubInitialIntent.ai,
        ),
        onChildRouteArgs: (args) => childArgs = args,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('product search child route'), findsOneWidget);
    expect(childArgs?.flow, ManualProductSearchChildFlow.aiSearch);
    expect(childArgs?.showEatImmediatelyOption, isFalse);
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

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const _FakeInventoryItemRepository(this._items);

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
