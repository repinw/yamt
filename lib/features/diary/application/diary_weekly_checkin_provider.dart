import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart'
    as goal_controller;
import 'package:yamt/features/calories/application/calorie_week_overview_provider.dart'
    as week_overview;
import 'package:yamt/features/calories/application/calorie_weekly_checkin_controller.dart'
    as checkin_controller;
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart'
    as checkin_demo;
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_plan_provider.dart'
    as checkin_plan;
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart'
    as checkin_provider;
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

part 'diary_weekly_checkin_provider.g.dart';

/// Calorie goal settings consumed by diary UI.
@riverpod
Future<CalorieGoalSettings> diaryCalorieGoalSettings(Ref ref) {
  return ref.watch(goal_controller.calorieGoalControllerProvider.future);
}

/// Whether the active calorie goal had already been reached on [day].
bool diaryActiveCalorieGoalWasReached(
  CalorieGoalSettings settings,
  DateTime day,
) {
  return settings.cycleAnchorEntryForDay(day)?.reachedAt != null;
}

/// Most recent recorded weight inside a weekly check-in window.
double? latestDiaryCheckInWeightKg(CalorieWeeklyCheckInData data) {
  for (final day in data.days.reversed) {
    if (day.weightKg != null) {
      return day.weightKg;
    }
  }
  return null;
}

/// Whether the check-in waits for a weight that the user can still track.
bool diaryCheckInCanTrackMissingWeight(CalorieWeeklyCheckInData data) {
  if (data.missingWeightDays.isEmpty) {
    return false;
  }

  return switch (data.blockedReason) {
    CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
    CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight => true,
    _ => false,
  };
}

/// Weekly check-in data consumed by diary UI.
@riverpod
Future<CalorieWeeklyCheckInData> diaryWeeklyCheckInData(Ref ref) {
  return ref.watch(checkin_provider.calorieWeeklyCheckInDataProvider.future);
}

/// Plan of the pending weekly check-in consumed by diary UI.
@riverpod
Future<CalorieWeeklyCheckInPlan?> diaryWeeklyCheckInPlan(Ref ref) {
  return ref.watch(checkin_plan.calorieWeeklyCheckInPlanProvider.future);
}

/// Plan of the latest completed window, for the debug preview.
@riverpod
Future<CalorieWeeklyCheckInPlan?> diaryWeeklyCheckInPreviewPlan(Ref ref) {
  return ref.watch(checkin_plan.calorieWeeklyCheckInPreviewPlanProvider.future);
}

/// Check-in data of the latest completed window, for the debug preview.
@riverpod
Future<CalorieWeeklyCheckInData> diaryWeeklyCheckInPreviewData(Ref ref) {
  return ref.watch(
    checkin_provider.calorieWeeklyCheckInPreviewDataProvider.future,
  );
}

/// Demo check-in data that lacks the end weight, for the debug preview.
CalorieWeeklyCheckInData diaryWeeklyCheckInBlockedDemoData(DateTime today) {
  return checkin_demo.calorieWeeklyCheckInDemoData(today: today, blocked: true);
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
  final goalController = ref.watch(
    goal_controller.calorieGoalControllerProvider.notifier,
  );

  return DiaryWeeklyCheckInActions(
    syncLearnedTdeeCache: checkInController.syncLearnedTdeeCache,
    applyWeeklyCheckIn: (data, training) =>
        checkInController.applyWeeklyCheckIn(data, training: training),
    rejectWeeklyCheckIn: (data, training) =>
        checkInController.rejectWeeklyCheckIn(data, training: training),
    showWeeklyCheckInAgain: (pendingWeeklyCheckIn) async {
      final saved = await checkInController.showPendingWeeklyCheckInAgain(
        pendingWeeklyCheckIn,
      );
      if (saved && ref.mounted) {
        checkin_provider.invalidateCalorieWeeklyCheckInData(ref);
        ref.invalidate(diaryWeeklyCheckInDataProvider);
      }
      return saved;
    },
    setSkippedIntakeDay: ({required selectedDay, required isSkipped}) =>
        goalController.setSkippedIntakeDay(
          day: selectedDay,
          isSkipped: isSkipped,
        ),
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
  const new({
    required this._syncLearnedTdeeCache,
    required this._applyWeeklyCheckIn,
    required this._rejectWeeklyCheckIn,
    required this._showWeeklyCheckInAgain,
    required this._setSkippedIntakeDay,
    required this._refreshCheckInData,
  });

  final Future<void> Function(CalorieWeeklyCheckInData data)
  _syncLearnedTdeeCache;
  final Future<bool> Function(
    CalorieWeeklyCheckInData data,
    CalorieRunTrainingChoice? training,
  )
  _applyWeeklyCheckIn;
  final Future<bool> Function(
    CalorieWeeklyCheckInData data,
    CalorieRunTrainingChoice? training,
  )
  _rejectWeeklyCheckIn;
  final Future<bool> Function(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  )
  _showWeeklyCheckInAgain;
  final Future<bool> Function({
    required DateTime selectedDay,
    required bool isSkipped,
  })
  _setSkippedIntakeDay;
  final void Function() _refreshCheckInData;

  /// Synchronizes learned TDEE cache after showing or deferring the check-in.
  Future<void> syncLearnedTdeeCache(CalorieWeeklyCheckInData data) {
    return _syncLearnedTdeeCache(data);
  }

  /// Applies a weekly check-in, after saving the [training] of the run.
  Future<bool> applyWeeklyCheckIn(
    CalorieWeeklyCheckInData data, {
    CalorieRunTrainingChoice? training,
  }) {
    return _applyWeeklyCheckIn(data, training);
  }

  /// Rejects a weekly check-in, keeping the previous TDEE and goal, after
  /// saving the [training] of the run.
  Future<bool> rejectWeeklyCheckIn(
    CalorieWeeklyCheckInData data, {
    CalorieRunTrainingChoice? training,
  }) {
    return _rejectWeeklyCheckIn(data, training);
  }

  /// Reopens a dismissed weekly check-in window.
  Future<bool> showWeeklyCheckInAgain(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) {
    return _showWeeklyCheckInAgain(pendingWeeklyCheckIn);
  }

  /// Marks or unmarks a selected intake day as skipped.
  Future<bool> setSkippedIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) {
    return _setSkippedIntakeDay(selectedDay: selectedDay, isSkipped: isSkipped);
  }

  /// Refreshes weekly check-in data.
  void refreshCheckInData() {
    _refreshCheckInData();
  }
}
