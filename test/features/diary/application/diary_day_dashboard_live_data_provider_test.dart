import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/'
    'diary_day_dashboard_live_data_provider.dart';

import '../../calories/support/fake_calories_repositories.dart';

void main() {
  test('combines week overview, run state, and selected day entries', () async {
    final selectedDay = DateTime(2026, 4, 27, 18);
    final normalizedDay = normalizeDiaryDay(selectedDay);
    final weekOverview = _weekOverview(selectedDay: normalizedDay);
    final entries = <CalorieEntry>[
      _entry(id: 'breakfast', day: normalizedDay),
    ];
    final runState = const BurnWeekRunState.initial().copyWith(
      currentWeekStartDayKey: diaryDayKey(normalizedDay),
      runWeekNumber: 3,
    );
    DateTime? readDay;
    final repository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (day) async {
        readDay = day;
        return entries;
      };
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieWeekOverviewForWindowProvider(
          normalizedDay,
        ).overrideWith((ref) => weekOverview),
        burnWeekRunControllerProvider.overrideWith(
          () => _FakeBurnWeekRunController(runState),
        ),
      ],
    );
    addTearDown(repository.dispose);
    addTearDown(container.dispose);

    final data = await container.read(
      diaryDayDashboardLiveDataProvider(selectedDay).future,
    );

    expect(readDay, normalizedDay);
    expect(data.weekOverview, same(weekOverview));
    expect(data.runState, same(runState));
    expect(data.selectedDayEntries, same(entries));
    expect(data.selectedDayOverview, same(weekOverview.days.last));
  });
}

class _FakeBurnWeekRunController extends BurnWeekRunController {
  _FakeBurnWeekRunController(this.runState);

  final BurnWeekRunState runState;

  @override
  Future<BurnWeekRunState> build() async {
    return runState;
  }
}

CalorieWeekOverview _weekOverview({required DateTime selectedDay}) {
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      CalorieWeekDayOverview(
        date: addDiaryDays(selectedDay, -offset),
        totalKcal: (100 + offset).toDouble(),
        goalKcal: 2200,
        entryCount: offset == 0 ? 1 : 0,
      ),
  ];
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: days.fold<double>(
      0,
      (sum, day) => sum + day.totalKcal,
    ),
    totalGoalKcal: days.fold<double>(0, (sum, day) => sum + day.goalKcal),
    remainingKcal: 14700,
    balanceStartDate: days.first.date,
    carryoverBeforeTodayKcal: 50,
    todayFlexibleGoalKcal: 2250,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
    futureGoalKcal: null,
  );
}

CalorieEntry _entry({required String id, required DateTime day}) {
  final loggedAt = day.add(const Duration(hours: 8));
  return CalorieEntry(
    id: id,
    userId: 'user-1',
    name: id,
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 120,
    per100Protein: 6,
    per100Carbs: 18,
    per100Fat: 3,
    totalKcal: 120,
    totalProtein: 6,
    totalCarbs: 18,
    totalFat: 3,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}
