import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _ReceiptCameraIntegrationHarness {
  const _ReceiptCameraIntegrationHarness({
    required this.app,
    required this.captureController,
  });

  final Widget app;
  final _CompletedReceiptCaptureFlowController captureController;
}

@Dependencies([
  InventoryItemsController,
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
  manualProductRecentItemsService,
])
_ReceiptCameraIntegrationHarness _buildHarness() {
  final routeObserver = RouteObserver<ModalRoute<void>>();
  final captureController = _CompletedReceiptCaptureFlowController();
  final router = GoRouter(
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return const Scaffold(floatingActionButton: InventoryActionFab());
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryReceiptReview,
        builder: (context, state) {
          final args = state.extra! as InventoryReceiptReviewPageArgs;
          return InventoryReceiptReviewPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: (context, state) {
          final args = state.extra! as ManualProductSearchRouteArgs;
          return NoTransitionPage<Object?>(
            key: state.pageKey,
            child: args.builder(context),
          );
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      appRouteObserverProvider.overrideWithValue(routeObserver),
      receiptCaptureFlowControllerProvider.overrideWith(
        () => captureController,
      ),
      receiptBatchFlowControllerProvider.overrideWith(
        _IdleReceiptBatchFlowController.new,
      ),
      receiptCameraSupportedProvider.overrideWithValue(true),
    ],
  );
  addTearDown(container.dispose);

  return _ReceiptCameraIntegrationHarness(
    captureController: captureController,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

Future<void> _pumpVisibleStep(
  WidgetTester tester, {
  Duration observeFor = const Duration(milliseconds: 600),
}) async {
  await tester.pump();
  await Future<void>.delayed(observeFor);
  await tester.pump();
}

@Dependencies([
  InventoryItemsController,
  inventoryManualAddQuickEatConfig,
  inventoryItemRepository,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
  manualProductRecentItemsService,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('camera receipt flow from expanded FAB opens review page', (
    tester,
  ) async {
    final harness = _buildHarness();

    await tester.pumpWidget(harness.app);
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
    await _pumpVisibleStep(tester);

    final cameraAction = find.byKey(const Key('inventory_action_camera_fab'));
    expect(cameraAction, findsOneWidget);

    await tester.tap(cameraAction);
    await harness.captureController.scanStarted.future;
    await _pumpVisibleStep(tester);

    harness.captureController.releaseScan.complete();
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(harness.captureController.sources, <ReceiptInputSource>[
      ReceiptInputSource.camera,
    ]);
    expect(find.byType(InventoryReceiptReviewPage), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.byKey(const Key('receipt_review_save_button')), findsOneWidget);
  });
}

class _CompletedReceiptCaptureFlowController
    extends ReceiptCaptureFlowController {
  final List<ReceiptInputSource> sources = <ReceiptInputSource>[];
  final Completer<void> scanStarted = Completer<void>();
  final Completer<void> releaseScan = Completer<void>();

  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  @override
  Future<ReceiptCaptureFlowResult> run({
    required ReceiptInputSource source,
  }) async {
    sources.add(source);
    state = const AsyncLoading<ReceiptCaptureFlowResult?>();
    if (!scanStarted.isCompleted) {
      scanStarted.complete();
    }
    await releaseScan.future;

    final result = ReceiptCaptureFlowResult.completed(
      source: source,
      extraction: const ReceiptAnalysisExtraction(
        root: <String, dynamic>{},
        items: <ReceiptAnalysisItem>[],
      ),
      reviewDrafts: <ReceiptReviewItemDraft>[
        ReceiptReviewItemDraft(
          item: InventoryItem.create(
            id: 'milk',
            name: 'Milk',
            entryDate: DateTime.parse('2026-05-13T10:00:00Z'),
            storeName: 'Store',
            quantity: 1,
            unitPrice: 1.29,
            weight: '1 l',
          ),
        ),
      ],
    );
    state = AsyncData<ReceiptCaptureFlowResult?>(result);
    return result;
  }
}

class _IdleReceiptBatchFlowController extends ReceiptBatchFlowController {
  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }
}
