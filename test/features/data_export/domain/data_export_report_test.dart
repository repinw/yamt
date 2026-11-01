import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  group('DataExportReport', () {
    final report = sampleReport();

    test('counts logged days, entries, and weighings', () {
      expect(report.loggedDays.map((day) => day.day), [
        DateTime(2026, 9, 20),
        DateTime(2026, 9, 21),
      ]);
      expect(report.entryCount, 3);
      expect(report.weighingCount, 1);
    });

    test('averageLogged averages over logged days only', () {
      // 400 kcal on day 1, 800 kcal on day 2; the pause day has no entry.
      expect(report.averageLogged((day) => day.kcal), 600);
      expect(report.averageLogged((day) => day.proteinGrams), 18);
    });

    test('averageLogged is null without a logged day', () {
      final empty = exportReport([exportDay(DateTime(2026, 9, 20))]);

      expect(empty.averageLogged((day) => day.kcal), isNull);
    });

    test('averageGoal skips pause days and days without a goal', () {
      final mixed = exportReport([
        exportDay(
          DateTime(2026, 9, 20),
          meals: [
            DataExportMeal(mealType: MealType.lunch, foods: [oatEntry()]),
          ],
        ),
        exportDay(
          DateTime(2026, 9, 21),
          type: DiaryDayType.pause,
          goalKcal: 2500,
          meals: [
            DataExportMeal(mealType: MealType.lunch, foods: [oatEntry()]),
          ],
        ),
        exportDay(
          DateTime(2026, 9, 22),
          goalKcal: 0,
          meals: [
            DataExportMeal(mealType: MealType.lunch, foods: [oatEntry()]),
          ],
        ),
        exportDay(
          DateTime(2026, 9, 23),
          goalKcal: 3000,
          meals: [
            DataExportMeal(mealType: MealType.lunch, foods: [oatEntry()]),
          ],
        ),
        exportDay(DateTime(2026, 9, 24), goalKcal: 9000),
      ]);

      expect(mixed.averageGoal((day) => day.goalKcal), 2500);
    });

    test('averageGoal is null when no logged day counts a goal', () {
      final noGoal = exportReport([
        exportDay(
          DateTime(2026, 9, 20),
          type: DiaryDayType.pause,
          meals: [
            DataExportMeal(mealType: MealType.lunch, foods: [oatEntry()]),
          ],
        ),
      ]);

      expect(noGoal.averageGoal((day) => day.goalKcal), isNull);
    });

    test('averageTdeeKcal averages the days that have one', () {
      expect(report.averageTdeeKcal, 2500);
      expect(
        exportReport([exportDay(DateTime(2026, 9, 20))]).averageTdeeKcal,
        isNull,
      );
    });

    test('averageTdeeDayValueKcal averages the days that have one', () {
      expect(report.averageTdeeDayValueKcal, 2650);
      expect(
        exportReport([exportDay(DateTime(2026, 9, 20), tdeeKcal: 2400)])
            .averageTdeeDayValueKcal,
        isNull,
      );
    });

    test('countOf counts the days of a type', () {
      expect(report.countOf(DiaryDayType.normal), 1);
      expect(report.countOf(DiaryDayType.training), 1);
      expect(report.countOf(DiaryDayType.pause), 1);
    });
  });

  group('DataExportDay', () {
    test('hasGoal is false on a pause day and without a goal', () {
      expect(exportDay(DateTime(2026, 9, 20)).hasGoal, isTrue);
      expect(
        exportDay(DateTime(2026, 9, 20), type: DiaryDayType.pause).hasGoal,
        isFalse,
      );
      expect(exportDay(DateTime(2026, 9, 20), goalKcal: 0).hasGoal, isFalse);
    });

    test('countedGoalKcal is null when the day has no goal', () {
      expect(exportDay(DateTime(2026, 9, 20)).countedGoalKcal, 2000);
      expect(
        exportDay(
          DateTime(2026, 9, 20),
          type: DiaryDayType.pause,
        ).countedGoalKcal,
        isNull,
      );
    });

    test('sums the meals', () {
      final day = sampleReport().days[1];

      expect(day.entryCount, 2);
      expect(day.kcal, 800);
      expect(day.proteinGrams, 24);
      expect(day.carbsGrams, 120);
      expect(day.fatGrams, 16);
    });
  });
}
