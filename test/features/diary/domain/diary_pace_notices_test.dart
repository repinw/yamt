import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';

void main() {
  final day = DateTime(2026, 11, 12);

  DiaryPaceDay pace({
    double target = 1588,
    double eaten = 0,
    DiaryMealTimes times = DiaryMealTimes.standard,
    DiaryMealShares shares = DiaryMealShares.standard,
  }) => (
    day: day,
    targetKcal: target,
    eatenKcal: eaten,
    times: times,
    shares: shares,
    macro: null,
  );

  // The times of the phone check: the day starts at 19:00.
  const lateTimes = DiaryMealTimes(
    start: 19 * 60,
    ends: [19 * 60 + 55, 20 * 60 + 10, 20 * 60 + 30, 21 * 60],
  );

  group('diaryPaceNotices', () {
    test('plans lunch, dinner and snack late in the evening, no breakfast', () {
      expect(diaryPaceNotices(pace(times: lateTimes)), [
        (meal: MealType.lunch, at: DateTime(2026, 11, 12, 20), freeKcal: 556),
        (
          meal: MealType.dinner,
          at: DateTime(2026, 11, 12, 20, 10),
          freeKcal: 476,
        ),
        (
          meal: MealType.snack,
          at: DateTime(2026, 11, 12, 20, 30),
          freeKcal: 159,
        ),
      ]);
    });

    test('puts lunch at 10:09 with the standard times and nothing eaten', () {
      final notices = diaryPaceNotices(pace());

      expect(notices.first, (
        meal: MealType.lunch,
        at: DateTime(2026, 11, 12, 10, 9),
        freeKcal: 556,
      ));
    });

    test('a meal eaten ahead of its part has no notice', () {
      // 1000 eaten covers breakfast's 397 and a part of lunch: lunch needs
      // 1556 by its end, and the day is due 953 by then.
      final meals = diaryPaceNotices(pace(eaten: 1000))
          .map((notice) => notice.meal);

      expect(meals, isNot(contains(MealType.breakfast)));
      expect(meals, isNot(contains(MealType.lunch)));
    });

    test('comes at the start of a meal when the eaten kcal are far behind', () {
      final notices = diaryPaceNotices(pace(times: lateTimes));

      // Dinner needs 476 and nothing is due before 953: its time begins.
      expect(notices[1].at, DateTime(2026, 11, 12, 20, 10));
    });

    test('everything eaten leaves the night quiet', () {
      expect(diaryPaceNotices(pace(eaten: 1588)), isEmpty);
      expect(diaryPaceNotices(pace(eaten: 5000)), isEmpty);
    });

    test('a meal without a part gets no notice', () {
      // Lunch's part is the whole 60 % due by its end: nothing is ahead.
      final notices = diaryPaceNotices(
        pace(times: lateTimes, shares: const DiaryMealShares([0, 60, 30, 10])),
      );

      expect(notices.map((notice) => notice.meal), [
        MealType.dinner,
        MealType.snack,
      ]);
    });

    test('a meal whose time has no length gets no notice', () {
      const times = DiaryMealTimes(
        start: 6 * 60,
        ends: [6 * 60, 13 * 60, 19 * 60, 21 * 60],
      );

      expect(
        diaryPaceNotices(pace(times: times)).map((notice) => notice.meal),
        isNot(contains(MealType.breakfast)),
      );
    });

    test('a zero target has no notices', () {
      expect(diaryPaceNotices(pace(target: 0)), isEmpty);
    });

    test('notices are on the day of the pace', () {
      for (final notice in diaryPaceNotices(pace())) {
        expect(DateTime(notice.at.year, notice.at.month, notice.at.day), day);
      }
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
