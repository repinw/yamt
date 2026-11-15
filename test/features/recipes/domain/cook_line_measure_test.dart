import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';

void main() {
  group('cookTextMeasure', () {
    test('splits a measure with a number from its food', () {
      expect(cookTextMeasure('1 Prise Salz'), (
        measure: '1 Prise',
        food: 'Salz',
      ));
      expect(
        cookTextMeasure('2 Zweige Rosmarin'),
        isNull,
        reason: 'Zweige is no measure word',
      );
    });

    test('splits a measure word without a number', () {
      expect(cookTextMeasure('etwas Öl'), (measure: 'etwas', food: 'Öl'));
    });

    test('splits a measure with an article', () {
      expect(cookTextMeasure('eine Handvoll Nüsse'), (
        measure: 'eine Handvoll',
        food: 'Nüsse',
      ));
    });

    test('is null when the text does not start with a measure', () {
      expect(cookTextMeasure('Butter zum Braten'), isNull);
      expect(cookTextMeasure('Salz'), isNull);
    });

    test('is null when nothing follows the measure', () {
      expect(cookTextMeasure('1 Prise'), isNull);
    });
  });

  group('cookTextStartsWithMeasure', () {
    test('is true for a number, a measure word and an article', () {
      expect(cookTextStartsWithMeasure('1 Prise Salz'), isTrue);
      expect(cookTextStartsWithMeasure('etwas Öl'), isTrue);
      expect(cookTextStartsWithMeasure('2 Zweige Rosmarin'), isTrue);
      expect(cookTextStartsWithMeasure('eine Handvoll Nüsse'), isTrue);
      expect(cookTextStartsWithMeasure('½ Zitrone'), isTrue);
    });

    test('is false for a food that starts the line', () {
      expect(cookTextStartsWithMeasure('Butter zum Braten'), isFalse);
      expect(cookTextStartsWithMeasure('Salz'), isFalse);
    });
  });
}
