import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

void main() {
  group('FlexibleDoubleConverter', () {
    const converter = FlexibleDoubleConverter();

    test('parses decimal strings with comma and dot', () {
      expect(converter.fromJson('1,5'), 1.5);
      expect(converter.fromJson('1.5'), 1.5);
    });

    test('parses numeric values', () {
      expect(converter.fromJson(1.5), 1.5);
      expect(converter.fromJson(1), 1.0);
    });

    test('throws FormatException for invalid values', () {
      expect(() => converter.fromJson('abc'), throwsA(isA<FormatException>()));
    });
  });

  group('FlexibleDateTimeConverter', () {
    const converter = FlexibleDateTimeConverter();

    test('parses unix timestamp in milliseconds', () {
      const milliseconds = 1_771_980_800_000;
      final expected = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      expect(converter.fromJson(milliseconds), expected);
    });

    test('parses ISO date strings', () {
      final parsed = converter.fromJson('2026-02-25T12:00:00.000');
      expect(parsed, DateTime(2026, 2, 25, 12));
    });

    test('returns native DateTime values', () {
      final value = DateTime(2026, 2, 25, 12, 30);
      expect(converter.fromJson(value), value);
    });
  });
}
