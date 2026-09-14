import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yamt/features/scanner/data/google_ai_receipt_parser.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

void main() {
  group('GoogleAiReceiptParser', () {
    const validJsonResponse = '''
    {
      "storeName": "REWE Markt GmbH",
      "dateTime": "2026-09-13T14:30:00",
      "printedTotal": 6.78,
      "currency": "EUR",
      "items": [
        {"rawName": "JA! VOLLMILCH 3.8% 1L", "totalPrice": 1.49, "discount": 0.0, "quantity": 1.0, "unitPrice": 1.49, "unit": "l", "rawCategory": "Molkereiprodukte", "rawBrand": "Ja!", "packageWeight": "1L", "isDeposit": false, "isDiscount": false},
        {"rawName": "BANANEN BIO", "totalPrice": 2.29, "discount": 0.30, "quantity": 0.850, "unitPrice": 2.69, "unit": "kg", "rawCategory": "Obst & Gemüse", "isDeposit": false, "isDiscount": false},
        {"rawName": "EINWEGPFAND 0,25", "totalPrice": 0.25, "isDeposit": true, "isDiscount": false},
        {"rawName": "COUPON RABATT", "totalPrice": 1.00, "isDeposit": false, "isDiscount": true}
      ]
    }
    ''';

    test('parseRawText parses valid JSON into ScannedReceipt', () async {
      Iterable<Content>? capturedPrompt;
      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async {
          capturedPrompt = content;
          return validJsonResponse;
        },
      );

      const rawText = 'REWE\nJA! VOLLMILCH 1.49\nBANANEN BIO 2.29\nSUMME 6.78';
      final receipt = await parser.parseRawText(
        rawText: rawText,
        sourceFilePaths: const <String>['/images/receipt.jpg'],
      );

      expect(receipt.storeName, 'REWE Markt GmbH');
      expect(receipt.printedTotal, 6.78);
      expect(receipt.currency, 'EUR');
      expect(receipt.dateTime, DateTime(2026, 9, 13, 14, 30));
      expect(receipt.sourceFilePaths, const <String>['/images/receipt.jpg']);
      expect(receipt.rawText, rawText);
      expect(receipt.items, hasLength(4));

      // Check product item
      final milk = receipt.items[0];
      expect(milk.rawName, 'JA! VOLLMILCH 3.8% 1L');
      expect(milk.totalPrice, 1.49);
      expect(milk.discount, 0.0);
      expect(milk.quantity, 1.0);
      expect(milk.unitPrice, 1.49);
      expect(milk.unit, 'l');
      expect(milk.rawCategory, 'Molkereiprodukte');
      expect(milk.rawBrand, 'Ja!');
      expect(milk.packageWeight, '1L');
      expect(milk.isDeposit, isFalse);
      expect(milk.isDiscount, isFalse);
      expect(milk.status, ReceiptItemStatus.unmatched);

      // Check discounted/weighed item
      final bananas = receipt.items[1];
      expect(bananas.rawName, 'BANANEN BIO');
      expect(bananas.totalPrice, 2.29);
      expect(bananas.discount, 0.30);
      expect(bananas.quantity, 0.850);
      expect(bananas.effectivePrice, closeTo(1.99, 0.001));
      expect(bananas.status, ReceiptItemStatus.unmatched);

      // Check deposit line
      final deposit = receipt.items[2];
      expect(deposit.rawName, 'EINWEGPFAND 0,25');
      expect(deposit.isDeposit, isTrue);
      expect(deposit.status, ReceiptItemStatus.confirmed);

      // Check coupon line
      final coupon = receipt.items[3];
      expect(coupon.rawName, 'COUPON RABATT');
      expect(coupon.isDiscount, isTrue);
      expect(coupon.effectivePrice, -1.00);
      expect(coupon.status, ReceiptItemStatus.confirmed);

      // Verify prompt content
      expect(capturedPrompt, isNotNull);
    });

    test(
      'parsePdf throws FileSystemException when file does not exist',
      () async {
        final parser = GoogleAiReceiptParser(
          contentHandler: (content) async => validJsonResponse,
        );

        expect(
          () => parser.parsePdf(pdfFilePath: '/nonexistent/receipt.pdf'),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test('parsePdf reads existing file and parses response', () async {
      final tempDir = await Directory.systemTemp.createTemp('receipt_test');
      final tempFile = File('${tempDir.path}/test_receipt.pdf');
      await tempFile.writeAsBytes(<int>[1, 2, 3, 4]);

      try {
        final parser = GoogleAiReceiptParser(
          contentHandler: (content) async {
            // Verify content has PDF data part
            expect(content.first.parts, anyElement(isA<DataPart>()));
            return validJsonResponse;
          },
        );

        final receipt = await parser.parsePdf(pdfFilePath: tempFile.path);

        expect(receipt.storeName, 'REWE Markt GmbH');
        expect(receipt.items, hasLength(4));
        expect(receipt.sourceFilePaths, <String>[tempFile.path]);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws FormatException when AI returns empty string', () async {
      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async => '',
      );

      expect(
        () => parser.parseRawText(rawText: 'text'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when AI returns invalid JSON', () async {
      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async => 'Not valid JSON at all',
      );

      expect(
        () => parser.parseRawText(rawText: 'text'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'throws FormatException when items array is missing in JSON',
      () async {
        final parser = GoogleAiReceiptParser(
          contentHandler: (content) async => '{"storeName": "Lidl"}',
        );

        expect(
          () => parser.parseRawText(rawText: 'text'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('skips items without rawName', () async {
      const jsonWithBlankItem = '''
      {
        "storeName": "Aldi",
        "items": [
          {"rawName": "", "totalPrice": 1.99},
          {"rawName": "Kaffee", "totalPrice": 4.99}
        ]
      }
      ''';

      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async => jsonWithBlankItem,
      );

      final receipt = await parser.parseRawText(rawText: 'text');
      expect(receipt.items, hasLength(1));
      expect(receipt.items.first.rawName, 'Kaffee');
    });

    test('parses German date format as fallback when not ISO-8601', () async {
      const jsonWithGermanDate = '''
      {
        "storeName": "Edeka",
        "dateTime": "13.09.2026 14:30:45",
        "items": [{"rawName": "Brot", "totalPrice": 2.50}]
      }
      ''';

      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async => jsonWithGermanDate,
      );

      final receipt = await parser.parseRawText(rawText: 'text');
      expect(receipt.dateTime, DateTime(2026, 9, 13, 14, 30, 45));
    });

    test('preserves negative price on deposit refund', () async {
      const jsonWithRefund = '''
      {
        "storeName": "Rewe",
        "items": [
          {"rawName": "LEERGUTRUECKGABE", "totalPrice": -2.50, "isDeposit": true}
        ]
      }
      ''';

      final parser = GoogleAiReceiptParser(
        contentHandler: (content) async => jsonWithRefund,
      );

      final receipt = await parser.parseRawText(rawText: 'text');
      final refund = receipt.items.first;
      expect(refund.totalPrice, -2.50);
      expect(refund.effectivePrice, -2.50);
      expect(refund.isDeposit, isTrue);
      expect(refund.status, ReceiptItemStatus.confirmed);
    });

    test(
      'throws ArgumentError when constructed without API key or handler',
      () {
        expect(
          () => GoogleAiReceiptParser(apiKey: ''),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
