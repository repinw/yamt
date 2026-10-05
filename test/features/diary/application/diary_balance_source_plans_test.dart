import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';

import '../support/diary_dashboard_test_support.dart';

void main() {
  final now = DateTime(2026, 10, 5, 12);
  final tomorrow = DateTime(2026, 10, 6);

  double eatenOnTomorrow({required bool countsPlans}) {
    final plan = buildQuickCalorieEntry(
      id: 'plan',
      userId: 'user-1',
      name: 'Pasta',
      mealType: MealType.dinner,
      loggedAt: tomorrow.add(const Duration(hours: 19)),
      now: now,
      kcal: 700,
    );
    final data = diaryDashboardLoadedStateForTest(
      selectedDay: tomorrow,
      weekOverview: diaryWeekOverviewForTest(
        selectedDay: tomorrow,
        dayTotals: const [0, 0, 0, 0, 0, 0, 200],
      ),
      plannedEntries: [plan],
      countsPlans: countsPlans,
    ).data!;
    return DiaryBalanceSource.fromDashboardData(data)
        .resolve(now: now)
        .loadedMetrics!
        .daily
        .realEatenKcal;
  }

  test('the head adds the plans when they count', () {
    expect(eatenOnTomorrow(countsPlans: true), 900);
  });

  test('the head shows only eaten food when plans do not count', () {
    expect(eatenOnTomorrow(countsPlans: false), 200);
  });
}
