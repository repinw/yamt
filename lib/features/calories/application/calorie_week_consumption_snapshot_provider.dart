import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_log_loader.dart';
import 'package:yamt/features/calories/application/calorie_week_overview_models.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';

part 'calorie_week_consumption_snapshot_provider.g.dart';

/// Calorie week consumption snapshot.
@riverpod
Future<CalorieWeekConsumptionSnapshot> calorieWeekConsumptionSnapshot(
  Ref ref,
) async {
  final visibleWindowEnd = ref.watch(calorieVisibleWindowControllerProvider);
  return await ref.watch(
    calorieWeekConsumptionSnapshotForWindowProvider(visibleWindowEnd).future,
  );
}

/// Calorie week consumption snapshot for window.
@riverpod
Future<CalorieWeekConsumptionSnapshot> calorieWeekConsumptionSnapshotForWindow(
  Ref ref,
  DateTime visibleWindowEnd,
) async {
  // Trigger recompute when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final days = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);
  final entriesByDay = await readVisibleEntriesByDaySafely(
    repository: repository,
    days: days,
  );

  final snapshots = <CalorieWeekConsumptionDaySnapshot>[];
  var totalConsumedKcal = 0.0;
  for (var index = 0; index < days.length; index += 1) {
    final day = days[index];
    final entries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalConsumedKcal += totalKcal;
    snapshots.add(
      CalorieWeekConsumptionDaySnapshot(
        date: day,
        totalKcal: totalKcal,
        entryCount: entries.length,
      ),
    );
  }

  return CalorieWeekConsumptionSnapshot(
    days: List<CalorieWeekConsumptionDaySnapshot>.unmodifiable(snapshots),
    totalConsumedKcal: totalConsumedKcal,
  );
}
