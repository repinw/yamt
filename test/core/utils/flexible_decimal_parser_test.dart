import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/flexible_decimal_parser.dart';

void main() {
  group('parseFlexibleDecimal', () {
    test('parses German and English grouped decimals', () {
      expect(parseFlexibleDecimal('1.000,50'), 1000.5);
      expect(parseFlexibleDecimal('1,000.50'), 1000.5);
      expect(parseFlexibleDecimal('1 000,50'), 1000.5);
    });

    test('parses grouped whole numbers', () {
      expect(parseFlexibleDecimal('1.234.567'), 1234567);
      expect(parseFlexibleDecimal('1,234,567'), 1234567);
      expect(parseFlexibleDecimal('1,000,000'), 1000000);
    });

    test('parses decimals without leading zero', () {
      expect(parseFlexibleDecimal('.5'), 0.5);
      expect(parseFlexibleDecimal(',5'), 0.5);
    });

    test('a leading 0 is never a thousands group', () {
      expect(parseFlexibleDecimal('0,250'), 0.25);
      expect(parseFlexibleDecimal('0.250'), 0.25);
      expect(parseFlexibleDecimal('0,5'), 0.5);
    });

    test('three digits after another number stay a thousands group', () {
      expect(parseFlexibleDecimal('1,250'), 1250);
      expect(parseFlexibleDecimal('1.250'), 1250);
    });

    test('rejects malformed grouped numbers', () {
      expect(parseFlexibleDecimal('1.2.3'), isNull);
      expect(parseFlexibleDecimal('1,00,000'), isNull);
      expect(parseFlexibleDecimal('abc'), isNull);
    });
  });
}
