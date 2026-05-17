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
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_search_launcher.dart';
import 'package:yamt/features/product_search/presentation/'
    'manual_product_search_launcher.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page/manual_product_search_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
void main() {
  testWidgets('passes inventory search flags to manual product route', (
    tester,
  ) async {
    final launcher = buildProductSearchManualProductSearchLauncher();
    final router = _buildRouter(launcher);
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));

    await tester.tap(find.byKey(const Key('open_manual_product_search')));
    await tester.pump();

    final page = tester.widget<InventoryReceiptManualProductPage>(
      find.byType(InventoryReceiptManualProductPage),
    );

    expect(page.item.id, 'item-1');
    expect(page.includeStoreInSearch, isFalse);
    expect(page.includeWeightInSearch, isTrue);
  });
}

@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
GoRouter _buildRouter(InventoryManualProductSearchLauncher launcher) {
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
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
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
