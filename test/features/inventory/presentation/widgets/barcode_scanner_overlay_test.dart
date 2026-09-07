import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'barcode_scanner_overlay/barcode_scanner_overlay.dart';

void main() {
  testWidgets('BarcodeScannerOverlay renders cutout, hint, and brackets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BarcodeScannerOverlay(
            hintMessage: 'Align barcode inside the frame',
          ),
        ),
      ),
    );

    expect(find.byType(BarcodeScannerOverlay), findsOneWidget);
    expect(find.text('Align barcode inside the frame'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    // Torch button should not be present when callback is null
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('BarcodeScannerOverlay torch toggle triggers callback', (
    tester,
  ) async {
    var toggleCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeScannerOverlay(
            onToggleTorch: () => toggleCount++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(toggleCount, 1);
  });

  testWidgets('BarcodeScannerOverlay displays active torch icon when on', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeScannerOverlay(
            isTorchOn: true,
            onToggleTorch: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);
  });

  testWidgets('BarcodeScannerOverlay animates checkmark on lock-on', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BarcodeScannerOverlay(),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsNothing);

    // Rebuild with isLocked = true
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BarcodeScannerOverlay(
            isLocked: true,
          ),
        ),
      ),
    );

    // Initial lock frame
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Pump through the 350ms lock animation
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('BarcodeScannerOverlay handles disableAnimations cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: BarcodeScannerOverlay(
              hintMessage: 'Scanning paused',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Scanning paused'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(BarcodeScannerOverlay), findsOneWidget);
  });
}
