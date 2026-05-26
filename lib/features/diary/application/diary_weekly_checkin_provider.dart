import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart'
    as goal_settings;
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart'
    as checkin_domain;
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart'
    as goal_controller;
import 'package:yamt/features/calories/provider/calorie_page_action_controller.dart'
    as page_actions;
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart'
    as week_overview;
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_controller.dart'
    as checkin_controller;
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart'
    as checkin_models;
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart'
    as checkin_provider;

part 'diary_weekly_checkin_provider.g.dart';

/// Diary facade for calorie goal settings.
typedef CalorieGoalSettings = goal_settings.CalorieGoalSettings;

/// Diary facade for goal history entries.
typedef CalorieGoalHistoryEntry = goal_settings.CalorieGoalHistoryEntry;

/// Diary facade for pending weekly check-ins.
typedef PendingCalorieGoalWeeklyCheckIn =
    goal_settings.PendingCalorieGoalWeeklyCheckIn;

/// Diary facade for weekly check-in calculations.
typedef CalorieWeeklyCheckInCalculation =
    checkin_domain.CalorieWeeklyCheckInCalculation;

/// Diary facade for blocked reasons.
typedef CalorieWeeklyCheckInBlockedReason =
    checkin_models.CalorieWeeklyCheckInBlockedReason;

/// Diary facade for learned TDEE freshness.
typedef CalorieLearnedTdeeFreshness =
    checkin_models.CalorieLearnedTdeeFreshness;

/// Diary facade for weekly check-in window day data.
typedef CalorieWeeklyCheckInWindowDay =
    checkin_models.CalorieWeeklyCheckInWindowDay;

/// Diary-owned name for the calorie weekly check-in UI data.
typedef DiaryWeeklyCheckInData = checkin_models.CalorieWeeklyCheckInData;

/// Calorie goal settings consumed by diary UI.
@riverpod
Future<CalorieGoalSettings> diaryCalorieGoalSettings(Ref ref) {
  return ref.watch(goal_controller.calorieGoalControllerProvider.future);
}

/// Weekly check-in data consumed by diary UI.
@riverpod
Future<DiaryWeeklyCheckInData> diaryWeeklyCheckInData(Ref ref) {
  return ref.watch(checkin_provider.calorieWeeklyCheckInDataProvider.future);
}

/// Whether [selectedDay] currently has calorie entries in the weekly window.
@riverpod
Future<bool> diaryWeeklyCheckInSelectedDayHasEntries(
  Ref ref,
  DateTime selectedDay,
) async {
  final overview = await ref.watch(
    week_overview.calorieWeekDayOverviewForDateProvider(selectedDay).future,
  );
  return overview.entryCount > 0;
}

/// Weekly check-in actions needed by diary presentation widgets.
@riverpod
DiaryWeeklyCheckInActions diaryWeeklyCheckInActions(Ref ref) {
  final checkInController = ref.watch(
    checkin_controller.calorieWeeklyCheckInControllerProvider.notifier,
  );
  final pageActionController = ref.watch(
    page_actions.caloriePageActionControllerProvider.notifier,
  );

  return DiaryWeeklyCheckInActions(
    syncLearnedTdeeCache: checkInController.syncLearnedTdeeCache,
    applyWeeklyCheckIn: checkInController.applyWeeklyCheckIn,
    setSkippedIntakeDay: pageActionController.setSkippedIntakeDay,
    refreshCheckInData: () {
      if (!ref.mounted) {
        return;
      }
      checkin_provider.invalidateCalorieWeeklyCheckInData(ref);
      ref.invalidate(diaryWeeklyCheckInDataProvider);
    },
  );
}

/// Actions that bridge diary UI to calorie-owned weekly check-in behavior.
class DiaryWeeklyCheckInActions {
  /// Creates weekly check-in actions.
  const DiaryWeeklyCheckInActions({
    required Future<void> Function(DiaryWeeklyCheckInData data)
    syncLearnedTdeeCache,
    required Future<bool> Function(DiaryWeeklyCheckInData data)
    applyWeeklyCheckIn,
    required Future<bool> Function({
      required DateTime selectedDay,
      required bool isSkipped,
    })
    setSkippedIntakeDay,
    required void Function() refreshCheckInData,
  }) : _syncLearnedTdeeCache = syncLearnedTdeeCache,
       _applyWeeklyCheckIn = applyWeeklyCheckIn,
       _setSkippedIntakeDay = setSkippedIntakeDay,
       _refreshCheckInData = refreshCheckInData;

  final Future<void> Function(DiaryWeeklyCheckInData data)
  _syncLearnedTdeeCache;
  final Future<bool> Function(DiaryWeeklyCheckInData data) _applyWeeklyCheckIn;
  final Future<bool> Function({
    required DateTime selectedDay,
    required bool isSkipped,
  })
  _setSkippedIntakeDay;
  final void Function() _refreshCheckInData;

  /// Synchronizes learned TDEE cache after showing or deferring the check-in.
  Future<void> syncLearnedTdeeCache(DiaryWeeklyCheckInData data) {
    return _syncLearnedTdeeCache(data);
  }

  /// Applies a weekly check-in.
  Future<bool> applyWeeklyCheckIn(DiaryWeeklyCheckInData data) {
    return _applyWeeklyCheckIn(data);
  }

  /// Marks or unmarks a selected intake day as skipped.
  Future<bool> setSkippedIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) {
    return _setSkippedIntakeDay(
      selectedDay: selectedDay,
      isSkipped: isSkipped,
    );
  }

  /// Refreshes weekly check-in data.
  void refreshCheckInData() {
    _refreshCheckInData();
  }
}
