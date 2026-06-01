import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_search_launcher.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_launcher.dart';

void main() {
  testWidgets('manual product launcher opens hub in selection mode', (
    tester,
  ) async {
    ProductSearchHubRouteArgs? capturedArgs;
    final launcher = buildProductSearchHubManualProductSearchLauncher();
    final router = _buildRouter(
      launcher: launcher,
      onHubArgs: (args) {
        capturedArgs = args;
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.tap(find.byKey(const Key('open_manual_product_search')));
    await tester.pump();

    final args = capturedArgs;
    expect(args, isNotNull);
    expect(args!.mode, ProductSearchHubMode.selection);
    expect(args.item?.id, 'item-1');
    expect(args.includeStoreInSearch, isFalse);
    expect(args.includeWeightInSearch, isTrue);
  });
}

GoRouter _buildRouter({
  required InventoryManualProductSearchLauncher launcher,
  required ValueChanged<ProductSearchHubRouteArgs> onHubArgs,
}) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return Scaffold(
            body: FilledButton(
              key: const Key('open_manual_product_search'),
              onPressed: () {
                unawaited(
                  launcher(
                    context: context,
                    request: InventoryManualProductSearchRequest(
                      item: _item(),
                      includeStoreInSearch: false,
                    ),
                  ),
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
          onHubArgs(state.extra! as ProductSearchHubRouteArgs);
          return const Placeholder();
        },
      ),
    ],
  );
}

Widget _wrapRouter(GoRouter router) {
  return MaterialApp.router(routerConfig: router);
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
