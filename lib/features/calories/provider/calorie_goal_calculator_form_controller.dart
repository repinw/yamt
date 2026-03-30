import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_goal_calculator_form_controller.g.dart';

enum CalorieCalculatorFieldError { empty, invalid }

class CalorieGoalCalculatorFormState {
  const CalorieGoalCalculatorFormState({
    required this.sex,
    required this.weightKgText,
    required this.heightCmText,
    required this.ageYearsText,
    required this.activityLevelText,
    required this.goalMode,
    required this.goalSpeedKgPerWeekText,
    required this.lastNonMaintainGoalSpeedText,
    required this.weightError,
    required this.heightError,
    required this.ageError,
    required this.activityLevelError,
    required this.goalSpeedError,
    required this.calculation,
    required this.isSaving,
  });

  factory CalorieGoalCalculatorFormState.initial(
    CalorieCalculatorProfile? initialProfile,
  ) {
    final profile = initialProfile ?? const CalorieCalculatorProfile.defaults();
    final normalizedGoalSpeedText = profile.goalMode == CalorieGoalMode.maintain
        ? '0'
        : _formatDouble(profile.goalSpeedKgPerWeek);
    final preservedGoalSpeedText = profile.goalSpeedKgPerWeek > 0
        ? _formatDouble(profile.goalSpeedKgPerWeek)
        : '0.5';

    return _create(
      sex: profile.sex,
      weightKgText: _formatDouble(profile.weightKg),
      heightCmText: _formatDouble(profile.heightCm),
      ageYearsText: profile.ageYears.toString(),
      activityLevelText: _formatDouble(profile.activityLevel),
      goalMode: profile.goalMode,
      goalSpeedKgPerWeekText: normalizedGoalSpeedText,
      lastNonMaintainGoalSpeedText: preservedGoalSpeedText,
    );
  }

  final CalorieCalculatorSex sex;
  final String weightKgText;
  final String heightCmText;
  final String ageYearsText;
  final String activityLevelText;
  final CalorieGoalMode goalMode;
  final String goalSpeedKgPerWeekText;
  final String lastNonMaintainGoalSpeedText;
  final CalorieCalculatorFieldError? weightError;
  final CalorieCalculatorFieldError? heightError;
  final CalorieCalculatorFieldError? ageError;
  final CalorieCalculatorFieldError? activityLevelError;
  final CalorieCalculatorFieldError? goalSpeedError;
  final CalorieGoalCalculationResult? calculation;
  final bool isSaving;

  bool get isMaintainMode => goalMode == CalorieGoalMode.maintain;
  bool get canSave => calculation != null && !isSaving;

  CalorieCalculatorProfile? get profile {
    final weightKg = _parsePositiveDouble(weightKgText);
    final heightCm = _parsePositiveDouble(heightCmText);
    final ageYears = _parsePositiveInt(ageYearsText);
    final activityLevel = _parsePositiveDouble(activityLevelText);
    final goalSpeedKgPerWeek = isMaintainMode
        ? 0.0
        : _parsePositiveDouble(goalSpeedKgPerWeekText);

    if (weightKg == null ||
        heightCm == null ||
        ageYears == null ||
        activityLevel == null ||
        goalSpeedKgPerWeek == null) {
      return null;
    }

    return CalorieCalculatorProfile(
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      activityLevel: activityLevel,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    );
  }

  CalorieGoalCalculatorFormState copyWith({
    CalorieCalculatorSex? sex,
    String? weightKgText,
    String? heightCmText,
    String? ageYearsText,
    String? activityLevelText,
    CalorieGoalMode? goalMode,
    String? goalSpeedKgPerWeekText,
    String? lastNonMaintainGoalSpeedText,
    bool? isSaving,
  }) {
    return _create(
      sex: sex ?? this.sex,
      weightKgText: weightKgText ?? this.weightKgText,
      heightCmText: heightCmText ?? this.heightCmText,
      ageYearsText: ageYearsText ?? this.ageYearsText,
      activityLevelText: activityLevelText ?? this.activityLevelText,
      goalMode: goalMode ?? this.goalMode,
      goalSpeedKgPerWeekText:
          goalSpeedKgPerWeekText ?? this.goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText:
          lastNonMaintainGoalSpeedText ?? this.lastNonMaintainGoalSpeedText,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  static CalorieGoalCalculatorFormState _create({
    required CalorieCalculatorSex sex,
    required String weightKgText,
    required String heightCmText,
    required String ageYearsText,
    required String activityLevelText,
    required CalorieGoalMode goalMode,
    required String goalSpeedKgPerWeekText,
    required String lastNonMaintainGoalSpeedText,
    bool isSaving = false,
  }) {
    final weightError = _validatePositiveDouble(weightKgText);
    final heightError = _validatePositiveDouble(heightCmText);
    final ageError = _validatePositiveInt(ageYearsText);
    final activityLevelError = _validatePositiveDouble(activityLevelText);
    final goalSpeedError = goalMode == CalorieGoalMode.maintain
        ? null
        : _validatePositiveDouble(goalSpeedKgPerWeekText);
    final profile =
        weightError == null &&
            heightError == null &&
            ageError == null &&
            activityLevelError == null &&
            goalSpeedError == null
        ? CalorieCalculatorProfile(
            sex: sex,
            weightKg: _parsePositiveDouble(weightKgText)!,
            heightCm: _parsePositiveDouble(heightCmText)!,
            ageYears: _parsePositiveInt(ageYearsText)!,
            activityLevel: _parsePositiveDouble(activityLevelText)!,
            goalMode: goalMode,
            goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
                ? 0
                : _parsePositiveDouble(goalSpeedKgPerWeekText)!,
          )
        : null;

    return CalorieGoalCalculatorFormState(
      sex: sex,
      weightKgText: weightKgText,
      heightCmText: heightCmText,
      ageYearsText: ageYearsText,
      activityLevelText: activityLevelText,
      goalMode: goalMode,
      goalSpeedKgPerWeekText: goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText: lastNonMaintainGoalSpeedText,
      weightError: weightError,
      heightError: heightError,
      ageError: ageError,
      activityLevelError: activityLevelError,
      goalSpeedError: goalSpeedError,
      calculation: profile == null
          ? null
          : CalorieGoalCalculator.calculate(profile),
      isSaving: isSaving,
    );
  }

  static String _formatDouble(double value) {
    final fixed = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    if (!fixed.contains('.')) {
      return fixed;
    }
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static double? _parsePositiveDouble(String rawValue) {
    final normalizedValue = rawValue.trim().replaceAll(',', '.');
    if (normalizedValue.isEmpty) {
      return null;
    }
    final parsedValue = double.tryParse(normalizedValue);
    if (parsedValue == null || parsedValue <= 0) {
      return null;
    }
    return parsedValue;
  }

  static int? _parsePositiveInt(String rawValue) {
    final normalizedValue = rawValue.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }
    final parsedValue = int.tryParse(normalizedValue);
    if (parsedValue == null || parsedValue <= 0) {
      return null;
    }
    return parsedValue;
  }

  static CalorieCalculatorFieldError? _validatePositiveDouble(String rawValue) {
    if (rawValue.trim().isEmpty) {
      return CalorieCalculatorFieldError.empty;
    }
    return _parsePositiveDouble(rawValue) == null
        ? CalorieCalculatorFieldError.invalid
        : null;
  }

  static CalorieCalculatorFieldError? _validatePositiveInt(String rawValue) {
    if (rawValue.trim().isEmpty) {
      return CalorieCalculatorFieldError.empty;
    }
    return _parsePositiveInt(rawValue) == null
        ? CalorieCalculatorFieldError.invalid
        : null;
  }
}

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

  void updateActivityLevel(String value) {
    state = state.copyWith(activityLevelText: value);
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

  Future<bool> save() async {
    final profile = state.profile;
    if (profile == null) {
      return false;
    }

    state = state.copyWith(isSaving: true);
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .saveCalculatedGoal(profile);
    if (!ref.mounted) {
      return false;
    }
    state = state.copyWith(isSaving: false);
    return saved;
  }
}
