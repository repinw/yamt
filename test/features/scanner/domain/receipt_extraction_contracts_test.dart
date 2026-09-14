import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import '../fakes/fake_receipt_structured_parser.dart';
import '../fakes/fake_receipt_text_extractor.dart';

void main() {
  group('ReceiptTextExtractor contract & Fake', () {
    test('extracts configured text and records file paths', () async {
      final extractor = FakeReceiptTextExtractor();
      final paths = <String>['/tmp/slice1.jpg', '/tmp/slice2.jpg'];

      final text = await extractor.extractText(paths);

      expect(text, contains('REWE Markt GmbH'));
      expect(extractor.extractedPathsHistory, hasLength(1));
      expect(extractor.extractedPathsHistory.first, paths);
    });

    test('throws when shouldFail is set to true', () async {
      final extractor = FakeReceiptTextExtractor()
        ..shouldFail = true
        ..failureMessage = 'OCR unreadable';

      expect(
        () => extractor.extractText(<String>['/tmp/blur.jpg']),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('OCR unreadable'),
          ),
        ),
      );
    });
  });

  group('ReceiptStructuredParser contract & Fake', () {
    test('parses raw text and preserves source paths and rawText', () async {
      final parser = FakeReceiptStructuredParser();
      const testReceipt = ScannedReceipt(
        id: 'receipt-1',
        storeName: 'Aldi Süd',
        printedTotal: 12.50,
        items: <ReceiptLineItem>[
          ReceiptLineItem(
            id: 'item-1',
            rawName: 'BIO MILCH 3.8%',
            totalPrice: 1.15,
          ),
        ],
      );
      parser.nextReceipt = testReceipt;

      final result = await parser.parseRawText(
        rawText: 'ALDI SUED\nBIO MILCH 1.15',
        sourceFilePaths: const <String>['/docs/slice1.jpg'],
      );

      expect(result.storeName, 'Aldi Süd');
      expect(result.printedTotal, 12.50);
      expect(result.items, hasLength(1));
      expect(result.rawText, 'ALDI SUED\nBIO MILCH 1.15');
      expect(result.sourceFilePaths, const <String>['/docs/slice1.jpg']);
      expect(parser.parsedRawTextsHistory, hasLength(1));
      expect(parser.sourceFilePathsHistory.first, const <String>[
        '/docs/slice1.jpg',
      ]);
    });

    test('parses PDF e-receipt directly preserving file path', () async {
      final parser = FakeReceiptStructuredParser();
      const testReceipt = ScannedReceipt(
        id: 'receipt-pdf',
        storeName: 'Lidl',
        printedTotal: 5.99,
        items: <ReceiptLineItem>[
          ReceiptLineItem(
            id: 'item-1',
            rawName: 'Apfelsaft 1L',
            totalPrice: 1.29,
          ),
        ],
      );
      parser.nextReceipt = testReceipt;

      final result = await parser.parsePdf(
        pdfFilePath: '/downloads/lidl_plus_receipt.pdf',
      );

      expect(result.storeName, 'Lidl');
      expect(result.printedTotal, 5.99);
      expect(result.items, hasLength(1));
      expect(result.sourceFilePaths, const <String>[
        '/downloads/lidl_plus_receipt.pdf',
      ]);
      expect(parser.parsedPdfPathsHistory, const <String>[
        '/downloads/lidl_plus_receipt.pdf',
      ]);
    });

    test('throws when parser encounters invalid response', () async {
      final parser = FakeReceiptStructuredParser()
        ..shouldFail = true
        ..failureMessage = 'Invalid JSON from AI';

      expect(
        () => parser.parseRawText(rawText: 'some unparseable text'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid JSON from AI'),
          ),
        ),
      );
    });
  });

  group('Hybrid Extraction & Parsing Pipeline Simulation', () {
    test('extracts raw text locally and parses into ScannedReceipt', () async {
      final extractor = FakeReceiptTextExtractor()
        ..nextRawText = 'EDEKA\nHaferflocken 0.79\nApfel 1.99\nSumme 2.78';
      final parser = FakeReceiptStructuredParser()
        ..nextReceipt = const ScannedReceipt(
          id: 'receipt-edeka',
          storeName: 'EDEKA',
          printedTotal: 2.78,
          items: <ReceiptLineItem>[
            ReceiptLineItem(
              id: '1',
              rawName: 'Haferflocken',
              totalPrice: 0.79,
            ),
            ReceiptLineItem(
              id: '2',
              rawName: 'Apfel',
              totalPrice: 1.99,
            ),
          ],
        );

      final filePaths = <String>['/camera/receipt_photo.jpg'];

      // Step 1: Local on-device text extraction
      final rawText = await extractor.extractText(filePaths);
      expect(rawText, contains('Haferflocken'));

      // Step 2: Lightweight structured parsing (Gemini Flash)
      final receipt = await parser.parseRawText(
        rawText: rawText,
        sourceFilePaths: filePaths,
      );

      expect(receipt.storeName, 'EDEKA');
      expect(receipt.items, hasLength(2));
      expect(receipt.calculatedTotal, closeTo(2.78, 0.001));
      expect(receipt.sourceFilePaths, filePaths);
      expect(receipt.rawText, rawText);
    });
  });
}
