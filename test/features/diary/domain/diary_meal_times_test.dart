import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';

/// Times from "hh:mm" texts: the day's start, then the end of each meal.
DiaryMealTimes _times(String start, List<String> ends) {
  int minute(String text) {
    final [hour, minutes] = text.split(':').map(int.parse).toList();
    return hour * 60 + minutes;
  }

  return DiaryMealTimes(start: minute(start), ends: [...ends.map(minute)]);
}

void main() {
  test('the standard day starts at 6:00 and ends its meals at 11, 16, 20 '
      "and 21 o'clock", () {
    expect(DiaryMealTimes.standard.start, 6 * 60);
    expect(DiaryMealTimes.standard.ends, [11 * 60, 16 * 60, 20 * 60, 21 * 60]);
    expect(DiaryMealTimes.standard.encode(), '360,660,960,1200,1260');
    expect(DiaryMealTimes.lastMinute, 1439);
  });

  test('endOf gives the end of each meal in section order', () {
    expect(
      [
        for (final meal in MealType.sectionOrder)
          DiaryMealTimes.standard.endOf(meal),
      ],
      [660, 960, 1200, 1260],
    );
  });

  group('decode', () {
    test('reads what encode wrote', () {
      expect(
        DiaryMealTimes.decode(DiaryMealTimes.standard.encode()),
        DiaryMealTimes.standard,
      );
      final late = _times('08:30', ['10:00', '14:15', '20:00', '23:59']);

      expect(late.encode(), '510,600,855,1200,1439');
      expect(DiaryMealTimes.decode(late.encode()), late);
    });

    test('takes the whole day and meals that end together', () {
      for (final value in [
        '0,0,0,0,0',
        '1439,1439,1439,1439,1439',
        '360,360,780,780,1260',
      ]) {
        expect(DiaryMealTimes.decode(value), isNotNull, reason: value);
        expect(DiaryMealTimes.decode(value)!.encode(), value);
      }
    });

    test('rejects a wrong count, no numbers, a time off the day, or times '
        'that run backwards', () {
      for (final value in [
        '',
        '360',
        '360,540,780,1140',
        '360,540,780,1140,1260,1300',
        '360,540,780,1140,x',
        '360,540,780,1140,12.5',
        '360,540,,1140,1260',
        '-1,540,780,1140,1260',
        '360,540,780,1140,1440',
        '1440,1440,1440,1440,1440',
        '360,540,780,1260,1140',
        '361,360,780,1140,1260',
      ]) {
        expect(DiaryMealTimes.decode(value), isNull, reason: value);
      }
    });
  });

  group('equality', () {
    test('times with the same start and ends are equal', () {
      final same = DiaryMealTimes(
        start: 360,
        ends: [...DiaryMealTimes.standard.ends],
      );

      expect(same, DiaryMealTimes.standard);
      expect(same.hashCode, DiaryMealTimes.standard.hashCode);
    });

    test('a different start or end is a different time', () {
      expect(
        DiaryMealTimes.standard.withStart(361),
        isNot(DiaryMealTimes.standard),
      );
      expect(
        DiaryMealTimes.standard.withEnd(MealType.snack, 1261),
        isNot(DiaryMealTimes.standard),
      );
    });
  });

  group('withEnd', () {
    test('moves one end and leaves the others when they stay in order', () {
      expect(
        DiaryMealTimes.standard.withEnd(MealType.lunch, 12 * 60).encode(),
        '360,660,720,1200,1260',
      );
    });

    test('an end moved before the one before takes it along', () {
      // Lunch by 8:00, before breakfast's 11:00.
      expect(
        DiaryMealTimes.standard.withEnd(MealType.lunch, 480).encode(),
        '360,480,480,1200,1260',
      );
    });

    test('an end moved past the next takes those along too', () {
      // Breakfast by 20:00 lifts lunch and dinner to it.
      expect(
        DiaryMealTimes.standard.withEnd(MealType.breakfast, 1200).encode(),
        '360,1200,1200,1200,1260',
      );
    });

    test('an end moved before the start takes the start along', () {
      expect(
        DiaryMealTimes.standard.withEnd(MealType.breakfast, 300).encode(),
        '300,300,960,1200,1260',
      );
      expect(
        DiaryMealTimes.standard.withEnd(MealType.snack, 0).encode(),
        '0,0,0,0,0',
      );
    });

    test('a time off the day stays on it', () {
      expect(
        DiaryMealTimes.standard.withEnd(MealType.snack, 5000).encode(),
        '360,660,960,1200,1439',
      );
      expect(
        DiaryMealTimes.standard.withEnd(MealType.dinner, 5000).encode(),
        '360,660,960,1439,1439',
      );
      expect(
        DiaryMealTimes.standard.withEnd(MealType.breakfast, -30).encode(),
        '0,0,960,1200,1260',
      );
    });

    test('keeps the times in order and the picked end where it was put, '
        'wherever it goes', () {
      for (final meal in MealType.sectionOrder) {
        for (var minute = 0; minute <= DiaryMealTimes.lastMinute; minute++) {
          final times = DiaryMealTimes.standard.withEnd(meal, minute);

          expect(times.endOf(meal), minute);
          expect(
            DiaryMealTimes.decode(times.encode()),
            times,
            reason: '$meal by $minute',
          );
        }
      }
    });

    test('does not change the times it was called on', () {
      DiaryMealTimes.standard.withEnd(MealType.lunch, 480);

      expect(DiaryMealTimes.standard.encode(), '360,660,960,1200,1260');
    });
  });

  group('withStart', () {
    test('moves the start alone when the meals stay after it', () {
      expect(
        DiaryMealTimes.standard.withStart(5 * 60).encode(),
        '300,660,960,1200,1260',
      );
    });

    test("a start moved past a meal's end takes the meal along", () {
      expect(
        DiaryMealTimes.standard.withStart(700).encode(),
        '700,700,960,1200,1260',
      );
      expect(
        DiaryMealTimes.standard.withStart(1300).encode(),
        '1300,1300,1300,1300,1300',
      );
    });

    test('a start off the day stays on it', () {
      expect(
        DiaryMealTimes.standard.withStart(-5).encode(),
        '0,660,960,1200,1260',
      );
      expect(
        DiaryMealTimes.standard.withStart(2000).encode(),
        '1439,1439,1439,1439,1439',
      );
    });
  });

  group('dueAt with the standard split', () {
    const shares = DiaryMealShares.standard;
    double due(int hour, [int minute = 0]) =>
        DiaryMealTimes.standard.dueAt(hour * 60 + minute, shares);

    test('nothing is due until the day starts', () {
      expect(due(0), 0);
      expect(due(5), 0);
      expect(due(5, 59), 0);
    });

    test('at the start of each part the share due by its end is due at once, '
        'and stays until the next part starts', () {
      expect(due(6), closeTo(0.25, 1e-9));
      expect(due(8, 30), closeTo(0.25, 1e-9));
      expect(due(10, 59), closeTo(0.25, 1e-9));
      expect(due(11), closeTo(0.6, 1e-9));
      expect(due(13, 30), closeTo(0.6, 1e-9));
      expect(due(16), closeTo(0.9, 1e-9));
      expect(due(19, 59), closeTo(0.9, 1e-9));
      expect(due(20), closeTo(1, 1e-9));
    });

    test('all of it is due after the last meal, to the end of the day', () {
      expect(due(21, 1), 1);
      expect(due(23), 1);
      expect(due(23, 59), 1);
    });

    test('never falls and stays between none and all, minute by minute', () {
      var before = 0.0;
      for (var minute = 0; minute <= DiaryMealTimes.lastMinute; minute++) {
        final value = DiaryMealTimes.standard.dueAt(minute, shares);

        expect(value, inInclusiveRange(before, 1), reason: 'at $minute');
        before = value;
      }
    });
  });

  group('dueAt', () {
    test('follows the shares the user set', () {
      const lunchHeavy = DiaryMealShares([10, 60, 20, 10]);

      expect(
        DiaryMealTimes.standard.dueAt(6 * 60, lunchHeavy),
        closeTo(0.1, 1e-9),
      );
      expect(
        DiaryMealTimes.standard.dueAt(11 * 60, lunchHeavy),
        closeTo(0.7, 1e-9),
      );
    });

    test('follows the times the user set', () {
      final early = _times('05:00', ['07:00', '11:00', '17:00', '19:00']);

      expect(early.dueAt(4 * 60 + 59, DiaryMealShares.standard), 0);
      expect(
        early.dueAt(5 * 60, DiaryMealShares.standard),
        closeTo(0.25, 1e-9),
      );
      expect(early.dueAt(7 * 60, DiaryMealShares.standard), closeTo(0.6, 1e-9));
      expect(early.dueAt(19 * 60, DiaryMealShares.standard), 1);
    });

    test('a meal at 0 % adds nothing, so the line stays flat through it', () {
      const lunchOff = DiaryMealShares([25, 0, 60, 15]);
      double due(int hour) =>
          DiaryMealTimes.standard.dueAt(hour * 60, lunchOff);

      expect(due(6), closeTo(0.25, 1e-9));
      expect(due(11), closeTo(0.25, 1e-9));
      expect(due(16), closeTo(0.85, 1e-9));
      expect(due(20), closeTo(1, 1e-9));
    });
  });
}
