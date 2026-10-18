import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';

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

  return DiaryWeightActions(
    saveManualWeight: manualWeightEntries.saveEntry,
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

/// Save behavior for diary weight entries.
class DiaryWeightActions {
  /// Creates diary weight actions.
  const new({
    required this._saveManualWeight,
    required this._refreshDependents,
  });

  final Future<bool> Function({required DateTime day, required double weightKg})
  _saveManualWeight;
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
}
