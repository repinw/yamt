import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay_painter.dart';
import 'package:yamt/core/widgets/barcode_scanner/windowed_mobile_scanner.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_scanner_page/'
    'product_search_barcode_scanner_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_barcode_scanner_page/'
    'product_search_barcode_scanner_view.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../../../../../helpers/fake_barcode_sources.dart';
import '../../../../../helpers/fake_mobile_scanner_platform.dart';

const _barcode = '4006381333931';

final _l10n = AppLocalizationsEn();

/// What the scanner handed to its caller.
class _Calls {
  final notFound = <String>[];
  final manual = <String>[];
}

Future<_Calls> _pumpScanner(
  WidgetTester tester, {
  required FakeOffBarcodeRepository off,
  required FakeGlobalBarcodeCandidateRepository learned,
  bool canCreateManual = true,
}) async {
  final calls = _Calls();
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
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InventoryBarcodeScannerPage(
          title: 'Scan',
          onProductSelected: (_, _, _) async => true,
          onProductNotFound: (barcode) async {
            calls.notFound.add(barcode);
            return true;
          },
          onCreateManualProduct: canCreateManual
              ? (barcode) async {
                  calls.manual.add(barcode);
                  return true;
                }
              : null,
        ),
      ),
    ),
  );
  await tester.pump();
  return calls;
}

/// Shows [_barcode] to the camera and lets both sources answer.
Future<void> _scan(
  WidgetTester tester,
  FakeMobileScannerPlatform camera,
) async {
  camera.scan(_barcode);
  // The scanner waits a moment before it looks the barcode up.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(barcodeSourceAnswerDelay * 2);
  await tester.pump();
}

void main() {
  late FakeMobileScannerPlatform camera;

  setUp(() => camera = FakeMobileScannerPlatform.install());

  testWidgets('offline, the scanner says that the lookup needs a connection '
      'and keeps the barcode for a manual product', (tester) async {
    final calls = await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(error: offlineHttpError),
      learned: FakeGlobalBarcodeCandidateRepository(),
    );

    await _scan(tester, camera);

    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsOneWidget,
    );
    expect(find.text(_l10n.inventoryManualAddLookupOffline), findsOneWidget);
    expect(find.text(_l10n.inventoryManualAddNotFound), findsNothing);
    expect(calls.notFound, isEmpty);
    expect(calls.manual, [_barcode]);
  });

  testWidgets('offline without a manual product, the barcode goes to the '
      'not-found handler', (tester) async {
    final calls = await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(error: offlineHttpError),
      learned: FakeGlobalBarcodeCandidateRepository(),
      canCreateManual: false,
    );

    await _scan(tester, camera);

    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsOneWidget,
    );
    expect(calls.notFound, [_barcode]);
  });

  testWidgets('a barcode read on a single frame does not count', (
    tester,
  ) async {
    final calls = await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(),
      learned: FakeGlobalBarcodeCandidateRepository(),
    );

    camera.glimpse(_barcode);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(barcodeSourceAnswerDelay * 2);

    expect(calls.notFound, isEmpty);
    expect(camera.isRunning, isTrue);
  });

  testWidgets('the scanner reads only inside the drawn frame', (tester) async {
    await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(),
      learned: FakeGlobalBarcodeCandidateRepository(),
    );
    await tester.pump();

    final size = tester.getSize(find.byType(MobileScanner));
    final frame = barcodeReticleRect(size, defaultBarcodeScanWindowSize);
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    expect(
      scanner.scanWindow,
      frame.inflate(WindowedMobileScanner.margin).intersect(Offset.zero & size),
    );
    // The camera gets the frame as a part of its picture, not all of it.
    final window = camera.scanWindow!;
    expect(window.left, greaterThan(0));
    expect(window.top, greaterThan(0));
    expect(window.right, lessThan(1));
    expect(window.bottom, lessThan(1));
  });

  testWidgets('an unknown barcode still counts as not found', (tester) async {
    final calls = await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(),
      learned: FakeGlobalBarcodeCandidateRepository(),
    );

    await _scan(tester, camera);

    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsNothing,
    );
    expect(calls.notFound, [_barcode]);
    expect(calls.manual, isEmpty);
  });

  testWidgets('with one source offline, the other source still shows its '
      'products', (tester) async {
    final calls = await _pumpScanner(
      tester,
      off: FakeOffBarcodeRepository(
        results: const [
          OffProductSearchResult(
            code: _barcode,
            name: 'Milk',
            brand: 'Acme',
            score: 100,
          ),
        ],
      ),
      learned: FakeGlobalBarcodeCandidateRepository(
        error: FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      ),
    );

    await _scan(tester, camera);
    // The spinner keeps running while the sheet is open, so it never settles.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(inventoryBarcodeCandidateSheetKey), findsOneWidget);
    expect(
      find.byKey(InventoryBarcodeScannerView.lookupOfflineKey),
      findsNothing,
    );
    expect(calls.notFound, isEmpty);
    expect(calls.manual, isEmpty);
  });
}
