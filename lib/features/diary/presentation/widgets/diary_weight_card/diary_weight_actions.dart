import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/provider/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/manual_health_weight_entries_controller.dart';

/// Weight actions used by diary weight widgets.
final diaryWeightActionsProvider = Provider<DiaryWeightActions>((ref) {
  return DiaryWeightActions(
    saveManualWeight: ({required day, required weightKg}) => ref
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: day, weightKg: weightKg),
    deleteManualWeight: (day) => ref
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .deleteEntryForDay(day),
    deleteHealthWeightSample: (sample) =>
        ref.read(healthWeightServiceProvider).deleteWeightSample(sample),
    refreshDependents: ({required selectedDay, day}) {
      ref
        ..invalidate(diaryActivityWeightDataProvider(selectedDay))
        ..invalidate(calorieHealthTrendSnapshotProvider)
        ..invalidate(calorieWeeklyCheckInViewModelProvider);
      if (day != null && !isSameDiaryDay(day, selectedDay)) {
        ref.invalidate(diaryActivityWeightDataProvider(day));
      }
    },
  );
});

/// Save/delete behavior for diary weight entries.
class DiaryWeightActions {
  /// Creates diary weight actions.
  const DiaryWeightActions({
    required Future<bool> Function({
      required DateTime day,
      required double weightKg,
    })
    saveManualWeight,
    required Future<bool> Function(DateTime day) deleteManualWeight,
    required Future<bool> Function(HealthWeightSample sample)
    deleteHealthWeightSample,
    required void Function({
      required DateTime selectedDay,
      DateTime? day,
    })
    refreshDependents,
  }) : _saveManualWeight = saveManualWeight,
       _deleteManualWeight = deleteManualWeight,
       _deleteHealthWeightSample = deleteHealthWeightSample,
       _refreshDependents = refreshDependents;

  final Future<bool> Function({
    required DateTime day,
    required double weightKg,
  })
  _saveManualWeight;
  final Future<bool> Function(DateTime day) _deleteManualWeight;
  final Future<bool> Function(HealthWeightSample sample)
  _deleteHealthWeightSample;
  final void Function({required DateTime selectedDay, DateTime? day})
  _refreshDependents;

  /// Saves a manual weight and refreshes dependent diary providers.
  Future<bool> saveManualWeight({
    required DateTime selectedDay,
    required DateTime day,
    required double weightKg,
  }) async {
    final saved = await _saveManualWeight(day: day, weightKg: weightKg);
    if (saved) {
      _refreshDependents(selectedDay: selectedDay, day: day);
    }
    return saved;
  }

  /// Deletes the active weight source and refreshes dependent providers.
  Future<bool> deleteWeight({
    required DateTime selectedDay,
    required DateTime day,
    required bool hasManualWeight,
    required HealthWeightSample? healthSample,
  }) async {
    final deleted = hasManualWeight
        ? await _deleteManualWeight(day)
        : await deleteAppOwnedHealthWeight(healthSample);
    if (deleted) {
      _refreshDependents(selectedDay: selectedDay, day: day);
    }
    return deleted;
  }

  /// Deletes an app-owned Health Connect weight sample.
  Future<bool> deleteAppOwnedHealthWeight(HealthWeightSample? sample) async {
    if (sample == null || !sample.isFromThisApp) {
      return false;
    }
    return _deleteHealthWeightSample(sample);
  }
}
