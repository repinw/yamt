import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_snapshot_rules.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

void main() {
  final start = DateTime(2026, 4, 8);
  final end = DateTime(2026, 4, 14);
  final due = DateTime(2026, 4, 15);
  final pending = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: start,
    windowEndDate: end,
    dueDate: due,
  );
  final goalOnly = const CalorieGoalSettings.empty().applyGoalChange(
    changedAt: start,
    dailyKcalGoal: 2400,
    calculatorProfile: null,
  );
  final decided = goalOnly.applyGoalChange(
    changedAt: due,
    dailyKcalGoal: 2580,
    calculatorProfile: null,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: start,
      windowEndDate: end,
      trendWeightChangePerDay: 0,
      calculatedTdeeKcal: 2580,
      lowConfidence: false,
    ),
  );

  group('pendingWeeklyCheckInNeedsSave', () {
    test('saves a new pending check-in', () {
      expect(
        pendingWeeklyCheckInNeedsSave(
          settings: goalOnly,
          pendingWeeklyCheckIn: pending,
        ),
        isTrue,
      );
    });

    test('skips the persisted pending check-in', () {
      expect(
        pendingWeeklyCheckInNeedsSave(
          settings: goalOnly.copyWithPendingWeeklyCheckIn(pending),
          pendingWeeklyCheckIn: pending,
        ),
        isFalse,
      );
    });

    test('never brings back a decided window', () {
      expect(
        pendingWeeklyCheckInNeedsSave(
          settings: decided,
          pendingWeeklyCheckIn: pending,
        ),
        isFalse,
      );
    });

    test('saves a decided window again once its inputs changed', () {
      expect(
        pendingWeeklyCheckInNeedsSave(
          settings: decided.invalidateWeeklyCheckInSnapshotsFromDay(
            day: DateTime(2026, 4, 10),
            invalidatedAt: due,
          ),
          pendingWeeklyCheckIn: pending,
        ),
        isTrue,
      );
    });
  });
}
