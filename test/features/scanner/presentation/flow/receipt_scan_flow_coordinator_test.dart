import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

import '../../fakes/receipt_scan_flow_test_harness.dart';

void main() {
  late ReceiptScanFlowTestHarness harness;

  setUp(() {
    harness = ReceiptScanFlowTestHarness();
  });

  group('ReceiptScanFlowCoordinator inputs & errors', () {
    testWidgets('startCameraFlow returns false when picker returns null', (
      tester,
    ) async {
      bool? flowResult;
      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            final coordinator = harness.createCoordinator(
              cameraPicker: () async => null,
            );
            flowResult = await coordinator.startCameraFlow(context);
          },
          child: const Text('Camera'),
        ),
      );

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(flowResult, isFalse);
      expect(harness.fakeExtractor.extractedPathsHistory, isEmpty);
    });

    testWidgets('startCameraFlow processes image and navigates to review', (
      tester,
    ) async {
      harness.fakeParser.nextReceipt = const ScannedReceipt(
        id: 'img-receipt',
        storeName: 'ALDI',
        items: [ReceiptLineItem(id: '1', rawName: 'MILCH', totalPrice: 1.19)],
      );

      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            await harness
                .createCoordinator(
                  cameraPicker: () async => '/tmp/photo.jpg',
                )
                .startCameraFlow(context);
          },
          child: const Text('Camera'),
        ),
      );

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(harness.fakeExtractor.extractedPathsHistory, [
        ['/tmp/photo.jpg'],
      ]);
      expect(find.text('Beleg prüfen'), findsOneWidget);
      expect(find.text('ALDI'), findsOneWidget);
    });

    testWidgets('startFilePickerFlow returns false when picker returns empty', (
      tester,
    ) async {
      bool? flowResult;
      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            final coordinator = harness.createCoordinator(
              filesPicker: () async => <String>[],
            );
            flowResult = await coordinator.startFilePickerFlow(context);
          },
          child: const Text('Pick'),
        ),
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(flowResult, isFalse);
      expect(harness.fakeParser.parsedPdfPathsHistory, isEmpty);
    });

    testWidgets('startFilePickerFlow processes PDF directly via parser', (
      tester,
    ) async {
      harness.fakeParser.nextReceipt = const ScannedReceipt(
        id: 'pdf-receipt',
        storeName: 'LIDL',
        items: [ReceiptLineItem(id: '1', rawName: 'SAFT', totalPrice: 1.49)],
      );

      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            await harness
                .createCoordinator(
                  filesPicker: () async => ['/documents/lidl.pdf'],
                )
                .startFilePickerFlow(context);
          },
          child: const Text('Pick PDF'),
        ),
      );

      await tester.tap(find.text('Pick PDF'));
      await tester.pumpAndSettle();
      expect(harness.fakeExtractor.extractedPathsHistory, isEmpty);
      expect(harness.fakeParser.parsedPdfPathsHistory, ['/documents/lidl.pdf']);
      expect(find.text('Beleg prüfen'), findsOneWidget);
    });

    testWidgets('shows snackbar when extraction fails', (tester) async {
      harness.fakeExtractor.shouldFail = true;

      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            await harness.createCoordinator().processFilePaths(context, [
              '/tmp/broken.png',
            ]);
          },
          child: const Text('Broken'),
        ),
      );

      await tester.tap(find.text('Broken'));
      await tester.pumpAndSettle();
      expect(find.text('Beleg prüfen'), findsNothing);
      expect(
        find.textContaining('Belegverarbeitung fehlgeschlagen'),
        findsOneWidget,
      );
    });
  });
}
