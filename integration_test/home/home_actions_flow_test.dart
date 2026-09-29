import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/home/presentation/widgets/inventory_add_actions.dart';
import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/scanner/fakes/fake_receipt_ai_repository.dart';
import '../../test/features/scanner/fakes/fake_receipt_product_resolver.dart';

const _hubPageKey = ValueKey<String>('home-actions-test-hub');

GoRoute _placeholder(String path, {Key? key}) {
  return GoRoute(
    path: path,
    builder: (context, state) => Scaffold(body: SizedBox.expand(key: key)),
  );
}

Widget _buildHarness() {
  final router = GoRouter(
    initialLocation: AppRoutes.homeInventory,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeInventory)]),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeDiary)]),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeInventoryTemplates)],
          ),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeProgress)]),
        ],
      ),
      _placeholder(AppRoutes.homeProductSearchHub, key: _hubPageKey),
    ],
  );
  addTearDown(router.dispose);

  // The Vorrat actions ask the scan coordinator whether a camera exists, so
  // its AI and product lookups are fakes.
  final container = ProviderContainer(
    overrides: [
      receiptCameraSupportedProvider.overrideWithValue(true),
      receiptAiRepositoryProvider.overrideWithValue(FakeReceiptAiRepository()),
      receiptProductResolverProvider.overrideWithValue(
        FakeReceiptProductResolver(),
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the action button opens the Vorrat actions and runs one', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsOneWidget);
    expect(find.byKey(InventoryAddActionKeys.barcode), findsOneWidget);
    expect(find.byKey(InventoryAddActionKeys.receiptPhoto), findsOneWidget);

    await tester.tap(find.byKey(InventoryAddActionKeys.manualSearch));
    await tester.pumpAndSettle();

    expect(find.byKey(_hubPageKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the close button hides the action panel', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeActionPanel.closeButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsNothing);
    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
  });
}
