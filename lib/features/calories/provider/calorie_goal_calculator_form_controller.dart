import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_calculator_form_controller.g.dart';

/// Defines calorie goal calculator form controller.
@riverpod
class CalorieGoalCalculatorFormController
    extends _$CalorieGoalCalculatorFormController {
  @override
  CalorieGoalCalculatorFormState build(
    CalorieCalculatorProfile? initialProfile,
  ) {
    return CalorieGoalCalculatorFormState.initial(initialProfile);
  }

  /// Update sex.
  void updateSex(CalorieCalculatorSex sex) {
    state = state.copyWith(sex: sex);
  }

  /// Update weight kg.
  void updateWeightKg(String value) {
    state = state.copyWith(weightKgText: value);
  }

  /// Update height cm.
  void updateHeightCm(String value) {
    state = state.copyWith(heightCmText: value);
  }

  /// Update age years.
  void updateAgeYears(String value) {
    state = state.copyWith(ageYearsText: value);
  }

  /// Update activity level.
  void updateActivityLevel(CalorieActivityLevelOption option) {
    state = state.copyWith(activityLevelOption: option);
  }

  /// Update goal mode.
  void updateGoalMode(CalorieGoalMode goalMode) {
    if (goalMode == CalorieGoalMode.maintain) {
      final lastGoalSpeed = state.goalSpeedKgPerWeekText.trim() == '0'
          ? state.lastNonMaintainGoalSpeedText
          : state.goalSpeedKgPerWeekText;
      state = state.copyWith(
        goalMode: goalMode,
        goalSpeedKgPerWeekText: '0',
        lastNonMaintainGoalSpeedText: lastGoalSpeed,
      );
      return;
    }

    final restoredGoalSpeed = state.lastNonMaintainGoalSpeedText.trim().isEmpty
        ? '0.5'
        : state.lastNonMaintainGoalSpeedText;
    state = state.copyWith(
      goalMode: goalMode,
      goalSpeedKgPerWeekText: restoredGoalSpeed,
    );
  }

  /// Update goal speed kg per week.
  void updateGoalSpeedKgPerWeek(String value) {
    state = state.copyWith(
      goalSpeedKgPerWeekText: value,
      lastNonMaintainGoalSpeedText: value.trim().isEmpty ? '0.5' : value,
    );
  }

  /// Save.
  Future<bool> save({
    required DateTime goalStartDate,
    bool allowFutureGoalStart = false,
    bool syncBurnWeekForOnboarding = false,
    CalorieGoalOnboardingCatchUpEstimate? onboardingCatchUpEstimate,
    DateTime? now,
  }) async {
    final profile = state.profile;
    final calculation = state.calculation;
    if (profile == null || calculation == null) {
      return false;
    }

    final referenceNow = now ?? DateTime.now();
    state = state.copyWith(isSaving: true);
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(
          profile,
          goalStartDate: goalStartDate,
          allowFutureGoalStart: allowFutureGoalStart,
        );
    if (saved && ref.mounted && syncBurnWeekForOnboarding) {
      await _applyOnboardingBurnWeekStart(
        goalStartDate: goalStartDate,
        now: referenceNow,
        dailyGoalKcal: calculation.finalGoalKcal,
        catchUpEstimate: onboardingCatchUpEstimate,
      );
    }
    if (!ref.mounted) {
      return saved;
    }
    state = state.copyWith(isSaving: false);
    return saved;
  }

  Future<void> _applyOnboardingBurnWeekStart({
    required DateTime goalStartDate,
    required DateTime now,
    required double dailyGoalKcal,
    required CalorieGoalOnboardingCatchUpEstimate? catchUpEstimate,
  }) async {
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    final normalizedToday = normalizeDiaryDay(now);
    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    if (normalizedGoalStartDate.isAfter(normalizedToday)) {
      await controller.resetRun();
      return;
    }
    if (catchUpEstimate == null) {
      await controller.restartRunFrom(weekStartDate: normalizedGoalStartDate);
      return;
    }

    final entries = await ref
        .read(calorieLogRepositoryProvider)
        .readEntriesForDay(normalizedToday);
    if (!ref.mounted) {
      return;
    }
    final loggedKcalSoFar = entries.fold<double>(0, (sum, entry) {
      if (entry.loggedAt.isAfter(now)) {
        return sum;
      }
      return sum + entry.totalKcal;
    });
    final startOfDay = DateTime(now.year, now.month, now.day);
    final dayProgress = (now.difference(startOfDay).inSeconds / (24 * 60 * 60))
        .clamp(0.0, 1.0);
    final targetKcal = dailyGoalKcal * dayProgress;
    final safeZoneWidthKcal =
        dailyGoalKcal * resolveBurnWeekMockDifficulty(0).safeZoneMultiplier;
    final desiredConsumedKcal = switch (catchUpEstimate) {
      CalorieGoalOnboardingCatchUpEstimate.low =>
        targetKcal - safeZoneWidthKcal,
      CalorieGoalOnboardingCatchUpEstimate.normal => targetKcal,
      CalorieGoalOnboardingCatchUpEstimate.high =>
        targetKcal + safeZoneWidthKcal,
    };
    final effectiveDesiredConsumedKcal = desiredConsumedKcal < 0
        ? 0.0
        : desiredConsumedKcal;
    await controller.bootstrapRunFrom(
      weekStartDate: normalizedGoalStartDate,
      heartCreditKcal: effectiveDesiredConsumedKcal - loggedKcalSoFar,
    );
  }
}
