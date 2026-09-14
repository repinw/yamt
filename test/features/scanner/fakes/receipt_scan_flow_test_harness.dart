import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_review_controller.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';

import 'fake_receipt_product_resolver.dart';
import 'fake_receipt_storage_gateway.dart';
import 'fake_receipt_structured_parser.dart';
import 'fake_receipt_text_extractor.dart';

@Dependencies([
  ReceiptReviewController,
  receiptManualProductPicker
])
class ReceiptScanFlowTestHarness {
  final FakeReceiptStructuredParser fakeParser =
      FakeReceiptStructuredParser();
  final FakeReceiptTextExtractor fakeExtractor =
      FakeReceiptTextExtractor();
  final FakeReceiptProductResolver fakeResolver =
      FakeReceiptProductResolver();
  final FakeReceiptStorageGateway fakeGateway =
      FakeReceiptStorageGateway();

  ReceiptScanFlowCoordinator createCoordinator({
    ReceiptCameraPicker? cameraPicker,
    ReceiptFilesPicker? filesPicker,
    ReceiptReviewLauncher? reviewLauncher,
  }) {
    return ReceiptScanFlowCoordinator(
      parser: fakeParser,
      extractor: fakeExtractor,
      resolver: fakeResolver,
      cameraPicker: cameraPicker,
      filesPicker: filesPicker,
      reviewLauncher: reviewLauncher,
    );
  }

  Widget build({
    required Widget Function(BuildContext context, WidgetRef ref) builder,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.root,
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => Scaffold(
            body: Consumer(builder: (context, ref, _) => builder(context, ref)),
          ),
        ),
        GoRoute(
          path: AppRoutes.homeInventoryReceiptReview,
          builder: (context, state) {
            final receipt = state.extra! as ScannedReceipt;
            return ReceiptReviewPage(initialReceipt: receipt);
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        receiptStructuredParserProvider.overrideWithValue(fakeParser),
        receiptTextExtractorProvider.overrideWithValue(fakeExtractor),
        receiptProductResolverProvider.overrideWithValue(fakeResolver),
        receiptStorageGatewayProvider.overrideWithValue(fakeGateway),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }
}
