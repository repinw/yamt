import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_progress_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/application/macro_goal_settings_controller.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_snapshot_rules.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_weekly_checkin_plan_provider.g.dart';

/// The plan of the pending weekly check-in, or `null` without one.
@riverpod
Future<CalorieWeeklyCheckInPlan?> calorieWeeklyCheckInPlan(Ref ref) async {
  final checkInData = await ref.watch(calorieWeeklyCheckInDataProvider.future);
  if (!ref.mounted) {
    throw StateError('Weekly check-in plan was disposed.');
  }
  return await _buildPlan(ref, checkInData);
}

/// The plan of the latest completed window, for the debug preview.
@riverpod
Future<CalorieWeeklyCheckInPlan?> calorieWeeklyCheckInPreviewPlan(
  Ref ref,
) async {
  final checkInData = await ref.watch(
    calorieWeeklyCheckInPreviewDataProvider.future,
  );
  if (!ref.mounted) {
    throw StateError('Weekly check-in preview plan was disposed.');
  }
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Weekly check-in preview plan was disposed.');
  }
  final today = ref.watch(clockProvider)();
  final hasWindow =
      resolveLatestCompletedCalorieWeeklyCheckIn(
        settings: settings,
        today: normalizeDiaryDay(today),
      ) !=
      null;
  if (!hasWindow) {
    return calorieWeeklyCheckInDemoPlan(
      today: today,
      macroSettings: ref.watch(macroGoalSettingsControllerProvider),
      profile: settings.calculatorProfile,
    );
  }
  return await _buildPlan(ref, checkInData);
}

Future<CalorieWeeklyCheckInPlan?> _buildPlan(
  Ref ref,
  CalorieWeeklyCheckInData checkInData,
) async {
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  if (!ref.mounted) {
    throw StateError('Weekly check-in plan was disposed.');
  }
  final pending = checkInData.pendingWeeklyCheckIn;
  if (pending == null) {
    return null;
  }
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final windowEnd = normalizeDiaryDay(pending.windowEndDate);
  final progress = await ref.watch(
    calorieGoalProgressProvider(windowEnd).future,
  );
  if (!ref.mounted) {
    throw StateError('Weekly check-in plan was disposed.');
  }

  final reviewedRun = settings.runTrainingPlan(windowEnd);
  final nextRun = settings.runTrainingPlan(today);
  final reviewedWeekdays = {
    for (final day in reviewedRun.trainingDays) day.weekday,
  };
  final calculation = checkInData.isReady ? checkInData.calculation : null;
  final profile = settings.calculatorProfile;
  final goalProfile =
      settings.goalEntryForDay(today)?.calculatorProfile ?? profile;

  return CalorieWeeklyCheckInPlan(
    reviewedRunNumber: resolveCalorieGoalRunNumber(
      settings: settings,
      day: windowEnd,
    ),
    reviewedDays: (
      start: normalizeDiaryDay(pending.windowStartDate),
      end: windowEnd,
    ),
    previousTrainingDayCount: reviewedRun.trainingDays.length,
    nextRunDays: nextRun.days,
    suggestedTrainingDays: {
      for (final day in nextRun.days)
        if (!nextRun.pauseDays.contains(day) &&
            reviewedWeekdays.contains(day.weekday))
          day,
    },
    pauseDays: nextRun.pauseDays,
    sessionKcal: settings.trainingSessionKcalForDay(today),
    previousTdeeKcal: calculation?.previousTdeeKcal ?? 0,
    previousGoalKcal: goalKcalBeforeWeeklyCheckIn(
      settings: settings,
      checkInWindowStartDate: pending.windowStartDate,
    ),
    measurement: calculation == null
        ? null
        : (
            tdeeKcal: calculation.calculatedTdeeKcal,
            goalKcal: calculation.newGoalKcal,
            averageIntakeKcal: calculation.averageIntakeKcal,
          ),
    progress: progress,
    profile: profile,
    macroSettings: ref.watch(macroGoalSettingsControllerProvider),
    previousMacroWeightKg: settings.macroWeightKgForDay(pending.windowEndDate),
    newMacroWeightKg: checkInData.macroWeightKg,
    isLosingWeight: goalProfile?.goalMode == CalorieGoalMode.lose,
  );
}
