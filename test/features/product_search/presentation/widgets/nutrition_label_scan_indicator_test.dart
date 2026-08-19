import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'nutrition_label_scan_indicator/nutrition_label_scan_indicator.dart';

const _testImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
    '+A8AAQUBAScY42YAAAAASUVORK5CYII=';

void main() {
  testWidgets('shows captured image and animates scan line', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionLabelScanIndicator(
            imageBytes: base64Decode(_testImageBase64),
            statusLabel: 'Reading nutrition label…',
            semanticLabel: 'Captured nutrition label is being scanned',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('nutrition_label_scan_image')),
      findsOneWidget,
    );
    expect(find.text('Reading nutrition label…'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Captured nutrition label is being scanned'),
      findsOneWidget,
    );

    final scanLine = find.byKey(const Key('nutrition_label_scan_line'));
    final initialY = tester.getTopLeft(scanLine).dy;
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.getTopLeft(scanLine).dy, isNot(initialY));
    semantics.dispose();
  });

  testWidgets('keeps scan line still when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: NutritionLabelScanIndicator(
              imageBytes: base64Decode(_testImageBase64),
              statusLabel: 'Reading nutrition label…',
              semanticLabel: 'Captured nutrition label is being scanned',
            ),
          ),
        ),
      ),
    );

    final scanLine = find.byKey(const Key('nutrition_label_scan_line'));
    final initialY = tester.getTopLeft(scanLine).dy;
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.getTopLeft(scanLine).dy, initialY);
  });
}
