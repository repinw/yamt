import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
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
Widget _buildHarness() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return const Scaffold(floatingActionButton: InventoryActionFab());
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => const ProductSearchHubPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      receiptCaptureFlowControllerProvider.overrideWith(
        _IdleReceiptCaptureFlowController.new,
      ),
      receiptBatchFlowControllerProvider.overrideWith(
        _IdleReceiptBatchFlowController.new,
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
  receiptCameraSupported,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('inventory FAB opens product search hub page from root', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
    await _pumpVisibleStep(tester);

    expect(find.byType(ProductSearchHubPage), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
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
