import 'dart:developer' show log;

import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';

const _snapshotInvalidatorLogName = 'CalorieWeeklyCheckInSnapshotInvalidator';

/// Invalidates weekly check-in snapshots from the provided diary day.
Future<bool> invalidateCalorieWeeklyCheckInSnapshotsFromDay({
  required DateTime day,
  required CalorieSettingsRepository settingsRepository,
  DateTime? now,
}) async {
  try {
    final previous = await settingsRepository.readSettings();
    final nextSettings = previous.invalidateWeeklyCheckInSnapshotsFromDay(
      day: day,
      invalidatedAt: now ?? DateTime.now(),
    );
    if (identical(previous, nextSettings)) {
      return true;
    }
    return await settingsRepository.saveSettings(nextSettings);
  } on Object catch (error, stackTrace) {
    log(
      'Failed to invalidate weekly check-in snapshots.',
      name: _snapshotInvalidatorLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}
