import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/features/scanner/presentation/shared_receipt_listener.dart';
import 'package:yamt/features/scanner/provider/'
    'pending_shared_receipt_intent.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/shared_receipt_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeSharedReceiptService extends SharedReceiptService {
  @override
  Future<void> build() async {}
}

class _FakeReceiptCaptureFlowController extends ReceiptCaptureFlowController {
  _FakeReceiptCaptureFlowController({required this.result});

  final ReceiptCaptureFlowResult result;
  final List<ReceiptInputSelection> capturedSelections =
      <ReceiptInputSelection>[];

  @override
  Future<ReceiptCaptureFlowResult?> build() async {
    return null;
  }

  @override
  Future<ReceiptCaptureFlowResult> runSelection({
    required ReceiptInputSelection selection,
  }) async {
    capturedSelections.add(selection);
    state = AsyncData(result);
    return result;
  }

  @override
  Future<bool> persistReviewedItems(
    List<ReceiptReviewItemDraft> reviewedItems,
  ) async {
    return true;
  }
}

ReceiptInputSelection _selection() {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: 'shared-receipt.jpg',
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

ReceiptReviewItemDraft _reviewDraft() {
  return ReceiptReviewItemDraft(
    item: InventoryItem.create(
      id: 'food',
      name: 'Milk',
      entryDate: DateTime.parse('2026-04-05T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      unitPrice: 1.99,
    ),
  );
}

@Dependencies([
  inventoryItemRepository,
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
GoRouter _router(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.root,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return const Scaffold(body: Text('Home'));
        },
      ),
      GoRoute(
        path: AppRoutes.calorieGoalSetup,
        builder: (context, state) {
          return const Scaffold(body: Text('Calorie setup'));
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
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
}

@Dependencies([
  inventoryItemRepository,
  inventoryManualAddQuickEatConfig,
  appRouter,
  InventoryItemsController,
  manualProductRecentItemsService,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  testWidgets('shows confirmation dialog and cancels shared scan', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _router(navigatorKey);
    addTearDown(router.dispose);
    final fakeController = _FakeReceiptCaptureFlowController(
      result: const ReceiptCaptureFlowResult.analysisFailed(
        source: ReceiptInputSource.file,
        errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          navigatorKeyProvider.overrideWithValue(navigatorKey),
          sharedReceiptServiceProvider.overrideWith(
            _FakeSharedReceiptService.new,
          ),
          receiptCaptureFlowControllerProvider.overrideWith(
            () => fakeController,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return SharedReceiptListener(
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SharedReceiptListener)),
    );
    container.read(pendingSharedReceiptIntentProvider.notifier).replace(
      <ReceiptInputSelection>[_selection()],
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan shared receipt?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeController.capturedSelections, isEmpty);
    expect(container.read(pendingSharedReceiptIntentProvider), isNull);
  });

  testWidgets('confirms shared scan and opens review page', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _router(navigatorKey);
    addTearDown(router.dispose);
    final fakeController = _FakeReceiptCaptureFlowController(
      result: ReceiptCaptureFlowResult.completed(
        source: ReceiptInputSource.file,
        extraction: const ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[
            ReceiptAnalysisItem(
              name: 'Milk',
              rawPayload: <String, dynamic>{'n': 'Milk'},
            ),
          ],
        ),
        reviewDrafts: <ReceiptReviewItemDraft>[_reviewDraft()],
        receiptPreviewBytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          navigatorKeyProvider.overrideWithValue(navigatorKey),
          sharedReceiptServiceProvider.overrideWith(
            _FakeSharedReceiptService.new,
          ),
          receiptCaptureFlowControllerProvider.overrideWith(
            () => fakeController,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return SharedReceiptListener(
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SharedReceiptListener)),
    );
    final selection = _selection();
    container.read(pendingSharedReceiptIntentProvider.notifier).replace(
      <ReceiptInputSelection>[selection],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(fakeController.capturedSelections, <ReceiptInputSelection>[
      selection,
    ]);
    expect(find.text('Review receipt'), findsOneWidget);
    expect(container.read(pendingSharedReceiptIntentProvider), isNull);
  });

  testWidgets('does not process shared scan on calorie onboarding route', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = _router(navigatorKey);
    addTearDown(router.dispose);
    final fakeController = _FakeReceiptCaptureFlowController(
      result: const ReceiptCaptureFlowResult.analysisFailed(
        source: ReceiptInputSource.file,
        errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          navigatorKeyProvider.overrideWithValue(navigatorKey),
          sharedReceiptServiceProvider.overrideWith(
            _FakeSharedReceiptService.new,
          ),
          receiptCaptureFlowControllerProvider.overrideWith(
            () => fakeController,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return SharedReceiptListener(
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.calorieGoalSetup);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SharedReceiptListener)),
    );
    container.read(pendingSharedReceiptIntentProvider.notifier).replace(
      <ReceiptInputSelection>[_selection()],
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan shared receipt?'), findsNothing);
    expect(fakeController.capturedSelections, isEmpty);
    expect(container.read(pendingSharedReceiptIntentProvider), isNotNull);
  });
}
