import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/data_export/application/data_export_report_provider.dart';
import 'package:yamt/features/data_export/domain/data_export_range.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<DataExportReport> _report(
  DataExportRange range, {
  List<CalorieEntry>? entries,
  String? mealShares,
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressTwoGoalSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository(
    initialEntries: entries ?? progressEntries(),
  );
  addTearDown(calorieLog.dispose);
  final container = ProviderContainer(
    overrides: [
      ...progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
      ),
    ],
  );
  addTearDown(container.dispose);
  if (mealShares != null) {
    await container
        .read(appPreferencesProvider)
        .setString(DiaryMealShares.preferenceKey, mealShares);
  }
  final subscription = container.listen(
    dataExportReportProvider(range),
    (_, _) {},
  );
  addTearDown(subscription.close);
  return await container.read(dataExportReportProvider(range).future);
}

void main() {
  test('the last 7 days hold one row per day up to today', () async {
    final report = await _report(const DataExportLastDaysRange(7));

    expect(report.from, DateTime(2026, 9, 18));
    expect(report.to, DateTime(2026, 9, 24));
    expect(report.days.map((day) => day.day), [
      for (var day = 18; day <= 24; day++) DateTime(2026, 9, day),
    ]);
    expect(report.entryCount, 7);
  });

  test('a day holds its entries grouped by meal in section order', () async {
    final entries = [
      CalorieEntry.placeholder(
        id: 'snack',
        name: 'Snack',
        mealType: MealType.snack,
        totalKcal: 100,
        loggedAt: DateTime(2026, 9, 24, 16),
      ),
      CalorieEntry.placeholder(
        id: 'lunch-a',
        name: 'Soup',
        mealType: MealType.lunch,
        totalKcal: 300,
        loggedAt: DateTime(2026, 9, 24, 12),
      ),
      CalorieEntry.placeholder(
        id: 'breakfast',
        name: 'Oats',
        mealType: MealType.breakfast,
        totalKcal: 400,
        loggedAt: DateTime(2026, 9, 24, 8),
      ),
      CalorieEntry.placeholder(
        id: 'lunch-b',
        name: 'Bread',
        mealType: MealType.lunch,
        totalKcal: 200,
        loggedAt: DateTime(2026, 9, 24, 13),
      ),
    ];

    final report = await _report(
      const DataExportLastDaysRange(1),
      entries: entries,
    );

    final day = report.days.single;
    expect(day.meals.map((meal) => meal.mealType), [
      MealType.breakfast,
      MealType.lunch,
      MealType.snack,
    ]);
    expect(
      day.meals[1].foods.map((food) => food.id),
      unorderedEquals(['lunch-a', 'lunch-b']),
    );
    expect(day.meals[1].kcal, 500);
    expect(day.kcal, 1000);
  });

  test('a day without entries has no meals', () async {
    final report = await _report(
      const DataExportLastDaysRange(1),
      entries: const [],
    );

    expect(report.days.single.meals, isEmpty);
    expect(report.loggedDays, isEmpty);
  });

  test('weights land on their days; others stay empty', () async {
    final report = await _report(const DataExportLastDaysRange(7));

    DataExportDay dayOf(int day) =>
        report.days.firstWhere((row) => row.day == DateTime(2026, 9, day));
    // Weigh-ins every second day from 24 September downward.
    expect(dayOf(24).weightKg, closeTo(82, 0.001));
    expect(dayOf(22).weightKg, closeTo(82.1, 0.001));
    expect(dayOf(20).weightKg, closeTo(82.2, 0.001));
    expect(dayOf(18).weightKg, closeTo(82.3, 0.001));
    expect(dayOf(23).weightKg, isNull);
    expect(dayOf(19).weightKg, isNull);
    expect(report.weighingCount, 4);
    // The trend has a value on every day after the first weighing.
    expect(dayOf(24).trendWeightKg, isNotNull);
  });

  test('the goal of the days gives their day type and goal kcal', () async {
    final report = await _report(const DataExportLastDaysRange(7));

    DataExportDay dayOf(int day) =>
        report.days.firstWhere((row) => row.day == DateTime(2026, 9, day));
    // Training days of the example goal: Monday and Wednesday.
    expect(dayOf(21).dayType, DiaryDayType.training);
    expect(dayOf(23).dayType, DiaryDayType.training);
    expect(dayOf(22).dayType, DiaryDayType.normal);
    expect(report.days.every((day) => day.hasGoal), isTrue);
    expect(report.days.every((day) => day.proteinGoalGrams > 0), isTrue);
  });

  test('days before the first goal are cut from a custom range', () async {
    final report = await _report(
      DataExportCustomRange(
        from: DateTime(2026, 8, 20),
        to: DateTime(2026, 9, 5),
      ),
    );

    expect(report.from, DateTime(2026, 9));
    expect(report.to, DateTime(2026, 9, 5));
    expect(report.days, hasLength(5));
  });

  test('last days reaching before the first goal start at the goal', () async {
    final report = await _report(const DataExportLastDaysRange(91));

    expect(report.from, DateTime(2026, 9));
    expect(report.to, DateTime(2026, 9, 24));
    expect(report.days, hasLength(24));
  });

  test('a range wholly before the first goal is kept without a goal', () async {
    final report = await _report(
      DataExportCustomRange(from: DateTime(2026, 8), to: DateTime(2026, 8, 3)),
    );

    expect(report.from, DateTime(2026, 8));
    expect(report.to, DateTime(2026, 8, 3));
    expect(report.days, hasLength(3));
    expect(report.days.any((day) => day.hasGoal), isFalse);
  });

  test('the current goal range holds the current goal only', () async {
    final report = await _report(const DataExportGoalRange(ProgressScope.goal));

    expect(report.from, DateTime(2026, 9, 10));
    expect(report.goals, hasLength(1));
    final goal = report.goals.single;
    expect(goal.number, 2);
    expect(goal.startDay, DateTime(2026, 9, 10));
    expect(goal.endDay, isNull);
    expect(goal.goalMode, CalorieGoalMode.lose);
    expect(goal.startWeightKg, isNotNull);
    expect(goal.targetWeightKg, 78);
    expect(goal.baseKcal, isNotNull);
  });

  test('the current goal range ends its last goal row open', () async {
    final report = await _report(const DataExportGoalRange(ProgressScope.goal));

    final goal = report.goals.last;
    expect(goal.number, 2);
    expect(goal.startDay, DateTime(2026, 9, 10));
    expect(goal.endDay, isNull);
    expect(goal.goalMode, CalorieGoalMode.lose);
    expect(goal.targetWeightKg, 78);
    expect(goal.baseKcal, isNotNull);
  });

  test('all data holds every goal, oldest first', () async {
    final report = await _report(const DataExportGoalRange(ProgressScope.all));

    expect(report.from, DateTime(2026, 9));
    expect(report.goals.map((goal) => goal.number), [1, 2]);
    expect(report.goals.first.endDay, DateTime(2026, 9, 9));
    expect(report.goals.last.endDay, isNull);
  });

  test('a past goal range holds that goal only', () async {
    final report = await _report(const DataExportGoalsRange(1, 1));

    expect(report.from, DateTime(2026, 9));
    expect(report.to, DateTime(2026, 9, 9));
    expect(report.goals.map((goal) => goal.number), [1]);
    expect(report.goals.single.targetWeightKg, 80);
  });

  test('the parts of the day are the standard ones by default', () async {
    final report = await _report(const DataExportLastDaysRange(7));

    expect(report.mealSharePercents, DiaryMealShares.standard.percents);
  });

  test('the parts of the day come from the saved preference', () async {
    final report = await _report(
      const DataExportLastDaysRange(7),
      mealShares: '40,30,20,10',
    );

    expect(report.mealSharePercents, [40, 30, 20, 10]);
  });

  test('a broken preference falls back to the standard parts', () async {
    final report = await _report(
      const DataExportLastDaysRange(7),
      mealShares: '40,30',
    );

    expect(report.mealSharePercents, DiaryMealShares.standard.percents);
  });
}
