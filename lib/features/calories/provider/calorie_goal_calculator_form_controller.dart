import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
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

  /// Save.
  Future<bool> save({
    required DateTime goalStartDate,
    bool allowFutureGoalStart = false,
    bool? countGoalStartDayForLearning,
  }) async {
    final profile = state.profile;
    final calculation = state.calculation;
    if (profile == null || calculation == null) {
      return false;
    }

    state = state.copyWith(isSaving: true);
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
}
