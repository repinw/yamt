import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_action_sheet_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_initial_action.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
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
  ValueChanged<Object?>? onManualAddRouteExtra,
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
        path: AppRoutes.homeInventoryManualAdd,
        builder: (context, state) {
          onManualAddRouteExtra?.call(state.extra);
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('finish_manual_add_route'),
                onPressed: () => context.pop(true),
                child: const Text('finish'),
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
    testWidgets('manual search pushes route and shows saved feedback', (
      tester,
    ) async {
      Object? routeExtra;

      await tester.pumpWidget(
        _buildHarness(
          action: _ActionSheetFlowTestAction.manualSearch,
          onManualAddRouteExtra: (extra) => routeExtra = extra,
        ),
      );

      await tester.tap(
        find.byKey(const Key('run_inventory_action_sheet_flow')),
      );
      await tester.pumpAndSettle();

      expect(routeExtra, InventoryManualAddInitialAction.manualSearch);

      await tester.tap(find.byKey(const Key('finish_manual_add_route')));
      await tester.pumpAndSettle();

      expect(find.text('Product added to inventory.'), findsOneWidget);
    });

    testWidgets('AI suggestion and barcode scan pass route extras', (
      tester,
    ) async {
      for (final entry in {
        _ActionSheetFlowTestAction.aiSuggestion:
            InventoryManualAddInitialAction.aiSuggestion,
        _ActionSheetFlowTestAction.barcodeScan:
            InventoryManualAddInitialAction.barcodeScan,
      }.entries) {
        Object? routeExtra;

        await tester.pumpWidget(
          _buildHarness(
            action: entry.key,
            onManualAddRouteExtra: (extra) => routeExtra = extra,
          ),
        );

        await tester.tap(
          find.byKey(const Key('run_inventory_action_sheet_flow')),
        );
        await tester.pumpAndSettle();

        expect(routeExtra, entry.value);

        await tester.tap(find.byKey(const Key('finish_manual_add_route')));
        await tester.pumpAndSettle();
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
          onManualAddRouteExtra: (extra) => routeExtra = extra,
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

      expect(routeExtra, InventoryManualAddInitialAction.launcher);
    });
  });
}
