import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';

import '../support/diary_dashboard_test_support.dart';

final DateTime _today = DateTime(2026, 10, 8);
final DateTime _tomorrow = nextDiaryDay(_today);
const _targets = DiaryMacroTargets(carbs: 250, protein: 120, fat: 70);
const _delta = DiaryMacroTargets(carbs: 5, protein: 0, fat: 2);

DiaryDayDashboardSnapshot _snapshot(
  DateTime day, {
  bool isPreviousDayClosed = false,
}) => DiaryDayDashboardSnapshot(
  selectedDay: day,
  refreshedAt: _today,
  weekOverview: diaryWeekOverviewForTest(
    selectedDay: day,
    isPreviousDayClosed: isPreviousDayClosed,
  ),
  selectedDayEntries: [_entry('eaten', 100)],
  plannedEntries: [_entry('plan', 40)],
  runState: const BurnWeekRunState.initial(),
  goalKcal: 2000,
  macroTargets: _targets,
  carryoverMacroDelta: _delta,
);

void main() {
  test('a planned day counts its plans', () {
    final data = DiaryDayDashboardData.fromSnapshot(
      _snapshot(_tomorrow),
      today: _today,
    );

    expect(data.countsPlans, isTrue);
    expect(data.mealSections.first.totalKcal, 140);
    expect(data.nutritionBars.protein, 14);
  });

  test('a day whose day before is closed counts only eaten food', () {
    final data = DiaryDayDashboardData.fromSnapshot(
      _snapshot(_tomorrow, isPreviousDayClosed: true),
      today: _today,
    );

    expect(data.countsPlans, isFalse);
    expect(data.mealSections.first.totalKcal, 100);
    expect(data.nutritionBars.protein, 10);
  });

  test('a cached planned day counts no plans once it is today', () {
    final data = DiaryDayDashboardData.fromSnapshot(
      _snapshot(_tomorrow),
      today: _tomorrow,
    );

    expect(data.countsPlans, isFalse);
    expect(data.mealSections.first.totalKcal, 100);
  });

  test('keeps the cached day budget', () {
    final data = DiaryDayDashboardData.fromSnapshot(
      _snapshot(_today),
      today: _today,
    );

    expect(data.nutritionBars.goals, _targets);
    expect(data.carryoverMacroDelta, _delta);
  });
}

CalorieEntry _entry(String id, double kcal) => CalorieEntry(
  isQuickEntry: false,
  id: id,
  userId: 'user-1',
  name: id,
  mealType: MealType.breakfast,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: kcal,
  per100Protein: kcal / 10,
  per100Carbs: 0,
  per100Fat: 0,
  totalKcal: kcal,
  totalProtein: kcal / 10,
  totalCarbs: 0,
  totalFat: 0,
  loggedAt: _today,
  createdAt: _today,
  updatedAt: _today,
);
