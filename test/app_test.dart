import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  testWidgets('YAMT builds router app from provider', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('root')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const YAMT(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
  });
}
