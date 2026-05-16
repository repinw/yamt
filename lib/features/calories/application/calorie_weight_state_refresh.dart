import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';

part 'calorie_weight_state_refresh.g.dart';

const _logName = 'CalorieWeightStateRefresh';

/// Refreshes calorie-owned state that depends on weight changes.
@riverpod
CalorieWeightStateRefresh calorieWeightStateRefresh(
  Ref ref,
) {
  return ({required DateTime day}) async {
    try {
      await ref
          .read(calorieGoalControllerProvider.notifier)
          .invalidateWeeklyCheckInSnapshotsFromDay(day);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to dirty weekly check-in snapshots after weight change.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!ref.mounted) {
      return;
    }
    ref
      ..invalidate(calorieHealthTrendSnapshotProvider)
      ..invalidate(calorieWeeklyCheckInDataProvider);
  };
}

/// Refresh callback for calorie-owned weight dependents.
typedef CalorieWeightStateRefresh =
    Future<void> Function({
      required DateTime day,
    });
