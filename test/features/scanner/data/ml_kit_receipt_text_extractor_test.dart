import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/ml_kit_receipt_text_extractor.dart';

void main() {
  group('MlKitReceiptTextExtractor', () {
    test('returns empty string when filePaths list is empty', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async => 'text',
      );

      final result = await extractor.extractText(<String>[]);

      expect(result, '');
    });

    test('extracts and trims text from single file', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async {
          expect(path, '/images/receipt_1.jpg');
          return '   REWE MARKT GMBH\nMilch 1.49   ';
        },
      );

      final result = await extractor.extractText(<String>[
        '/images/receipt_1.jpg',
      ]);

      expect(result, 'REWE MARKT GMBH\nMilch 1.49');
    });

    test('concatenates multiple slices with newlines', () async {
      final processedPaths = <String>[];
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async {
          processedPaths.add(path);
          if (path.contains('slice1')) {
            return 'REWE MARKT\nTop Part';
          } else {
            return 'Bottom Part\nSUMME 12.34';
          }
        },
      );

      final result = await extractor.extractText(<String>[
        '/images/slice1.jpg',
        '/images/slice2.jpg',
      ]);

      expect(result, 'REWE MARKT\nTop Part\nBottom Part\nSUMME 12.34');
      expect(processedPaths, <String>[
        '/images/slice1.jpg',
        '/images/slice2.jpg',
      ]);
    });

    test('ignores empty slices in multi-image input', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async {
          if (path.contains('slice1')) return 'Header';
          if (path.contains('slice2')) return '   ';
          return 'Footer';
        },
      );

      final result = await extractor.extractText(<String>[
        '/images/slice1.jpg',
        '/images/slice2.jpg',
        '/images/slice3.jpg',
      ]);

      expect(result, 'Header\nFooter');
    });

    test('propagates exception when processor fails', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async => throw Exception('Unreadable image'),
      );

      expect(
        () => extractor.extractText(<String>['/images/corrupted.jpg']),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unreadable image'),
          ),
        ),
      );
    });

    test('skips empty and whitespace-only file paths', () async {
      final processed = <String>[];
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async {
          processed.add(path);
          return 'Valid';
        },
      );

      final result = await extractor.extractText(<String>[
        '',
        '   ',
        '/images/valid.jpg',
        '  ',
      ]);

      expect(result, 'Valid');
      expect(processed, <String>['/images/valid.jpg']);
    });

    test('throws ArgumentError when given a PDF file path', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async => 'text',
      );

      expect(
        () => extractor.extractText(<String>['/docs/e_receipt.pdf']),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('MlKitReceiptTextExtractor only supports image files'),
          ),
        ),
      );
    });

    test('disposes owned recognizer without error', () async {
      final extractor = MlKitReceiptTextExtractor(
        fileProcessor: (path) async => 'dummy',
      );

      await expectLater(extractor.dispose(), completes);
    });
  });
}
