import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/home/widgets/'
    'inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_capture_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_input_capabilities.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _ActionSheetFlowTestAction {
  manualSearch,
  aiSuggestion,
  barcodeScan,
  actionSheet,
}

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
class _ActionSheetFlowHost extends ConsumerWidget {
  const _ActionSheetFlowHost({required this.action});

  final _ActionSheetFlowTestAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ElevatedButton(
      key: const Key('run_inventory_action_sheet_flow'),
      onPressed: () async {
        switch (action) {
          case _ActionSheetFlowTestAction.manualSearch:
            await InventoryActionSheetFlow.openManualSearch(
              context: context,
              l10n: l10n,
            );
          case _ActionSheetFlowTestAction.aiSuggestion:
            await InventoryActionSheetFlow.openAiSuggestion(
              context: context,
              l10n: l10n,
            );
          case _ActionSheetFlowTestAction.barcodeScan:
            await InventoryActionSheetFlow.openBarcodeScanner(
              context: context,
              l10n: l10n,
            );
          case _ActionSheetFlowTestAction.actionSheet:
            await InventoryActionSheetFlow.openActionSheet(
              context: context,
              ref: ref,
              l10n: l10n,
            );
        }
      },
      child: const Text('run'),
    );
  }
}

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
Widget _buildHarness({
  required _ActionSheetFlowTestAction action,
  bool isCameraSupported = true,
  ValueChanged<Object?>? onHubRouteExtra,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return Scaffold(
            body: Center(child: _ActionSheetFlowHost(action: action)),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) {
          onHubRouteExtra?.call(state.extra);
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('finish_product_search_hub_route'),
                onPressed: () => context.pop(),
                child: const Text('finish hub'),
              ),
            ),
          );
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
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

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  receiptCameraSupported,
])
void main() {
  group('InventoryActionSheetFlow', () {
    testWidgets('manual search opens hub search intent', (
      tester,
    ) async {
      Object? routeExtra;

      await tester.pumpWidget(
        _buildHarness(
          action: _ActionSheetFlowTestAction.manualSearch,
          onHubRouteExtra: (extra) => routeExtra = extra,
        ),
      );

      await tester.tap(
        find.byKey(const Key('run_inventory_action_sheet_flow')),
      );
      await tester.pumpAndSettle();

      final args = routeExtra! as ProductSearchHubRouteArgs;
      expect(args.mode, ProductSearchHubMode.inventory);
      expect(args.initialIntent, ProductSearchHubInitialIntent.search);
    });

    testWidgets('AI suggestion and barcode scan open hub intents', (
      tester,
    ) async {
      for (final entry in {
        _ActionSheetFlowTestAction.aiSuggestion:
            ProductSearchHubInitialIntent.ai,
        _ActionSheetFlowTestAction.barcodeScan:
            ProductSearchHubInitialIntent.barcode,
      }.entries) {
        Object? routeExtra;

        await tester.pumpWidget(
          _buildHarness(
            action: entry.key,
            onHubRouteExtra: (extra) => routeExtra = extra,
          ),
        );

        await tester.tap(
          find.byKey(const Key('run_inventory_action_sheet_flow')),
        );
        await tester.pumpAndSettle();

        final args = routeExtra! as ProductSearchHubRouteArgs;
        expect(args.mode, ProductSearchHubMode.inventory);
        expect(args.initialIntent, entry.value);
      }
    });

    testWidgets('action sheet disables camera and opens launcher flow', (
      tester,
    ) async {
      Object? routeExtra;

      await tester.pumpWidget(
        _buildHarness(
          action: _ActionSheetFlowTestAction.actionSheet,
          isCameraSupported: false,
          onHubRouteExtra: (extra) => routeExtra = extra,
        ),
      );

      await tester.tap(
        find.byKey(const Key('run_inventory_action_sheet_flow')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add food manually'), findsOneWidget);
      expect(find.text('Scan receipt (camera)'), findsOneWidget);
      expect(find.text('Upload receipt (image/PDF)'), findsOneWidget);
      expect(
        find.text('Camera is not supported on this platform.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Add food manually'));
      await tester.pumpAndSettle();

      final args = routeExtra! as ProductSearchHubRouteArgs;
      expect(args.mode, ProductSearchHubMode.inventory);
      expect(args.initialIntent, ProductSearchHubInitialIntent.launcher);
    });
  });
}
