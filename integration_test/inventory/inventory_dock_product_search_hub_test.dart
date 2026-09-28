import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/home/presentation/widgets/inventory_dock.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'food_estimate_photo_input.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) {
          return const Scaffold(bottomNavigationBar: InventoryDock());
        },
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) => ProductSearchHubPage(
          args: resolveProductSearchHubRouteArgs(state.extra),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        redirect: redirectInvalidManualProductSearchRoute,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [receiptCameraSupportedProvider.overrideWithValue(true)],
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

  testWidgets('inventory dock opens product search hub page from root', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(InventoryDock.addKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryDock.manualSearchKey));
    await _pumpVisibleStep(tester);

    expect(find.byType(ProductSearchHubPage), findsOneWidget);
    expect(
      find.byKey(const Key('product_search_hub_search_field')),
      findsOneWidget,
    );
  });

  testWidgets('the add sheet opens the editor for an own product', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(InventoryDock.addKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryDock.createKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(find.byKey(ManualProductDetailsForm.saveKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the add sheet opens the AI estimate with the camera first', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(InventoryDock.addKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryDock.aiKey));
    await _pumpVisibleStep(tester, observeFor: const Duration(seconds: 1));

    expect(find.byKey(FoodEstimatePhotoInput.cameraKey), findsOneWidget);
    expect(find.byKey(FoodEstimatePhotoInput.galleryKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
