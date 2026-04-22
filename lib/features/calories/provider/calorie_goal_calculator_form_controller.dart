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
  Future<bool> save({required DateTime goalStartDate}) async {
    final profile = state.profile;
    if (profile == null) {
      return false;
    }

    state = state.copyWith(isSaving: true);
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(
          profile,
          goalStartDate: goalStartDate,
        );
    if (!ref.mounted) {
      return saved;
    }
    state = state.copyWith(isSaving: false);
    return saved;
  }
}
