import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';

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
    required this.sex,
    required this.weightKgText,
    required this.heightCmText,
    required this.ageYearsText,
    required this.activityLevelOption,
    required this.goalMode,
    required this.goalSpeedKgPerWeekText,
    required this.lastNonMaintainGoalSpeedText,
    required this.weightError,
    required this.heightError,
    required this.ageError,
    required this.goalSpeedError,
    required this.calculation,
    required this.isSaving,
  });

  /// Creates a [CalorieGoalCalculatorFormState] for initial.
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
      activityLevelOption: CalorieActivityLevelOption.fromActivityLevel(
        profile.activityLevel,
      ),
      goalMode: profile.goalMode,
      goalSpeedKgPerWeekText: normalizedGoalSpeedText,
      lastNonMaintainGoalSpeedText: preservedGoalSpeedText,
    );
  }

  /// The sex.
  final CalorieCalculatorSex sex;

  /// The weight kg text.
  final String weightKgText;

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

  /// The weight error.
  final CalorieCalculatorFieldError? weightError;

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

    if (weightKg == null ||
        heightCm == null ||
        ageYears == null ||
        goalSpeedKgPerWeek == null) {
      return null;
    }

    return CalorieCalculatorProfile(
      sex: sex,
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
    String? heightCmText,
    String? ageYearsText,
    CalorieActivityLevelOption? activityLevelOption,
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
      activityLevelOption: activityLevelOption ?? this.activityLevelOption,
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
    required CalorieActivityLevelOption activityLevelOption,
    required CalorieGoalMode goalMode,
    required String goalSpeedKgPerWeekText,
    required String lastNonMaintainGoalSpeedText,
    bool isSaving = false,
  }) {
    final weightError = _validatePositiveDouble(weightKgText);
    final heightError = _validatePositiveDouble(heightCmText);
    final ageError = _validatePositiveInt(ageYearsText);
    final goalSpeedError = goalMode == CalorieGoalMode.maintain
        ? null
        : _validatePositiveDouble(goalSpeedKgPerWeekText);
    final profile =
        weightError == null &&
            heightError == null &&
            ageError == null &&
            goalSpeedError == null
        ? CalorieCalculatorProfile(
            sex: sex,
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
      heightCmText: heightCmText,
      ageYearsText: ageYearsText,
      activityLevelOption: activityLevelOption,
      goalMode: goalMode,
      goalSpeedKgPerWeekText: goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText: lastNonMaintainGoalSpeedText,
      weightError: weightError,
      heightError: heightError,
      ageError: ageError,
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
