import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/barcode_utils.dart';

void main() {
  group('normalizeBarcode', () {
    test('removes whitespace and hyphens from barcode numbers', () {
      expect(normalizeBarcode('  40-0638 1333 931  '), '4006381333931');
      expect(normalizeBarcode('4006381333931'), '4006381333931');
    });

    test('rejects URLs and strings with letters (e.g. from QR codes)', () {
      expect(normalizeBarcode('https://example.com/item/4006381333931'), '');
      expect(normalizeBarcode('http://yamt.app/12345678'), '');
      expect(normalizeBarcode('WIFI:S:MyNet;P:12345678;;'), '');
      expect(normalizeBarcode('Product 12345678'), '');
      expect(normalizeBarcode('abc12345678'), '');
    });
  });

  group('isSupportedBarcode', () {
    test('validates expected lengths', () {
      expect(isSupportedBarcode('1234567'), isFalse);
      expect(isSupportedBarcode('12345678'), isTrue);
      expect(isSupportedBarcode('12345678901234'), isTrue);
      expect(isSupportedBarcode('123456789012345'), isFalse);
    });

    test('rejects non-digit strings', () {
      expect(isSupportedBarcode('1234567a'), isFalse);
      expect(isSupportedBarcode('abcdefgh'), isFalse);
      expect(isSupportedBarcode(''), isFalse);
    });
  });

  group('isValidGtinChecksum', () {
    test('validates authentic EAN-13 barcodes', () {
      // German EAN-13 examples
      expect(isValidGtinChecksum('4006381333931'), isTrue);
      expect(isValidGtinChecksum('7394376616037'), isTrue);
      expect(isValidGtinChecksum('4008400404127'), isTrue);
    });

    test('validates authentic EAN-8 barcodes', () {
      expect(isValidGtinChecksum('96385074'), isTrue);
      expect(isValidGtinChecksum('12345670'), isTrue);
    });

    test('validates authentic UPC-A (12-digit) barcodes', () {
      expect(isValidGtinChecksum('012345678905'), isTrue);
      expect(isValidGtinChecksum('614141999996'), isTrue);
    });

    test('validates authentic ITF-14 (14-digit) barcodes', () {
      expect(isValidGtinChecksum('10012345678902'), isTrue);
    });

    test('rejects invalid checksums', () {
      // 4006381333931 has check digit 1. Changing to 2 should fail.
      expect(isValidGtinChecksum('4006381333932'), isFalse);
      expect(isValidGtinChecksum('12345678'), isFalse);
    });

    test('rejects unsupported lengths or non-numeric strings', () {
      expect(isValidGtinChecksum('1234567'), isFalse);
      expect(isValidGtinChecksum('123456789'), isFalse); // length 9
      expect(isValidGtinChecksum('12345678901'), isFalse); // length 11
      expect(isValidGtinChecksum('400638133393a'), isFalse);
    });
  });

  group('isValidBarcode', () {
    test('validates valid barcodes with checksum', () {
      expect(isValidBarcode('4006381333931'), isTrue);
      expect(isValidBarcode('96385074'), isTrue);
      expect(isValidBarcode('4006381333932'), isFalse);
      expect(isValidBarcode('abcdefgh'), isFalse);
    });

    test('allows bypassing checksum enforcement when requested', () {
      expect(isValidBarcode('12345678', enforceChecksum: false), isTrue);
    });
  });
}
