import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

import '../../fakes/receipt_scan_flow_test_harness.dart';

void main() {
  late ReceiptScanFlowTestHarness harness;

  setUp(() {
    harness = ReceiptScanFlowTestHarness();
  });

  group('ReceiptScanFlowCoordinator product resolution', () {
    testWidgets('pre-resolves alias exact and catalog fuzzy products', (
      tester,
    ) async {
      const exactCandidate = ProductCandidate(
        id: 'p-1',
        name: 'Frische Vollmilch 3.8%',
        source: CandidateSource.aliasExact,
      );
      const fuzzyCandidate = ProductCandidate(
        id: 'p-2',
        name: 'Bananen Bio',
      );

      harness.fakeResolver
        ..registerCandidatesForText('VOLLMILCH', [exactCandidate])
        ..registerCandidatesForText('BANANEN', [fuzzyCandidate]);

      harness.fakeParser.nextReceipt = const ScannedReceipt(
        id: 'match-receipt',
        storeName: 'REWE',
        items: [
          ReceiptLineItem(id: '1', rawName: 'VOLLMILCH', totalPrice: 1.09),
          ReceiptLineItem(id: '2', rawName: 'BANANEN', totalPrice: 2.19),
        ],
      );

      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            await harness.createCoordinator().processFilePaths(context, [
              '/tmp/rewe.png',
            ]);
          },
          child: const Text('Scan'),
        ),
      );

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Beleg prüfen'), findsOneWidget);
      expect(find.text('Frische Vollmilch 3.8%'), findsOneWidget);
      expect(find.text('Bananen Bio'), findsOneWidget);
    });

    testWidgets('handles resolver failure gracefully', (tester) async {
      harness.fakeResolver.shouldFail = true;
      harness.fakeParser.nextReceipt = const ScannedReceipt(
        id: 'fail-receipt',
        storeName: 'EDEKA',
        items: [ReceiptLineItem(id: '1', rawName: 'BUTTER', totalPrice: 2.29)],
      );

      await harness.pump(
        tester,
        builder: (context, ref) => ElevatedButton(
          onPressed: () async {
            await harness.createCoordinator().processFilePaths(context, [
              '/tmp/edeka.png',
            ]);
          },
          child: const Text('Scan'),
        ),
      );

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text('Beleg prüfen'), findsOneWidget);
      expect(find.text('BUTTER'), findsOneWidget);
    });
  });
}
