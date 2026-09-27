import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';

const _response = '''
{
  "s": "REWE",
  "dt": "2026-09-27T14:31:00",
  "t": 4.89,
  "cur": "EUR",
  "i": [
    {"r": "JA! VOLLMILCH 3,8% 1L", "n": "Vollmilch 3,8%", "b": "JA!", "w": "1L", "p": 1.19, "f": true, "dp": false, "dc": false},
    {"r": "TRAGETASCHE", "n": "Tragetasche", "p": 0.30, "f": false, "dp": false, "dc": false},
    {"r": "PFAND 0,25", "n": "Pfand", "p": 0.25, "f": false, "dp": true, "dc": false},
    {"r": "BANANEN", "n": "Bananen", "q": 1.02, "u": "kg", "up": 1.31, "p": 1.34, "d": 0.2, "f": true, "dp": false, "dc": false},
    {"r": "RABATT PAPRIKA", "n": "Rabatt Paprika", "p": -0.30, "f": false, "dp": false, "dc": true}
  ]
}
''';

void main() {
  late Directory tempDir;
  late String photoPath;
  late String pdfPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('receipt_ai_test');
    photoPath = '${tempDir.path}/receipt.jpg';
    pdfPath = '${tempDir.path}/receipt.pdf';
    File(photoPath).writeAsBytesSync([1, 2, 3]);
    File(pdfPath).writeAsBytesSync([4, 5]);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('sends every file with its MIME type in receipt order', () async {
    Map<String, Object?>? sentInputs;
    final repository = ReceiptAiRepository(
      templateClient: (inputs) async {
        sentInputs = inputs;
        return _response;
      },
    );

    await repository.parseReceipt([photoPath, pdfPath]);

    expect(sentInputs, {
      'files': [
        {
          'mimeType': 'image/jpeg',
          'data': base64Encode([1, 2, 3]),
        },
        {
          'mimeType': 'application/pdf',
          'data': base64Encode([4, 5]),
        },
      ],
    });
  });

  test('maps the receipt and its lines', () async {
    final repository = ReceiptAiRepository(
      templateClient: (_) async => _response,
    );

    final receipt = await repository.parseReceipt([photoPath]);

    expect(receipt.storeName, 'REWE');
    expect(receipt.dateTime, DateTime(2026, 9, 27, 14, 31));
    expect(receipt.printedTotal, 4.89);
    expect(receipt.sourceFilePaths, [photoPath]);
    expect(receipt.items, hasLength(5));

    final milk = receipt.items[0];
    expect(milk.rawName, 'JA! VOLLMILCH 3,8% 1L');
    expect(milk.productName, 'Vollmilch 3,8%');
    expect(milk.rawBrand, 'JA!');
    expect(milk.packageWeight, '1L');
    expect(milk.quantity, 1);

    final bananas = receipt.items[3];
    expect(bananas.quantity, 1.02);
    expect(bananas.unit, 'kg');
    expect(bananas.unitPrice, 1.31);
    expect(bananas.discount, 0.2);
  });

  test('non-food lines start ignored, food lines start unmatched', () async {
    final repository = ReceiptAiRepository(
      templateClient: (_) async => _response,
    );

    final receipt = await repository.parseReceipt([photoPath]);
    final statuses = {
      for (final item in receipt.items) item.rawName: item.status,
    };

    expect(statuses, {
      'JA! VOLLMILCH 3,8% 1L': ReceiptItemStatus.unmatched,
      'TRAGETASCHE': ReceiptItemStatus.ignored,
      'PFAND 0,25': ReceiptItemStatus.confirmed,
      'BANANEN': ReceiptItemStatus.unmatched,
      'RABATT PAPRIKA': ReceiptItemStatus.confirmed,
    });
    expect(receipt.items[2].isDeposit, isTrue);
    expect(receipt.items[4].isDiscount, isTrue);
  });

  test('throws on an empty response', () async {
    final repository = ReceiptAiRepository(templateClient: (_) async => ' ');

    expect(
      () => repository.parseReceipt([photoPath]),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects files that are neither images nor PDFs', () async {
    final textPath = '${tempDir.path}/notes.txt';
    File(textPath).writeAsStringSync('hello');
    final repository = ReceiptAiRepository(
      templateClient: (_) async => _response,
    );

    expect(
      () => repository.parseReceipt([textPath]),
      throwsA(isA<ArgumentError>()),
    );
  });
}
