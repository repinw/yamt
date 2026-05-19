import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_weekly_balance_metrics.dart';

void main() {
  test('uses fallback weekly goal when visible current week is smaller', () {
    final selectedDay = DateTime(2026, 4, 28);
    final currentWeekStartDate = DateTime(2026, 4, 27);
    final weekOverview = _weekOverview(
      selectedDay: selectedDay,
      currentWeekStartDate: currentWeekStartDate,
      baseGoals: const <double>[1800, 1800],
      dayTotals: const <double>[1200, 600],
    );

    final metrics = resolveDiaryWeeklyBalanceMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: weekOverview.days.last,
      selectedDayEntries: const <CalorieEntry>[],
      currentWeekStartDate: currentWeekStartDate,
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
      now: selectedDay.add(const Duration(hours: 12)),
    );

    expect(metrics.goalKcal, 12600);
    expect(metrics.targetKcal, closeTo(2700, 0.001));
    expect(metrics.progressDay, 2);
    expect(metrics.totalDays, 7);
  });

  test('uses visible current-week base goals when they exceed fallback', () {
    final selectedDay = DateTime(2026, 5, 3);
    final currentWeekStartDate = DateTime(2026, 4, 27);
    final weekOverview = _weekOverview(
      selectedDay: selectedDay,
      currentWeekStartDate: currentWeekStartDate,
      baseGoals: const <double>[3000, 3000, 3000, 3000, 3000, 3000, 1200],
      dayTotals: const <double>[1800, 1800, 1800, 1800, 1800, 1800, 600],
    );

    final metrics = resolveDiaryWeeklyBalanceMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: weekOverview.days.last,
      selectedDayEntries: const <CalorieEntry>[],
      currentWeekStartDate: currentWeekStartDate,
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
      now: selectedDay.add(const Duration(hours: 12)),
    );

    expect(metrics.goalKcal, 19200);
    expect(metrics.targetKcal, closeTo(17828.571, 0.001));
    expect(metrics.progressDay, 7);
  });

  test(
    'keeps actual weekly kcal real while applying heart credit to pacing',
    () {
      final selectedDay = DateTime(2026, 4, 28);
      final currentWeekStartDate = DateTime(2026, 4, 27);
      final weekOverview = _weekOverview(
        selectedDay: selectedDay,
        currentWeekStartDate: currentWeekStartDate,
        baseGoals: const <double>[2000, 2000],
        dayTotals: const <double>[1200, 600],
      );

      final metrics = resolveDiaryWeeklyBalanceMetrics(
        weekOverview: weekOverview,
        selectedDayOverview: weekOverview.days.last,
        selectedDayEntries: const <CalorieEntry>[],
        currentWeekStartDate: currentWeekStartDate,
        runState: const BurnWeekRunState.initial().copyWith(
          currentWeekStartDayKey: '2026-4-27',
          heartCreditKcal: 250,
        ),
        now: selectedDay.add(const Duration(hours: 12)),
      );

      expect(metrics.goalKcal, 14000);
      expect(metrics.pacing.actualConsumedKcal, 1800);
      expect(metrics.pacing.consumedKcal, 2050);
    },
  );

  test('expands display goal when selected day still has kcal left', () {
    final selectedDay = DateTime(2026, 5, 3);
    final currentWeekStartDate = DateTime(2026, 4, 27);
    final weekOverview = _weekOverview(
      selectedDay: selectedDay,
      currentWeekStartDate: currentWeekStartDate,
      baseGoals: const <double>[2500, 2500, 2500, 2500, 2500, 2500, 2500],
      dayTotals: const <double>[2600, 2600, 2600, 2600, 2600, 2600, 2000],
      todayFlexibleGoalKcal: 2300,
    );

    final metrics = resolveDiaryWeeklyBalanceMetrics(
      weekOverview: weekOverview,
      selectedDayOverview: weekOverview.days.last,
      selectedDayEntries: const <CalorieEntry>[],
      currentWeekStartDate: currentWeekStartDate,
      runState: const BurnWeekRunState.initial().copyWith(
        currentWeekStartDayKey: '2026-4-27',
      ),
      now: selectedDay.add(const Duration(hours: 12)),
    );

    expect(metrics.pacing.actualConsumedKcal, 17600);
    expect(metrics.goalKcal, 17900);
  });

  test('progress day clamps to the visible Burn Week range', () {
    final weekStartDate = DateTime(2026, 4, 27);

    expect(
      resolveDiaryWeeklyProgressDay(
        selectedDay: weekStartDate.subtract(const Duration(days: 3)),
        currentWeekStartDate: weekStartDate,
      ),
      1,
    );
    expect(
      resolveDiaryWeeklyProgressDay(
        selectedDay: weekStartDate.add(const Duration(days: 9)),
        currentWeekStartDate: weekStartDate,
      ),
      7,
    );
  });
}

CalorieWeekOverview _weekOverview({
  required DateTime selectedDay,
  required DateTime currentWeekStartDate,
  required List<double> baseGoals,
  required List<double> dayTotals,
  double? todayFlexibleGoalKcal,
}) {
  final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
  final days = [
    for (var offset = 6; offset >= 0; offset -= 1)
      _dayOverview(
        date: addDiaryDays(normalizedSelectedDay, -offset),
        currentWeekStartDate: currentWeekStartDate,
        baseGoals: baseGoals,
        dayTotals: dayTotals,
      ),
  ];
  final totalConsumedKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = days.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );
  return CalorieWeekOverview(
    days: days,
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate: currentWeekStartDate,
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal ?? days.last.goalKcal,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
    futureGoalKcal: null,
  );
}

CalorieWeekDayOverview _dayOverview({
  required DateTime date,
  required DateTime currentWeekStartDate,
  required List<double> baseGoals,
  required List<double> dayTotals,
}) {
  final currentWeekIndex = normalizeDiaryDay(
    date,
  ).difference(normalizeDiaryDay(currentWeekStartDate)).inDays;
  final isCurrentWeekDay =
      currentWeekIndex >= 0 && currentWeekIndex < baseGoals.length;
  final baseGoalKcal = isCurrentWeekDay ? baseGoals[currentWeekIndex] : 0.0;
  final totalKcal = isCurrentWeekDay ? dayTotals[currentWeekIndex] : 0.0;

  return CalorieWeekDayOverview(
    date: date,
    totalKcal: totalKcal,
    goalKcal: baseGoalKcal,
    baseGoalKcal: baseGoalKcal,
    entryCount: totalKcal > 0 ? 1 : 0,
  );
}
