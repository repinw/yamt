import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/router/app_route_observer.dart';
import 'package:yamt/features/home/widgets/inventory_action_fab.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/scanner/fakes/fake_receipt_product_resolver.dart';
import '../../test/features/scanner/fakes/fake_receipt_storage_gateway.dart';
import '../../test/features/scanner/fakes/fake_receipt_structured_parser.dart';
import '../../test/features/scanner/fakes/fake_receipt_text_extractor.dart';

Widget _buildHarness({required FakeReceiptStructuredParser fakeParser}) {
  final routeObserver = RouteObserver<ModalRoute<void>>();
  final router = GoRouter(
    observers: [routeObserver],
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) =>
            const Scaffold(floatingActionButton: InventoryActionFab()),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryReceiptReview,
        builder: (context, state) {
          final args = state.extra! as ScannedReceipt;
          return ReceiptReviewPage(initialReceipt: args);
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  final fakeExtractor = FakeReceiptTextExtractor();
  final fakeResolver = FakeReceiptProductResolver();
  final fakeGateway = FakeReceiptStorageGateway();

  final container = ProviderContainer(
    overrides: [
      appRouteObserverProvider.overrideWithValue(routeObserver),
      receiptCameraSupportedProvider.overrideWithValue(true),
      receiptStructuredParserProvider.overrideWithValue(fakeParser),
      receiptTextExtractorProvider.overrideWithValue(fakeExtractor),
      receiptProductResolverProvider.overrideWithValue(fakeResolver),
      receiptStorageGatewayProvider.overrideWithValue(fakeGateway),
      receiptScanFlowCoordinatorProvider.overrideWith(
        (ref) => ReceiptScanFlowCoordinator(
          parser: fakeParser,
          extractor: fakeExtractor,
          resolver: fakeResolver,
          cameraPicker: () async => '/tmp/camera_photo.jpg',
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('camera receipt flow from expanded FAB opens review page', (
    tester,
  ) async {
    final fakeParser = FakeReceiptStructuredParser()
      ..nextReceipt = const ScannedReceipt(
        id: 'camera-receipt-1',
        storeName: 'Store',
        items: [
          ReceiptLineItem(id: 'item-milk', rawName: 'Milk', totalPrice: 1.29),
        ],
      );

    await tester.pumpWidget(_buildHarness(fakeParser: fakeParser));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(const Key('inventory_action_fab_button')));
    await _pumpVisibleStep(tester);

    final cameraAction = find.byKey(const Key('inventory_action_camera_fab'));
    expect(cameraAction, findsOneWidget);

    await tester.tap(cameraAction);
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(find.byType(ReceiptReviewPage), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Beleg prüfen'), findsOneWidget);
  });
}
