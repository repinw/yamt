import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

void main() {
  test('resolves check-in window dates across month boundary', () {
    final start = DateTime(2026, 2, 27);
    final end = DateTime(2026, 3, 5);
    final pending = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: start,
      windowEndDate: end,
      dueDate: DateTime(2026, 3, 6),
    );

    final dates = resolveCalorieWeeklyCheckInWindowDates(
      settings: _settings(start),
      pendingWeeklyCheckIn: pending,
    );

    expect(dates.windowDays, [
      DateTime(2026, 2, 27),
      DateTime(2026, 2, 28),
      DateTime(2026, 3),
      DateTime(2026, 3, 2),
      DateTime(2026, 3, 3),
      DateTime(2026, 3, 4),
      DateTime(2026, 3, 5),
    ]);
    expect(dates.learningStartDate, start);
    expect(dates.nextBoundaryDay, DateTime(2026, 3, 6));
    expect(dates.isFirstWindow, isTrue);
  });

  test('resolves latest completed and pending windows on due day', () {
    final start = DateTime(2026, 2, 27);
    final today = DateTime(2026, 3, 6);
    final settings = _settings(start);

    final latest = resolveLatestCompletedCalorieWeeklyCheckIn(
      settings: settings,
      today: today,
    );
    final pending = resolvePendingCalorieWeeklyCheckIn(
      settings: settings,
      today: today,
    );

    expect(latest?.windowStartDate, start);
    expect(latest?.windowEndDate, DateTime(2026, 3, 5));
    expect(pending?.windowStartDate, start);
    expect(pending?.dueDate, today);
  });

  test('does not surface pending window after trusted snapshot exists', () {
    final start = DateTime(2026, 2, 27);
    final today = DateTime(2026, 3, 6);
    final settings = _settings(start).applyGoalChange(
      dailyKcalGoal: 2050,
      calculatorProfile: null,
      changedAt: today,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: start,
        windowEndDate: DateTime(2026, 3, 5),
        trendWeightChangePerDay: 0,
        calculatedBaseTdeeKcal: 2050,
        baseGoalKcal: 2050,
        lowConfidence: false,
        inputHash: 'v2:abc',
      ),
    );

    final pending = resolvePendingCalorieWeeklyCheckIn(
      settings: settings,
      today: today,
    );

    expect(pending, isNull);
  });

  test('builds inclusive days across month boundary', () {
    expect(
      buildCalorieWeeklyInclusiveDays(
        startDate: DateTime(2026, 2, 27, 13),
        endDate: DateTime(2026, 3, 1, 22),
      ),
      [DateTime(2026, 2, 27), DateTime(2026, 2, 28), DateTime(2026, 3)],
    );
  });
}

CalorieGoalSettings _settings(DateTime start) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: null,
    effectiveDate: start,
    countingStartDate: start,
  );
}
