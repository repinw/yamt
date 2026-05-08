import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_fab.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
Widget _buildHarness({
  bool embedded = true,
  bool isCameraSupported = true,
  ValueChanged<Object?>? onManualAddRouteExtra,
}) {
  final routeObserver = RouteObserver<ModalRoute<void>>();
  final router = GoRouter(
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return Scaffold(
            body: Center(
              child: embedded ? InventoryActionFab.embedded() : null,
            ),
            floatingActionButton: embedded ? null : const InventoryActionFab(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeShopping,
        builder: (context, state) {
          return const Scaffold(body: Text('Next route'));
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) {
          onManualAddRouteExtra?.call(state.extra);
          return const SizedBox();
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      appRouteObserverProvider.overrideWithValue(routeObserver),
      receiptCaptureFlowControllerProvider.overrideWith(
        _RecordingReceiptCaptureFlowController.new,
      ),
      receiptBatchFlowControllerProvider.overrideWith(
        _RecordingReceiptBatchFlowController.new,
      ),
      receiptCameraSupportedProvider.overrideWithValue(isCameraSupported),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Future<void> _openEmbeddedFabSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
  await tester.pumpAndSettle();
}

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
void main() {
  group('InventoryActionFab', () {
    testWidgets('expands and closes from the floating button', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(embedded: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Manual search'), findsOneWidget);
      expect(find.text('Barcode'), findsOneWidget);
      expect(find.text('AI suggestion'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('inventory_action_fab_close_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual search'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('outside tap closes the expanded floating menu', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(embedded: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
      await tester.pumpAndSettle();

      expect(find.text('Manual search'), findsOneWidget);

      await tester.tapAt(const Offset(24, 24));
      await tester.pumpAndSettle();

      expect(find.text('Manual search'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('route push closes expanded floating menu overlay', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(embedded: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
      await tester.pumpAndSettle();

      expect(find.text('Manual search'), findsOneWidget);

      final context = tester.element(find.byType(InventoryActionFab));
      unawaited(context.push(AppRoutes.homeShopping));
      await tester.pumpAndSettle();

      expect(find.text('Next route'), findsOneWidget);
      expect(find.text('Manual search'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('action closes expanded menu before opening route', (
      tester,
    ) async {
      Object? manualAddRouteExtra;

      await tester.pumpWidget(
        _buildHarness(
          embedded: false,
          onManualAddRouteExtra: (extra) => manualAddRouteExtra = extra,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inventory_action_ai_suggestion_fab')),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI suggestion'), findsNothing);
      expect(
        manualAddRouteExtra,
        InventoryManualAddInitialAction.aiSuggestion,
      );
    });
  });

  group('InventoryActionFab.embedded', () {
    testWidgets('opens sheet with all actions', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      await _openEmbeddedFabSheet(tester);

      expect(
        find.byKey(const Key('inventory_action_manual_search_fab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_action_ai_suggestion_fab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_action_barcode_fab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_action_upload_image_pdf_fab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory_action_camera_fab')),
        findsOneWidget,
      );
      expect(find.text('Manual search'), findsOneWidget);
      expect(find.text('Barcode'), findsOneWidget);
      expect(find.text('AI suggestion'), findsOneWidget);
      expect(find.text('Upload image/PDF'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('manual search closes sheet and opens manual route', (
      tester,
    ) async {
      Object? manualAddRouteExtra;

      await tester.pumpWidget(
        _buildHarness(
          onManualAddRouteExtra: (extra) => manualAddRouteExtra = extra,
        ),
      );
      await tester.pumpAndSettle();

      await _openEmbeddedFabSheet(tester);
      await tester.tap(
        find.byKey(const Key('inventory_action_manual_search_fab')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory_action_manual_search_fab')),
        findsNothing,
      );
      expect(
        manualAddRouteExtra,
        InventoryManualAddInitialAction.manualSearch,
      );
    });

    testWidgets('barcode closes sheet and opens barcode route', (
      tester,
    ) async {
      Object? manualAddRouteExtra;

      await tester.pumpWidget(
        _buildHarness(
          onManualAddRouteExtra: (extra) => manualAddRouteExtra = extra,
        ),
      );
      await tester.pumpAndSettle();

      await _openEmbeddedFabSheet(tester);
      await tester.tap(find.byKey(const Key('inventory_action_barcode_fab')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory_action_barcode_fab')),
        findsNothing,
      );
      expect(
        manualAddRouteExtra,
        InventoryManualAddInitialAction.barcodeScan,
      );
    });

    testWidgets('camera disabled shows support message and disables tile', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(isCameraSupported: false));
      await tester.pumpAndSettle();

      await _openEmbeddedFabSheet(tester);

      expect(
        find.text('Camera is not supported on this platform.'),
        findsOneWidget,
      );
      final cameraTile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(const Key('inventory_action_camera_fab')),
          matching: find.byType(ListTile),
        ),
      );
      expect(cameraTile.onTap, isNull);
      expect(cameraTile.enabled, isFalse);
    });

    testWidgets('double tap opens only one sheet', (tester) async {
      await tester.pumpWidget(_buildHarness());
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('inventory_action_fab_button'));
      await tester.tap(fab);
      await tester.tap(fab, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory_action_manual_search_fab')),
        findsOneWidget,
      );
    });
  });
}

class _RecordingReceiptCaptureFlowController
    extends ReceiptCaptureFlowController {
  @override
  FutureOr<ReceiptCaptureFlowResult?> build() {
    return null;
  }

  @override
  Future<ReceiptCaptureFlowResult> run({
    required ReceiptInputSource source,
  }) async {
    return ReceiptCaptureFlowResult.inputCanceled(source: source);
  }
}

class _RecordingReceiptBatchFlowController extends ReceiptBatchFlowController {
  @override
  ReceiptBatchFlowState build() {
    return const ReceiptBatchFlowState();
  }

  @override
  Future<void> runFileBatch() async {
    state = const ReceiptBatchFlowState(
      status: ReceiptBatchFlowStatus.inputCanceled,
    );
  }
}
