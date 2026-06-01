import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_ingredient_source_flow.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_page.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

@Dependencies([InventoryItemsController])
void main() {
  testWidgets('manual source opens product hub and returns new ingredient', (
    tester,
  ) async {
    final inventoryController = _MutableInventoryItemsController();
    final container = ProviderContainer(
      overrides: [
        inventoryItemsControllerProvider.overrideWith(
          () => inventoryController,
        ),
      ],
    );
    final inventorySubscription = container.listen(
      inventoryItemsControllerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    Object? routeExtra;
    CookingFlowSummaryIngredientDraft? draft;

    final router = _buildRouter(
      container: container,
      onHubArgs: (extra) {
        routeExtra = extra;
      },
      onDraft: (value) {
        draft = value;
      },
    );
    addTearDown(inventorySubscription.close);
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byKey(const Key('open_manual_source')));
    await tester.pumpAndSettle();

    final args = routeExtra! as ProductSearchHubRouteArgs;
    expect(args.mode, ProductSearchHubMode.inventory);
    expect(args.initialIntent, ProductSearchHubInitialIntent.search);

    await tester.tap(find.byKey(const Key('finish_product_search_hub')));
    await tester.pumpAndSettle();

    expect(draft?.name, 'Butter');
    expect(draft?.inventoryItemIds, ['new-butter']);
  });
}

@Dependencies([InventoryItemsController])
GoRouter _buildRouter({
  required ProviderContainer container,
  required ValueChanged<Object?> onHubArgs,
  required ValueChanged<CookingFlowSummaryIngredientDraft?> onDraft,
}) {
  return GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return Scaffold(
            body: FilledButton(
              key: const Key('open_manual_source'),
              onPressed: () {
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
                unawaited(
                  resolveCookingFlowSummaryIngredientSource(
                    context: context,
                    container: container,
                    source: CookingFlowSummaryIngredientAddSource.manualSearch,
                    currentIngredients:
                        const <CookingFlowSummaryIngredientDraft>[],
                    saveSession: () async => true,
                  ).then(onDraft),
                );
              },
              child: const Text('open'),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) {
          onHubArgs(state.extra);
          return Scaffold(
            body: FilledButton(
              key: const Key('finish_product_search_hub'),
              onPressed: () {
                (container.read(inventoryItemsControllerProvider.notifier)
                        as _MutableInventoryItemsController)
                    .setItems([_inventoryItem()]);
                context.pop();
              },
              child: const Text('finish'),
            ),
          );
        },
      ),
    ],
  );
}

class _MutableInventoryItemsController extends InventoryItemsController {
  var _items = const <InventoryItem>[];

  @override
  Future<List<InventoryItem>> build() async => _items;

  void setItems(List<InventoryItem> items) {
    _items = items;
    state = AsyncData(items);
  }
}

InventoryItem _inventoryItem() {
  return InventoryItem.create(
    id: 'new-butter',
    name: 'Butter',
    entryDate: DateTime.utc(2026, 6),
    storeName: 'Manual',
    quantity: 1,
    weight: '250 g',
  );
}
