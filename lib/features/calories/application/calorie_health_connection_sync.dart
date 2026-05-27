import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'health_connection_controller.dart';

part 'calorie_health_connection_sync.g.dart';

const _logName = 'CalorieHealthConnectionSync';
const _activityTrackingBackfillDayCount = 30;

/// Keeps calorie settings in sync with Health connection state.
@riverpod
void calorieHealthConnectionSync(Ref ref) {
  var isSyncing = false;

  Future<void> syncIfReady() async {
    if (isSyncing || !ref.mounted) {
      return;
    }
    final status = ref.read(healthConnectionControllerProvider).asData?.value;
    final settings = ref.read(calorieGoalControllerProvider).asData?.value;
    if (status?.accessState != HealthDataAccessState.ready ||
        settings == null) {
      return;
    }

    final startedAt = _activityTrackingStartDate(settings, DateTime.now());
    isSyncing = true;
    final controller = ref.read(calorieGoalControllerProvider.notifier);
    try {
      final saved = await controller.markActivityTrackingStarted(
        startedAt: startedAt,
      );
      if (!saved) {
        log('Failed to persist activity tracking start.', name: _logName);
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to sync Health connection state.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isSyncing = false;
    }
  }

  void scheduleSync() {
    unawaited(syncIfReady());
  }

  ref
    ..listen(
      healthConnectionControllerProvider,
      (_, _) => scheduleSync(),
      fireImmediately: true,
    )
    ..listen(
      calorieGoalControllerProvider,
      (_, _) => scheduleSync(),
      fireImmediately: true,
    );
}

DateTime _activityTrackingStartDate(
  CalorieGoalSettings settings,
  DateTime now,
) {
  final today = normalizeDiaryDay(now);
  final anchorEntry = settings.cycleAnchorEntryForDay(today);
  final rollingStartDate = addDiaryDays(
    today,
    -(_activityTrackingBackfillDayCount - 1),
  );
  final goalStartDate = anchorEntry?.effectiveCountingStartDate;
  if (goalStartDate == null) {
    return rollingStartDate;
  }
  final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
  if (normalizedGoalStartDate.isAfter(rollingStartDate)) {
    return normalizedGoalStartDate;
  }
  return rollingStartDate;
}
