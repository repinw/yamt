import 'dart:async';

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
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page/manual_product_search_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
void main() {
  testWidgets('push helper returns typed result without route animation', (
    tester,
  ) async {
    String? result;

    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_manual_product_route'),
            onPressed: () {
              unawaited(
                pushManualProductSearchPage<String>(
                  context: context,
                  args: ManualProductSearchRouteArgs.manualProduct(
                    item: _item(),
                  ),
                ).then((value) => result = value),
              );
            },
            child: const Text('open'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));

    await tester.tap(find.byKey(const Key('open_manual_product_route')));
    await tester.pump();

    expect(router.state.uri.queryParameters.keys, <String>['payload']);
    expect(router.state.uri.toString().length, lessThan(160));
    expect(find.byType(InventoryReceiptManualProductPage), findsOneWidget);

    popManualProductSearchPage(
      tester.element(find.byType(InventoryReceiptManualProductPage)),
      'done',
    );
    await tester.pumpAndSettle();

    expect(result, 'done');
  });

  testWidgets('pop helper delegates to go_router when available', (
    tester,
  ) async {
    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_go_router_route'),
            onPressed: () => unawaited(
              pushManualProductSearchPage<String>(
                context: context,
                args: ManualProductSearchRouteArgs.manualProduct(
                  item: _item(),
                ),
              ),
            ),
            child: const Text('home'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));

    await tester.tap(find.byKey(const Key('open_go_router_route')));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryReceiptManualProductPage), findsOneWidget);

    popManualProductSearchPage(
      tester.element(find.byType(InventoryReceiptManualProductPage)),
      'done',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open_go_router_route')), findsOneWidget);
  });

  testWidgets('editor route uses route-local save handler', (
    tester,
  ) async {
    InventoryReceiptManualProductResult? savedResult;
    Future<void> handleSaved(
      InventoryReceiptManualProductResult result,
    ) async {
      savedResult = result;
    }

    await tester.pumpWidget(
      _wrapChild(
        buildManualProductSearchChild(
          ManualProductSearchRouteArgs.editor(
            config: InventoryReceiptManualProductConfig(item: _item()),
            showEatImmediatelyOption: false,
            initialAction: InventoryReceiptManualProductAction.addToInventory,
            closeCurrentEditorOnSave: false,
            showActionSelector: true,
            autofocusSearch: true,
            onSaved: handleSaved,
          ),
        ),
      ),
    );

    final page = tester.widget<InventoryReceiptManualProductEditorPage>(
      find.byType(InventoryReceiptManualProductEditorPage),
    );
    final result = InventoryReceiptManualProductResult(
      item: _item(),
      action: InventoryReceiptManualProductAction.addToInventory,
    );

    expect(page.closeCurrentEditorOnSave, isFalse);
    expect(page.onSaved, isNotNull);

    await page.onSaved!(result);

    expect(savedResult, same(result));
  });
}

Widget _wrapRouter(GoRouter router) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        const _EmptyInventoryItemRepository(),
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Widget _wrapChild(Widget child) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        const _EmptyInventoryItemRepository(),
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
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
GoRouter _buildManualProductRouteTestRouter({
  required WidgetBuilder homeBuilder,
}) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => homeBuilder(context)),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
  );
}

class _EmptyInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const _EmptyInventoryItemRepository();

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
  }
}
