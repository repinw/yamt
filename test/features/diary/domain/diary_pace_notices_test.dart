import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';

final _day = DateTime(2026, 11, 12);

DiaryPaceDay _pace({
  double target = 2000,
  double eaten = 0,
  DiaryMealTimes times = DiaryMealTimes.standard,
  DiaryMealShares shares = DiaryMealShares.standard,
}) => (
  day: _day,
  targetKcal: target,
  eatenKcal: eaten,
  times: times,
  shares: shares,
  macro: null,
);

DiaryPaceNotice _notice(MealType meal, int hour, int free) =>
    (meal: meal, at: DateTime(2026, 11, 12, hour), freeKcal: free);

void main() {
  group('diaryPaceNotices edge cases', () {
    test('a part of no length gets no notice, the next one starts at once', () {
      const times = DiaryMealTimes(
        start: 6 * 60,
        ends: [6 * 60, 16 * 60, 20 * 60, 21 * 60],
      );

      expect(diaryPaceNotices(_pace(times: times)), [
        _notice(MealType.lunch, 6, 1200),
        _notice(MealType.dinner, 16, 1800),
      ]);
    });

    test('a part at 0 % gets no notice and adds nothing to the next one', () {
      const shares = DiaryMealShares([25, 0, 60, 15]);

      expect(diaryPaceNotices(_pace(shares: shares)), [
        _notice(MealType.breakfast, 6, 500),
        _notice(MealType.dinner, 16, 1700),
      ]);
    });

    test(
      'a notice that rounds to 0 is dropped, one that rounds to 1 stays',
      () {
        // 25 % of 100 is 25: 24.6 eaten leaves 0.4, which rounds to 0.
        expect(
          diaryPaceNotices(_pace(target: 100, eaten: 24.6)).map((n) => n.meal),
          [MealType.lunch, MealType.dinner],
        );
        // 0.5 left rounds half up to 1.
        expect(
          diaryPaceNotices(_pace(target: 100, eaten: 24.5)).first,
          _notice(MealType.breakfast, 6, 1),
        );
      },
    );

    test('nothing is named once everything due is eaten', () {
      expect(diaryPaceNotices(_pace(eaten: 1800)), isEmpty);
      expect(diaryPaceNotices(_pace(eaten: 5000)), isEmpty);
      expect(diaryPaceNotices(_pace(target: 0)), isEmpty);
    });

    test('the snack never gets a notice', () {
      expect(
        diaryPaceNotices(_pace()).map((n) => n.meal),
        isNot(contains(MealType.snack)),
      );
    });

    test('a day that starts in the evening plans its notices that evening', () {
      const times = DiaryMealTimes(
        start: 20 * 60,
        ends: [21 * 60, 22 * 60, 23 * 60, 23 * 60 + 30],
      );

      expect(diaryPaceNotices(_pace(times: times)), [
        _notice(MealType.breakfast, 20, 500),
        _notice(MealType.lunch, 21, 1200),
        _notice(MealType.dinner, 22, 1800),
      ]);
    });
  });

  group('diaryPaceMacro', () {
    const targets = (protein: 100.0, carbs: 200.0, fat: 50.0);

    test('is the macro with the largest share of its target left', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 50, carbs: 190, fat: 40),
          targets: targets,
        ),
        DiaryPaceMacro.protein,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 90, carbs: 40, fat: 40),
          targets: targets,
        ),
        DiaryPaceMacro.carbs,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 90, carbs: 190, fat: 10),
          targets: targets,
        ),
        DiaryPaceMacro.fat,
      );
    });

    test('is null when no macro has anything left', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 100, carbs: 250, fat: 60),
          targets: targets,
        ),
        isNull,
      );
    });

    test('ignores a macro without a target', () {
      expect(
        diaryPaceMacro(
          eaten: (protein: 0, carbs: 0, fat: 0),
          targets: (protein: 0, carbs: 0, fat: 50),
        ),
        DiaryPaceMacro.fat,
      );
      expect(
        diaryPaceMacro(
          eaten: (protein: 0, carbs: 0, fat: 0),
          targets: (protein: 0, carbs: 0, fat: 0),
        ),
        isNull,
      );
    });
  });
}
