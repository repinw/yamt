import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/onboarding_catch_up_calculator.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_calculator_form_controller.g.dart';

const _uuid = Uuid();
const _minimumPlaceholderKcal = 100.0;

/// Defines calorie goal calculator form controller.
@riverpod
class CalorieGoalCalculatorFormController
    extends _$CalorieGoalCalculatorFormController {
  @override
  CalorieGoalCalculatorFormState build(
    CalorieCalculatorProfile? initialProfile, {
    bool useEmptyDefaults = false,
  }) {
    return CalorieGoalCalculatorFormState.initial(
      initialProfile,
      useEmptyDefaults: useEmptyDefaults,
    );
  }

  /// Update sex.
  void updateSex(CalorieCalculatorSex sex) {
    state = state.copyWith(sex: sex);
  }

  /// Update weight kg.
  void updateWeightKg(String value) {
    state = state.copyWith(weightKgText: value);
    _syncGoalMode();
  }

  /// Update target weight kg.
  void updateTargetWeightKg(String value) {
    state = state.copyWith(targetWeightKgText: value);
    _syncGoalMode();
  }

  void _syncGoalMode() {
    final startWeight = double.tryParse(
      state.weightKgText.replaceAll(',', '.'),
    );
    final targetWeight = double.tryParse(
      state.targetWeightKgText.replaceAll(',', '.'),
    );
    if (startWeight != null && targetWeight != null) {
      if (targetWeight < startWeight) {
        if (state.goalMode != CalorieGoalMode.lose) {
          updateGoalMode(CalorieGoalMode.lose);
        }
      } else if (targetWeight > startWeight) {
        if (state.goalMode != CalorieGoalMode.gain) {
          updateGoalMode(CalorieGoalMode.gain);
        }
      } else {
        if (state.goalMode != CalorieGoalMode.maintain) {
          updateGoalMode(CalorieGoalMode.maintain);
        }
      }
    }
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

  /// Update onboarding start-day choice.
  void updateOnboardingStartNow({required bool startNow}) {
    state = state.copyWith(onboardingStartNow: startNow);
  }

  /// Update same-day onboarding tracking mode.
  void updateOnboardingTodayTracking(
    CalorieGoalOnboardingTodayTracking value,
  ) {
    state = state.copyWith(onboardingTodayTracking: value);
  }

  /// Update same-day onboarding eaten estimate.
  void updateOnboardingCatchUpEstimate(
    CalorieGoalOnboardingCatchUpEstimate value,
  ) {
    state = state.copyWith(onboardingCatchUpEstimate: value);
  }

  /// Save.
  ///
  /// [onboardingPlaceholderName] is used as the visible name on
  /// auto-generated diary entries when the user picks a catch-up
  /// estimate during onboarding. Callers should pass a localized
  /// string (e.g. `caloriesOnboardingPlaceholderName` from
  /// `AppLocalizations`).
  Future<bool> save({
    required DateTime goalStartDate,
    bool allowFutureGoalStart = false,
    bool syncBurnWeekForOnboarding = false,
    bool? countGoalStartDayForLearning,
    CalorieGoalOnboardingCatchUpEstimate? onboardingCatchUpEstimate,
    String? onboardingPlaceholderName,
    DateTime? now,
  }) async {
    final profile = state.profile;
    final calculation = state.calculation;
    if (profile == null || calculation == null) {
      return false;
    }

    final referenceNow = now ?? DateTime.now();
    state = state.copyWith(isSaving: true);
    final onboardingRunWeekNumber = await _resolveOnboardingRunWeekNumber(
      syncBurnWeekForOnboarding: syncBurnWeekForOnboarding,
    );
    if (!ref.mounted) {
      return false;
    }
    // Bootstrap Burn Week BEFORE saving the goal. The goal save
    // triggers markCalorieGoalOnboardingCompleted which causes a
    // router redirect that disposes this provider. If bootstrap
    // ran after the save, ref.mounted would be false and the
    // heartCreditKcal from the onboarding estimate would be lost.
    if (syncBurnWeekForOnboarding) {
      final burnWeekStarted = await _applyOnboardingBurnWeekStart(
        goalStartDate: goalStartDate,
        now: referenceNow,
        dailyGoalKcal: calculation.finalGoalKcal,
        runWeekNumber: onboardingRunWeekNumber,
        catchUpEstimate: onboardingCatchUpEstimate,
        placeholderName: onboardingPlaceholderName,
      );
      if (!burnWeekStarted) {
        if (ref.mounted) {
          state = state.copyWith(isSaving: false);
        }
        return false;
      }
    }
    if (!ref.mounted) {
      return false;
    }
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(
          profile,
          goalStartDate: goalStartDate,
          allowFutureGoalStart: allowFutureGoalStart,
          countGoalStartDayForLearning: countGoalStartDayForLearning,
        );
    if (!ref.mounted) {
      return saved;
    }
    state = state.copyWith(isSaving: false);
    return saved;
  }

  Future<int> _resolveOnboardingRunWeekNumber({
    required bool syncBurnWeekForOnboarding,
  }) async {
    if (!syncBurnWeekForOnboarding) {
      return burnWeekLearningRunWeekNumber;
    }
    final existingSettings = await ref.read(
      calorieGoalControllerProvider.future,
    );
    return existingSettings.hasLearnedTdee
        ? burnWeekFirstGameRunWeekNumber
        : burnWeekLearningRunWeekNumber;
  }

  Future<bool> _applyOnboardingBurnWeekStart({
    required DateTime goalStartDate,
    required DateTime now,
    required double dailyGoalKcal,
    required int runWeekNumber,
    required CalorieGoalOnboardingCatchUpEstimate? catchUpEstimate,
    String? placeholderName,
  }) async {
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    final normalizedToday = normalizeDiaryDay(now);
    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    if (normalizedGoalStartDate.isAfter(normalizedToday)) {
      if (runWeekNumber > burnWeekLearningRunWeekNumber) {
        await controller.restartRunFrom(
          weekStartDate: normalizedGoalStartDate,
          runWeekNumber: runWeekNumber,
        );
        return true;
      }
      await controller.resetRun();
      return true;
    }
    if (catchUpEstimate == null) {
      await controller.restartRunFrom(
        weekStartDate: normalizedGoalStartDate,
        runWeekNumber: runWeekNumber,
      );
      return true;
    }

    final repository = ref.read(calorieLogRepositoryProvider);
    final entries = await repository.readEntriesForDay(normalizedToday);
    if (!ref.mounted) {
      return false;
    }
    final loggedKcalSoFar = entries.fold<double>(0, (sum, entry) {
      if (entry.loggedAt.isAfter(now)) {
        return sum;
      }
      return sum + entry.totalKcal;
    });

    final desiredTotalKcal = calculateOnboardingCatchUpKcal(
      dailyGoalKcal: dailyGoalKcal,
      now: now,
      estimate: catchUpEstimate,
    );
    final remainingKcal = desiredTotalKcal - loggedKcalSoFar;

    if (remainingKcal >= _minimumPlaceholderKcal &&
        placeholderName != null &&
        placeholderName.isNotEmpty) {
      final perMeal = distributeKcalAcrossMeals(
        totalKcal: remainingKcal,
        now: now,
      );
      for (final entry in perMeal.entries) {
        if (entry.value < 1) {
          continue;
        }
        final placeholder = CalorieEntry.placeholder(
          id: _uuid.v4(),
          name: placeholderName,
          mealType: entry.key,
          totalKcal: entry.value,
          loggedAt: mealMidpointForDay(entry.key, normalizedToday),
        );
        final placeholderSaved = await repository.saveEntryForCurrentUser(
          placeholder,
        );
        if (!placeholderSaved) {
          return false;
        }
        if (!ref.mounted) {
          return false;
        }
      }
    }

    await controller.bootstrapRunFrom(
      weekStartDate: normalizedGoalStartDate,
      // Placeholders now represent the catch-up calories as real diary
      // entries; no virtual heart credit is needed.
      heartCreditKcal: 0,
      runWeekNumber: runWeekNumber,
    );
    return true;
  }
}
