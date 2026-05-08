import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';

/// Defines calorie calculator field error.
enum CalorieCalculatorFieldError {
  /// Empty.
  empty,

  /// Invalid.
  invalid,
}

/// Defines calorie goal calculator form state.
class CalorieGoalCalculatorFormState {
  /// The calorie goal calculator form state.
  const CalorieGoalCalculatorFormState({
    required this.sexError,
    required this.weightKgText,
    required this.targetWeightKgText,
    required this.heightCmText,
    required this.ageYearsText,
    required this.activityLevelOption,
    required this.goalMode,
    required this.goalSpeedKgPerWeekText,
    required this.lastNonMaintainGoalSpeedText,
    required this.onboardingStartNow,
    required this.onboardingTodayTracking,
    required this.onboardingCatchUpEstimate,
    required this.weightError,
    required this.targetWeightError,
    required this.heightError,
    required this.ageError,
    required this.goalSpeedError,
    required this.calculation,
    required this.isSaving,
    this.sex,
  });

  /// Creates a [CalorieGoalCalculatorFormState] for initial.
  factory CalorieGoalCalculatorFormState.initial(
    CalorieCalculatorProfile? initialProfile, {
    bool useEmptyDefaults = false,
  }) {
    final profile = initialProfile ?? const CalorieCalculatorProfile.defaults();
    final shouldUseEmptyFields = initialProfile == null && useEmptyDefaults;
    final normalizedGoalSpeedText = profile.goalMode == CalorieGoalMode.maintain
        ? '0'
        : _formatDouble(profile.goalSpeedKgPerWeek);
    final preservedGoalSpeedText = profile.goalSpeedKgPerWeek > 0
        ? _formatDouble(profile.goalSpeedKgPerWeek)
        : '0.5';

    return CalorieGoalCalculatorFormState._create(
      sex: shouldUseEmptyFields ? null : profile.sex,
      weightKgText: shouldUseEmptyFields ? '' : _formatDouble(profile.weightKg),
      targetWeightKgText: '',
      heightCmText: shouldUseEmptyFields ? '' : _formatDouble(profile.heightCm),
      ageYearsText: shouldUseEmptyFields ? '' : profile.ageYears.toString(),
      activityLevelOption: CalorieActivityLevelOption.fromActivityLevel(
        profile.activityLevel,
      ),
      goalMode: profile.goalMode,
      goalSpeedKgPerWeekText: normalizedGoalSpeedText,
      lastNonMaintainGoalSpeedText: preservedGoalSpeedText,
      onboardingStartNow: true,
      onboardingTodayTracking: CalorieGoalOnboardingTodayTracking.exact,
      onboardingCatchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
    );
  }

  factory CalorieGoalCalculatorFormState._create({
    required String weightKgText,
    required String targetWeightKgText,
    required String heightCmText,
    required String ageYearsText,
    required CalorieActivityLevelOption activityLevelOption,
    required CalorieGoalMode goalMode,
    required String goalSpeedKgPerWeekText,
    required String lastNonMaintainGoalSpeedText,
    required bool onboardingStartNow,
    required CalorieGoalOnboardingTodayTracking onboardingTodayTracking,
    required CalorieGoalOnboardingCatchUpEstimate onboardingCatchUpEstimate,
    CalorieCalculatorSex? sex,
    bool isSaving = false,
  }) {
    final weightError = _validateWeight(weightKgText);
    final targetWeightError = targetWeightKgText.isEmpty
        ? null
        : _validateWeight(targetWeightKgText);
    final heightError = _validateHeight(heightCmText);
    final ageError = _validateAge(ageYearsText);
    final goalSpeedError = goalMode == CalorieGoalMode.maintain
        ? null
        : _validatePositiveDouble(goalSpeedKgPerWeekText);
    final sexError = sex == null ? CalorieCalculatorFieldError.empty : null;
    final profile =
        sexError == null &&
            weightError == null &&
            heightError == null &&
            ageError == null &&
            goalSpeedError == null
        ? CalorieCalculatorProfile(
            sex: sex!,
            weightKg: _parsePositiveDouble(weightKgText)!,
            heightCm: _parsePositiveDouble(heightCmText)!,
            ageYears: _parsePositiveInt(ageYearsText)!,
            activityLevel: activityLevelOption.palValue,
            goalMode: goalMode,
            goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
                ? 0
                : _parsePositiveDouble(goalSpeedKgPerWeekText)!,
          )
        : null;

    return CalorieGoalCalculatorFormState(
      sex: sex,
      weightKgText: weightKgText,
      targetWeightKgText: targetWeightKgText,
      heightCmText: heightCmText,
      ageYearsText: ageYearsText,
      activityLevelOption: activityLevelOption,
      goalMode: goalMode,
      goalSpeedKgPerWeekText: goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText: lastNonMaintainGoalSpeedText,
      onboardingStartNow: onboardingStartNow,
      onboardingTodayTracking: onboardingTodayTracking,
      onboardingCatchUpEstimate: onboardingCatchUpEstimate,
      sexError: sexError,
      weightError: weightError,
      targetWeightError: targetWeightError,
      heightError: heightError,
      ageError: ageError,
      goalSpeedError: goalSpeedError,
      calculation: profile == null
          ? null
          : CalorieGoalCalculator.calculate(profile),
      isSaving: isSaving,
    );
  }

  /// The sex.
  final CalorieCalculatorSex? sex;

  /// The sex error.
  final CalorieCalculatorFieldError? sexError;

  /// The weight kg text.
  final String weightKgText;

  /// The target weight kg text.
  final String targetWeightKgText;

  /// The height cm text.
  final String heightCmText;

  /// The age years text.
  final String ageYearsText;

  /// The activity level option.
  final CalorieActivityLevelOption activityLevelOption;

  /// The goal mode.
  final CalorieGoalMode goalMode;

  /// The goal speed kg per week text.
  final String goalSpeedKgPerWeekText;

  /// The last non maintain goal speed text.
  final String lastNonMaintainGoalSpeedText;

  /// Whether onboarding starts today.
  final bool onboardingStartNow;

  /// How onboarding should treat today's food.
  final CalorieGoalOnboardingTodayTracking onboardingTodayTracking;

  /// Same-day onboarding rough eaten estimate.
  final CalorieGoalOnboardingCatchUpEstimate onboardingCatchUpEstimate;

  /// The weight error.
  final CalorieCalculatorFieldError? weightError;

  /// The target weight error.
  final CalorieCalculatorFieldError? targetWeightError;

  /// The height error.
  final CalorieCalculatorFieldError? heightError;

  /// The age error.
  final CalorieCalculatorFieldError? ageError;

  /// The goal speed error.
  final CalorieCalculatorFieldError? goalSpeedError;

  /// The calculation.
  final CalorieGoalCalculationResult? calculation;

  /// Whether saving.
  final bool isSaving;

  /// Whether maintain mode.
  bool get isMaintainMode => goalMode == CalorieGoalMode.maintain;

  /// Whether save.
  bool get canSave => calculation != null && !isSaving;

  /// The profile.
  CalorieCalculatorProfile? get profile {
    final weightKg = _parsePositiveDouble(weightKgText);
    final heightCm = _parsePositiveDouble(heightCmText);
    final ageYears = _parsePositiveInt(ageYearsText);
    final goalSpeedKgPerWeek = isMaintainMode
        ? 0.0
        : _parsePositiveDouble(goalSpeedKgPerWeekText);

    if (sex == null ||
        weightKg == null ||
        heightCm == null ||
        ageYears == null ||
        goalSpeedKgPerWeek == null) {
      return null;
    }

    return CalorieCalculatorProfile(
      sex: sex!,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      activityLevel: activityLevelOption.palValue,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
    );
  }

  /// Copy with.
  CalorieGoalCalculatorFormState copyWith({
    CalorieCalculatorSex? sex,
    String? weightKgText,
    String? targetWeightKgText,
    String? heightCmText,
    String? ageYearsText,
    CalorieActivityLevelOption? activityLevelOption,
    CalorieGoalMode? goalMode,
    String? goalSpeedKgPerWeekText,
    String? lastNonMaintainGoalSpeedText,
    bool? onboardingStartNow,
    CalorieGoalOnboardingTodayTracking? onboardingTodayTracking,
    CalorieGoalOnboardingCatchUpEstimate? onboardingCatchUpEstimate,
    bool? isSaving,
  }) {
    return CalorieGoalCalculatorFormState._create(
      sex: sex ?? this.sex,
      weightKgText: weightKgText ?? this.weightKgText,
      targetWeightKgText: targetWeightKgText ?? this.targetWeightKgText,
      heightCmText: heightCmText ?? this.heightCmText,
      ageYearsText: ageYearsText ?? this.ageYearsText,
      activityLevelOption: activityLevelOption ?? this.activityLevelOption,
      goalMode: goalMode ?? this.goalMode,
      goalSpeedKgPerWeekText:
          goalSpeedKgPerWeekText ?? this.goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText:
          lastNonMaintainGoalSpeedText ?? this.lastNonMaintainGoalSpeedText,
      onboardingStartNow: onboardingStartNow ?? this.onboardingStartNow,
      onboardingTodayTracking:
          onboardingTodayTracking ?? this.onboardingTodayTracking,
      onboardingCatchUpEstimate:
          onboardingCatchUpEstimate ?? this.onboardingCatchUpEstimate,
      isSaving: isSaving ?? this.isSaving,
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

  static CalorieCalculatorFieldError? _validateWeight(String rawValue) {
    if (rawValue.trim().isEmpty) {
      return CalorieCalculatorFieldError.empty;
    }
    final val = _parsePositiveDouble(rawValue);
    if (val == null || val < 40 || val > 250) {
      return CalorieCalculatorFieldError.invalid;
    }
    return null;
  }

  static CalorieCalculatorFieldError? _validateHeight(String rawValue) {
    if (rawValue.trim().isEmpty) {
      return CalorieCalculatorFieldError.empty;
    }
    final val = _parsePositiveDouble(rawValue);
    if (val == null || val < 120 || val > 250) {
      return CalorieCalculatorFieldError.invalid;
    }
    return null;
  }

  static CalorieCalculatorFieldError? _validateAge(String rawValue) {
    if (rawValue.trim().isEmpty) {
      return CalorieCalculatorFieldError.empty;
    }
    final val = _parsePositiveInt(rawValue);
    if (val == null || val < 16 || val > 100) {
      return CalorieCalculatorFieldError.invalid;
    }
    return null;
  }
}
