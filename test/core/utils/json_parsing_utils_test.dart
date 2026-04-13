import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/json_parsing_utils.dart';

void main() {
  group('readJsonPositiveInt', () {
    test('clamps negative values and ignores strings and null', () {
      expect(readJsonPositiveInt(-2), 1);
      expect(readJsonPositiveInt(-2.8), 1);
      expect(readJsonPositiveInt('3'), isNull);
      expect(readJsonPositiveInt(null), isNull);
    });
  });

  group('readJsonNonNegativeInt', () {
    test('clamps negative values and ignores unsupported types', () {
      expect(readJsonNonNegativeInt(-2), 0);
      expect(readJsonNonNegativeInt(-2.8), 0);
      expect(readJsonNonNegativeInt('3'), isNull);
      expect(readJsonNonNegativeInt(null), isNull);
    });
  });

  group('readJsonDateTime', () {
    test('returns null for invalid, empty, and wrong-type values', () {
      expect(readJsonDateTime('not-a-date'), isNull);
      expect(readJsonDateTime('   '), isNull);
      expect(readJsonDateTime(42), isNull);
      expect(readJsonDateTime(null), isNull);
    });

    test('parses valid ISO strings', () {
      expect(
        readJsonDateTime(' 2026-04-13T10:00:00.000Z ')?.toIso8601String(),
        '2026-04-13T10:00:00.000Z',
      );
    });
  });

  group('readJsonMap', () {
    test('returns null for lists and primitives', () {
      expect(readJsonMap(<Object?>['a']), isNull);
      expect(readJsonMap('value'), isNull);
      expect(readJsonMap(3), isNull);
    });

    test('normalizes keys to strings', () {
      expect(
        readJsonMap(<Object?, Object?>{1: 'one', 'two': 2}),
        <String, dynamic>{'1': 'one', 'two': 2},
      );
    });
  });
}
