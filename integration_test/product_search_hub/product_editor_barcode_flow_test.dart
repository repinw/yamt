import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_photo_section.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_scanner_page/'
    'product_search_barcode_scanner_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_scanner_page/'
    'product_search_barcode_scanner_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_barcode_sources.dart';
import '../../test/helpers/fake_mobile_scanner_platform.dart';

const _barcode = '4006381333931';

Widget _buildHarness({
  required FakeOffBarcodeRepository off,
  required FakeGlobalBarcodeCandidateRepository learned,
}) {
  final config = InventoryReceiptManualProductConfig(
    item: InventoryItem.create(
      id: 'item-1',
      name: '',
      entryDate: DateTime.parse('2026-10-12T10:00:00Z'),
      storeName: 'Rewe',
      quantity: 1,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open_editor'),
              onPressed: () => unawaited(
                pushManualProductSearchPage<Object?>(
                  context: context,
                  args: ManualProductSearchRouteArgs.editor(
                    config: config,
                    showEatImmediatelyOption: false,
                    initialAction:
                        InventoryReceiptManualProductAction.addToInventory,
                    showActionSelector: false,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
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

  // The real lookup runs; only the two sources behind it are fakes.
  final container = ProviderContainer(
    overrides: [
      productSearchGatewayProvider.overrideWithValue(
        CompositeProductSearchAdapter(
          offRepository: off,
          barcodeCandidateRepository: learned,
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

/// Pumps until [isDone], at most [timeout]. The scanner's laser keeps
/// animating on a device, so `pumpAndSettle` would never return.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() isDone, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  const step = Duration(milliseconds: 100);
  for (var waited = Duration.zero; waited < timeout; waited += step) {
    if (isDone()) {
      return;
    }
    await tester.pump(step);
  }
  expect(isDone(), isTrue, reason: 'Still waiting after $timeout.');
}

bool _isShown(Finder finder) => finder.evaluate().isNotEmpty;

String _barcodeFieldText(WidgetTester tester) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(ManualProductFormField.barcode.key),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

/// Opens the editor, scans [_barcode], and waits until the scanner closed.
Future<void> _scanBarcodeInEditor(
  WidgetTester tester,
  FakeMobileScannerPlatform camera,
) async {
  await tester.tap(find.byKey(const Key('open_editor')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(ManualProductPhotoSection.scanBarcodeKey));
  await _pumpUntil(tester, () => camera.isRunning);
  camera.scan(_barcode);
  await _pumpUntil(
    tester,
    () => !_isShown(find.byType(InventoryBarcodeScannerPage)),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('offline, a scanned barcode says the lookup needs a connection '
      'and stays in the product', (tester) async {
    final camera = FakeMobileScannerPlatform.install();
    await tester.pumpWidget(
      _buildHarness(
        off: FakeOffBarcodeRepository(error: offlineHttpError),
        learned: FakeGlobalBarcodeCandidateRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await _scanBarcodeInEditor(tester, camera);

    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsOneWidget,
    );
    expect(
      find.byType(InventoryReceiptManualProductEditorPage),
      findsOneWidget,
    );
    expect(_barcodeFieldText(tester), _barcode);
  });

  testWidgets('online, an unknown barcode still reports that nothing was '
      'found', (tester) async {
    final camera = FakeMobileScannerPlatform.install();
    await tester.pumpWidget(
      _buildHarness(
        off: FakeOffBarcodeRepository(),
        learned: FakeGlobalBarcodeCandidateRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await _scanBarcodeInEditor(tester, camera);

    expect(find.byType(AppSnackBarView), findsOneWidget);
    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsNothing,
    );
    expect(_barcodeFieldText(tester), _barcode);
  });
}
