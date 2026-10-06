import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_snapshot_invalidator.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';

part 'calorie_entry_day_change.g.dart';

/// Reports that a diary entry on a day changed through a write that the
/// calories feature did not make itself.
typedef CalorieEntryDayChange = Future<void> Function(DateTime day);

/// Refreshes the diary overview and marks the weekly check-ins from the
/// entry's day as stale. A failed check-in update is logged.
@riverpod
CalorieEntryDayChange calorieEntryDayChange(Ref ref) {
  final overviewRevision = ref.watch(calorieOverviewRevisionProvider.notifier);
  final settingsRepository = ref.watch(calorieSettingsRepositoryProvider);
  final clock = ref.watch(clockProvider);
  return (day) async {
    overviewRevision.markChanged();
    await invalidateCalorieWeeklyCheckInSnapshotsFromDay(
      day: day,
      settingsRepository: settingsRepository,
      now: clock(),
    );
  };
}
