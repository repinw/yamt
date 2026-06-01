import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
  receiptCameraSupported,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
Widget _buildHarness({
  bool embedded = true,
  ReceiptBatchFlowController Function()? batchControllerBuilder,
}) {
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

  return ProviderScope(
    overrides: [
      receiptCaptureFlowControllerProvider.overrideWith(
        _IdleReceiptCaptureFlowController.new,
      ),
      receiptBatchFlowControllerProvider.overrideWith(
        batchControllerBuilder ?? _IdleReceiptBatchFlowController.new,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(),
      ),
      receiptCameraSupportedProvider.overrideWithValue(true),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> _tapFabAndSettle(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
  await tester.pumpAndSettle();
}

@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
  receiptCameraSupported,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  group('InventoryActionFab', () {
    testWidgets('floating button opens action menu with hub action', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(embedded: false));
      await tester.pumpAndSettle();

      await _tapFabAndSettle(tester);

      expect(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_action_manual_search_fab')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductSearchHubPage), findsOneWidget);
      expect(find.text('Add to inventory'), findsOneWidget);
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
      await tester.pumpWidget(_buildHarness());
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

    testWidgets('busy receipt batch disables action menu', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          batchControllerBuilder: _RunningReceiptBatchFlowController.new,
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
      await tester.pump();

      expect(find.byType(ProductSearchHubPage), findsNothing);
      expect(
        find.byKey(const Key('inventory_action_product_search_hub_fab')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('inventory_action_fab_button')),
        findsOneWidget,
      );
    });
  });
}

class _IdleReceiptCaptureFlowController extends ReceiptCaptureFlowController {
  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }
}

class _IdleReceiptBatchFlowController extends ReceiptBatchFlowController {
  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }
}

class _RunningReceiptBatchFlowController extends ReceiptBatchFlowController {
  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState(
      status: ReceiptBatchFlowStatus.running,
    );
  }
}

class _FakeInventoryItemRepository
    implements InventoryItemRepository, InventoryItemRecentManualReader {
  const _FakeInventoryItemRepository();

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
