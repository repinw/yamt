import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';

part 'calorie_goal_calculator_form_controller.g.dart';

@riverpod
class CalorieGoalCalculatorFormController
    extends _$CalorieGoalCalculatorFormController {
  @override
  CalorieGoalCalculatorFormState build(
    CalorieCalculatorProfile? initialProfile,
  ) {
    return CalorieGoalCalculatorFormState.initial(initialProfile);
  }

  void updateSex(CalorieCalculatorSex sex) {
    state = state.copyWith(sex: sex);
  }

  void updateWeightKg(String value) {
    state = state.copyWith(weightKgText: value);
  }

  void updateHeightCm(String value) {
    state = state.copyWith(heightCmText: value);
  }

  void updateAgeYears(String value) {
    state = state.copyWith(ageYearsText: value);
  }

  void updateActivityLevel(CalorieActivityLevelOption option) {
    state = state.copyWith(activityLevelOption: option);
  }

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

  void updateGoalSpeedKgPerWeek(String value) {
    state = state.copyWith(
      goalSpeedKgPerWeekText: value,
      lastNonMaintainGoalSpeedText: value.trim().isEmpty ? '0.5' : value,
    );
  }

  Future<bool> save({required DateTime goalStartAt}) async {
    final profile = state.profile;
    if (profile == null) {
      return false;
    }

    state = state.copyWith(isSaving: true);
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(profile, goalStartAt: goalStartAt);
    if (!ref.mounted) {
      return saved;
    }
    state = state.copyWith(isSaving: false);
    return saved;
  }
}
