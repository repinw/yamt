import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/barcode_scanner/app_barcode_scanner_page.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay_painter.dart';
import 'package:yamt/core/widgets/barcode_scanner/windowed_mobile_scanner.dart';

import '../../../helpers/fake_mobile_scanner_platform.dart';

const _barcode = '4006381333931';

/// Opens the page with a clock that reads [now].
Future<List<String>> _pumpPage(
  WidgetTester tester, {
  DateTime Function()? now,
}) async {
  final scanned = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clockProvider.overrideWithValue(now ?? () => DateTime(2026))],
      child: MaterialApp(
        home: AppBarcodeScannerPage(
          title: 'Scan',
          onBarcodeScanned: (barcode) async {
            scanned.add(barcode);
            return true;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return scanned;
}

void main() {
  late FakeMobileScannerPlatform camera;

  setUp(() => camera = FakeMobileScannerPlatform.install());

  testWidgets('reads only around the drawn frame', (tester) async {
    await _pumpPage(tester);

    final size = tester.getSize(find.byType(MobileScanner));
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    expect(
      scanner.scanWindow,
      barcodeReticleRect(
        size,
        defaultBarcodeScanWindowSize,
      ).inflate(WindowedMobileScanner.margin).intersect(Offset.zero & size),
    );
  });

  testWidgets('takes a barcode read twice, not one read once', (tester) async {
    final scanned = await _pumpPage(tester);

    camera.glimpse(_barcode);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scanned, isEmpty);

    camera.glimpse(_barcode);
    await tester.pump(const Duration(milliseconds: 300));
    expect(scanned, [_barcode]);
  });

  testWidgets('a second read that comes too late does not count', (
    tester,
  ) async {
    var now = DateTime(2026);
    final scanned = await _pumpPage(tester, now: () => now);

    camera.glimpse(_barcode);
    await tester.pump(const Duration(milliseconds: 300));
    now = now.add(const Duration(seconds: 2));
    camera.glimpse(_barcode);
    await tester.pump(const Duration(milliseconds: 300));

    expect(scanned, isEmpty);
  });
}
