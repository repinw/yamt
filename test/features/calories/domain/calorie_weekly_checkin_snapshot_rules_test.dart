import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
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

  group('decideWeeklyCheckIn', () {
    final snapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: start,
      windowEndDate: end,
      trendWeightChangePerDay: 0,
      calculatedTdeeKcal: 2580,
      baseGoalKcal: 2580,
      lowConfidence: false,
    );
    final open = goalOnly.copyWithPendingWeeklyCheckIn(pending);

    CalorieGoalSettings? decide(
      CalorieGoalSettings settings, {
      required bool accept,
      CalorieRunTrainingChoice? training,
    }) => decideWeeklyCheckIn(
      settings: settings,
      pending: pending,
      snapshot: snapshot,
      accept: accept,
      today: due,
      training: training,
    );

    test('accepting applies the new goal and clears the check-in', () {
      final next = decide(open, accept: true)!;

      expect(next.sortedGoalHistory.last.dailyKcalGoal, 2580);
      expect(next.pendingWeeklyCheckIn, isNull);
    });

    test('accepting a goal the history already holds adds no entry', () {
      final settings = decided.copyWithPendingWeeklyCheckIn(pending);
      final next = decideWeeklyCheckIn(
        settings: settings,
        pending: pending,
        snapshot: decided.sortedGoalHistory.last.weeklyCheckInSnapshot!,
        accept: true,
        today: due,
      )!;

      expect(next.goalHistory, hasLength(settings.goalHistory.length));
      expect(next.pendingWeeklyCheckIn, isNull);
    });

    test('rejecting keeps the goal from before the window', () {
      final next = decide(open, accept: false)!;

      final latest = next.sortedGoalHistory.last;
      expect(latest.dailyKcalGoal, 2400);
      expect(latest.weeklyCheckInSnapshot?.isRejected, isTrue);
      expect(next.pendingWeeklyCheckIn, isNull);
    });

    test('the training days of the next run come with the decision', () {
      final next = decide(
        open,
        accept: false,
        training: (runDay: due, trainingDays: {DateTime(2026, 4, 16)}),
      )!;

      expect(next.isTrainingDay(DateTime(2026, 4, 16)), isTrue);
      expect(
        next.sortedGoalHistory.last.weeklyCheckInSnapshot?.isRejected,
        isTrue,
      );
    });

    test('a run that has ended decides nothing', () {
      expect(
        decide(
          open,
          accept: true,
          training: (runDay: start, trainingDays: {start}),
        ),
        isNull,
      );
    });
  });
}
