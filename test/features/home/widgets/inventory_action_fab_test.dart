import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_page.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> _pumpHarness(WidgetTester tester, {bool embedded = true}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return Scaffold(
            body: Center(
              child: embedded ? const InventoryActionFab.embedded() : null,
            ),
            floatingActionButton: embedded ? null : const InventoryActionFab(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => const ProductSearchHubPage(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          const _FakeInventoryItemRepository(),
        ),
        receiptCameraSupportedProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

Future<void> _tapFabAndSettle(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
  await tester.pumpAndSettle();
}

void main() {
  group('InventoryActionFab', () {
    testWidgets('floating button opens action menu with hub action', (
      tester,
    ) async {
      await _pumpHarness(tester, embedded: false);
      await tester.pumpAndSettle();

      await _tapFabAndSettle(tester);

      expect(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductSearchHubPage), findsOneWidget);
      expect(
        find.byKey(
          const Key('product_search_hub_recently_selected_empty_state'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('embedded button opens action sheet with hub action', (
      tester,
    ) async {
      await _pumpHarness(tester);
      await tester.pumpAndSettle();

      await _tapFabAndSettle(tester);

      expect(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductSearchHubPage), findsOneWidget);
    });
  });
}

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const new();

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

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
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }
}
