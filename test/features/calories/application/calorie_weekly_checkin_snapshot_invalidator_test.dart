import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_snapshot_invalidator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_goal_weekly_check_in_snapshot.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('returns true without saving when no snapshots change', () async {
    final repository = FakeCalorieSettingsRepository();
    final day = DateTime.utc(2026, 3, 10);

    final result = await invalidateCalorieWeeklyCheckInSnapshotsFromDay(
      day: day,
      settingsRepository: repository,
      now: DateTime.utc(2026, 3, 11),
    );

    expect(result, isTrue);
  });

  test('invalidates snapshots covering the target day and saves', () async {
    final day = DateTime.utc(2026, 3, 10);
    final snapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: DateTime.utc(2026, 3, 8),
      windowEndDate: DateTime.utc(2026, 3, 14),
      trendWeightChangePerDay: 0,
      lowConfidence: false,
    );
    final entry = CalorieGoalHistoryEntry(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime.utc(2026, 3, 15),
      changedAt: DateTime.utc(2026, 3, 15),
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: snapshot,
    );
    final initialSettings = const CalorieGoalSettings.empty().copyWith(
      goalHistory: [entry],
    );
    final repository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );

    final result = await invalidateCalorieWeeklyCheckInSnapshotsFromDay(
      day: day,
      settingsRepository: repository,
      now: DateTime.utc(2026, 3, 16),
    );

    expect(result, isTrue);
    final updated = await repository.readSettings();
    final updatedSnapshot = updated.goalHistory.first.weeklyCheckInSnapshot;
    expect(updatedSnapshot?.isInputDirty, isTrue);
    expect(updatedSnapshot?.invalidatedAt, DateTime.utc(2026, 3, 16));
  });
}
