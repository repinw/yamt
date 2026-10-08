import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/application/day_budget.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test(
    'resolve returns scheduled restart for live day with future run start',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final restartDate = addDiaryDays(selectedDay, 1);

      final data = await _resolveBalanceData(
        selectedDay: selectedDay,
        now: selectedDay.add(const Duration(hours: 12)),
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(restartDate),
        ),
        weekOverview: _weekOverview(selectedDay: selectedDay),
      );

      expect(data.scheduledRestartDate, restartDate);
      expect(data.practiceDay, isNull);
      expect(data.loadedMetrics, isNull);
    },
  );

  test('resolve returns practice day before future goal start', () async {
    final selectedDay = DateTime(2026, 4, 27);
    final startDate = addDiaryDays(selectedDay, 2);

    final data = await _resolveBalanceData(
      selectedDay: selectedDay,
      now: selectedDay.add(const Duration(hours: 12)),
      runState: const BurnWeekRunState.initial(),
      weekOverview: _weekOverview(
        selectedDay: selectedDay,
        goalStartsInFuture: true,
        nextGoalStartDate: startDate,
        futureGoalKcal: 2150,
      ),
    );

    expect(data.scheduledRestartDate, isNull);
    expect(data.practiceDay?.startDate, startDate);
    expect(data.practiceDay?.futureGoalKcal, 2150);
    expect(data.loadedMetrics, isNull);
  });

  test(
    'resolve returns loaded metrics when no pre-start state applies',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final data = await _resolveBalanceData(
        selectedDay: selectedDay,
        now: selectedDay.add(const Duration(hours: 12)),
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: diaryDayKey(selectedDay),
          runWeekNumber: 2,
        ),
        weekOverview: _weekOverview(
          selectedDay: selectedDay,
          dayTotals: const <double>[0, 0, 0, 0, 0, 0, 800],
        ),
        entries: <CalorieEntry>[
          _entry(
            id: 'breakfast',
            day: selectedDay,
            mealType: MealType.breakfast,
            totalKcal: 800,
          ),
        ],
      );

      expect(data.scheduledRestartDate, isNull);
      expect(data.practiceDay, isNull);
      expect(data.loadedMetrics?.selectedDay, selectedDay);
      expect(data.loadedMetrics?.daily.realEatenKcal, 800);
      expect(data.loadedMetrics?.state.runWeekNumber, 2);
    },
  );

  test('resolve starts a fresh run week when the stored one expired', () async {
    final selectedDay = DateTime(2026, 4, 15);
    final expiredWeekStart = DateTime(2026, 4, 8);
    final data = await _resolveBalanceData(
      selectedDay: selectedDay,
      now: selectedDay.add(const Duration(hours: 12)),
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: diaryDayKey(expiredWeekStart),
        runWeekNumber: 2,
      ),
      weekOverview: _weekOverview(
        selectedDay: selectedDay,
        balanceStartDate: expiredWeekStart,
        dayTotals: const <double>[2500, 2600, 2550, 2700, 2600, 2830, 0],
        goalKcal: 2600,
      ),
    );

    // The expired week start would explain the carryover with the seven
    // days before; the fresh week starts on the selected day.
    final details = data.loadedMetrics?.budgetDetails;
    expect(details, isNotNull);
    expect(details!.previousDays, isEmpty);
  });
}

Future<DiaryBalanceCardData> _resolveBalanceData({
  required DateTime selectedDay,
  required DateTime now,
  required BurnWeekRunState runState,
  required CalorieWeekOverview weekOverview,
  List<CalorieEntry> entries = const <CalorieEntry>[],
}) async {
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    ],
  );
  addTearDown(container.dispose);
  final budget = resolveDayBudget(
    week: weekOverview,
    today: normalizeDiaryDay(now),
    nutrition: container.read(dailyNutritionTargetResolverProvider),
  );
  final delta = budget.carryoverMacroDelta;
  return DiaryBalanceSource.fromDashboardData(
    DiaryDayDashboardData(
      selectedDay: normalizeDiaryDay(selectedDay),
      refreshedAt: now,
      weekOverview: weekOverview,
      selectedDayEntries: entries,
      plannedEntries: const <CalorieEntry>[],
      countsPlans: false,
      runState: runState,
      mealSections: buildDiaryDashboardMealSections(
        entries,
        plannedEntries: const <CalorieEntry>[],
        countsPlans: false,
      ),
      nutritionBars: buildDiaryDashboardNutritionBars(
        entries,
        budget.goalKcal,
        macroTargets: DiaryMacroTargets(
          carbs: budget.target.carbsGrams,
          protein: budget.target.proteinGrams,
          fat: budget.target.fatGrams,
        ),
      ),
      carryoverMacroDelta: DiaryMacroTargets(
        carbs: delta.carbs,
        protein: delta.protein,
        fat: delta.fat,
      ),
    ),
  ).resolve(now: now);
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  List<double> dayTotals = const <double>[0, 0, 0, 0, 0, 0, 0],
  double goalKcal = 2000,
  DateTime? balanceStartDate,
  bool goalStartsInFuture = false,
  DateTime? nextGoalStartDate,
  double? futureGoalKcal,
}) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: addDiaryDays(normalizedSelectedDay, -offset),
        totalKcal: dayTotals[6 - offset],
        goalKcal: goalKcal,
        entryCount: dayTotals[6 - offset] > 0 ? 1 : 0,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(0, (sum, day) => sum + day.goalKcal);
  return CalorieWeekOverview(
    isPreviousDayClosed: false,
    days: days,
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate:
        balanceStartDate ?? addDiaryDays(normalizedSelectedDay, -6),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: goalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: futureGoalKcal,
  );
}

CalorieEntry _entry({
  required String id,
  required DateTime day,
  required MealType mealType,
  required double totalKcal,
}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    isQuickEntry: false,
    id: id,
    userId: 'user-1',
    name: id,
    mealType: mealType,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 0,
    per100Carbs: 0,
    per100Fat: 0,
    totalKcal: totalKcal,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
