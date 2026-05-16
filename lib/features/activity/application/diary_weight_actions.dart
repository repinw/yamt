import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/presentation/controllers/manual_health_weight_entries_controller.dart';

part 'diary_weight_actions.g.dart';

/// Weight actions used by diary weight widgets.
@riverpod
DiaryWeightActions diaryWeightActions(Ref ref) {
  final refreshCalorieWeightChange = ref.watch(
    calorieWeightStateRefreshProvider,
  );
  final manualWeightEntries = ref.watch(
    manualHealthWeightEntriesControllerProvider.notifier,
  );
  final healthWeightService = ref.watch(healthWeightServiceProvider);

  return DiaryWeightActions(
    saveManualWeight: manualWeightEntries.saveEntry,
    deleteManualWeight: manualWeightEntries.deleteEntryForDay,
    deleteHealthWeightSample: healthWeightService.deleteWeightSample,
    refreshDependents: ({required selectedDay, day}) async {
      if (!ref.mounted) {
        return;
      }
      ref.invalidate(diaryActivityWeightDataProvider(selectedDay));
      await refreshCalorieWeightChange(day: day ?? selectedDay);
      if (!ref.mounted) {
        return;
      }
      if (day != null && !isSameDiaryDay(day, selectedDay)) {
        ref.invalidate(diaryActivityWeightDataProvider(day));
      }
    },
  );
}

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
    required Future<void> Function({
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
  final Future<void> Function({required DateTime selectedDay, DateTime? day})
  _refreshDependents;

  /// Saves a manual weight and refreshes dependent diary providers.
  Future<bool> saveManualWeight({
    required DateTime selectedDay,
    required DateTime day,
    required double weightKg,
  }) async {
    final saved = await _saveManualWeight(day: day, weightKg: weightKg);
    if (saved) {
      await _refreshDependents(selectedDay: selectedDay, day: day);
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
      await _refreshDependents(selectedDay: selectedDay, day: day);
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
