import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_pace_spent.dart';

void main() {
  final day = DateTime(2026, 11, 12);

  group('diary pace spent codec', () {
    test('encodes the day and the minute of each meal', () {
      final text = encodeDiaryPaceSpent(DateTime(2026, 11, 12, 15, 40), {
        MealType.breakfast: DateTime(2026, 11, 12, 6),
        MealType.dinner: DateTime(2026, 11, 12, 16, 5),
      });

      expect(text, '2026-11-12|breakfast=360,dinner=965');
    });

    test('decodes what it encoded, minute exact', () {
      final spent = {
        MealType.breakfast: DateTime(2026, 11, 12, 6),
        MealType.lunch: DateTime(2026, 11, 12, 11, 7),
        MealType.snack: DateTime(2026, 11, 12, 20, 59),
      };

      expect(
        decodeDiaryPaceSpent(encodeDiaryPaceSpent(day, spent), day),
        spent,
      );
    });

    test('round trips an empty map', () {
      expect(decodeDiaryPaceSpent(encodeDiaryPaceSpent(day, {}), day), isEmpty);
    });

    test('is empty when nothing is stored', () {
      expect(decodeDiaryPaceSpent(null, day), isEmpty);
    });

    test('is empty for the record of another day', () {
      final text = encodeDiaryPaceSpent(DateTime(2026, 11, 11), {
        MealType.lunch: DateTime(2026, 11, 11, 11),
      });

      expect(decodeDiaryPaceSpent(text, day), isEmpty);
    });

    test('is empty for broken text', () {
      for (final broken in [
        '',
        'garbage',
        '2026-11-12',
        'not-a-day|lunch=100',
        '2026-11-12|lunch=100|extra',
      ]) {
        expect(decodeDiaryPaceSpent(broken, day), isEmpty, reason: broken);
      }
    });

    test('skips a broken pair and keeps the good ones', () {
      expect(decodeDiaryPaceSpent('2026-11-12|lunch=abc,dinner=100,x', day), {
        MealType.dinner: DateTime(2026, 11, 12, 1, 40),
      });
      expect(decodeDiaryPaceSpent('2026-11-12|unknown=100', day), isEmpty);
    });
  });
}
