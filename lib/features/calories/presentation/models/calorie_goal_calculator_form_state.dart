import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/presentation/models/calorie_goal_calculator_form_fields.dart';

/// Defines calorie goal calculator form state.
class CalorieGoalCalculatorFormState {
  /// The calorie goal calculator form state.
  const new({
    required this.sexError,
    required this.weightKgText,
    required this.targetWeightKgText,
    required this.heightCmText,
    required this.ageYearsText,
    required this.activityLevelOption,
    required this.goalMode,
    required this.goalSpeedKgPerWeekText,
    required this.lastNonMaintainGoalSpeedText,
    required this.weightError,
    required this.targetWeightError,
    required this.heightError,
    required this.ageError,
    required this.goalSpeedError,
    required this.calculation,
    required this.isSaving,
    this.trainingWeekdays = const <int>[],
    this.trainingDayKcalOffset = 0.0,
    this.sex,
    this.birthDate,
  });

  /// Creates a [CalorieGoalCalculatorFormState] for initial.
  factory initial(
    CalorieCalculatorProfile? initialProfile, {
    bool useEmptyDefaults = false,
  }) {
    final profile = initialProfile ?? const CalorieCalculatorProfile.defaults();
    final shouldUseEmptyFields = initialProfile == null && useEmptyDefaults;
    final normalizedGoalSpeedText = profile.goalMode == CalorieGoalMode.maintain
        ? '0'
        : formatCalculatorNumber(profile.goalSpeedKgPerWeek);
    final preservedGoalSpeedText = profile.goalSpeedKgPerWeek > 0
        ? formatCalculatorNumber(profile.goalSpeedKgPerWeek)
        : '0.5';

    return CalorieGoalCalculatorFormState._create(
      sex: shouldUseEmptyFields ? null : profile.sex,
      weightKgText: shouldUseEmptyFields
          ? ''
          : formatCalculatorNumber(profile.weightKg),
      targetWeightKgText: shouldUseEmptyFields || profile.targetWeightKg == null
          ? ''
          : formatCalculatorNumber(profile.targetWeightKg!),
      heightCmText: shouldUseEmptyFields
          ? ''
          : formatCalculatorNumber(profile.heightCm),
      ageYearsText: shouldUseEmptyFields ? '' : profile.ageYears.toString(),
      activityLevelOption: CalorieActivityLevelOption.fromActivityLevel(
        profile.activityLevel,
      ),
      goalMode: profile.goalMode,
      goalSpeedKgPerWeekText: normalizedGoalSpeedText,
      lastNonMaintainGoalSpeedText: preservedGoalSpeedText,
      trainingWeekdays: profile.trainingWeekdays,
      trainingDayKcalOffset: profile.trainingDayKcalOffset,
      birthDate: shouldUseEmptyFields ? null : profile.birthDate,
    );
  }

  factory _create({
    required String weightKgText,
    required String targetWeightKgText,
    required String heightCmText,
    required String ageYearsText,
    required CalorieActivityLevelOption activityLevelOption,
    required CalorieGoalMode goalMode,
    required String goalSpeedKgPerWeekText,
    required String lastNonMaintainGoalSpeedText,
    List<int> trainingWeekdays = const <int>[],
    double trainingDayKcalOffset = 0.0,
    CalorieCalculatorSex? sex,
    DateTime? birthDate,
    bool isSaving = false,
  }) {
    final weightError = validateCalculatorWeight(weightKgText);
    final targetWeightError = goalMode == CalorieGoalMode.maintain
        ? null
        : validateCalculatorWeight(targetWeightKgText);
    final heightError = validateCalculatorHeight(heightCmText);
    final ageError = validateCalculatorAge(ageYearsText);
    final goalSpeedError = goalMode == CalorieGoalMode.maintain
        ? null
        : validatePositiveCalculatorDouble(goalSpeedKgPerWeekText);
    final sexError = sex == null ? CalorieCalculatorFieldError.empty : null;
    final profile =
        sexError == null &&
            weightError == null &&
            heightError == null &&
            ageError == null &&
            targetWeightError == null &&
            goalSpeedError == null
        ? CalorieCalculatorProfile(
            sex: sex!,
            weightKg: parsePositiveCalculatorDouble(weightKgText)!,
            heightCm: parsePositiveCalculatorDouble(heightCmText)!,
            ageYears: parsePositiveCalculatorInt(ageYearsText)!,
            birthDate: birthDate,
            activityLevel: activityLevelOption.palValue,
            goalMode: goalMode,
            goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
                ? 0
                : parsePositiveCalculatorDouble(goalSpeedKgPerWeekText)!,
            targetWeightKg: goalMode == CalorieGoalMode.maintain
                ? null
                : parsePositiveCalculatorDouble(targetWeightKgText),
            trainingWeekdays: trainingWeekdays,
            trainingDayKcalOffset: trainingDayKcalOffset,
          )
        : null;

    return CalorieGoalCalculatorFormState(
      sex: sex,
      birthDate: birthDate,
      weightKgText: weightKgText,
      targetWeightKgText: targetWeightKgText,
      heightCmText: heightCmText,
      ageYearsText: ageYearsText,
      activityLevelOption: activityLevelOption,
      goalMode: goalMode,
      goalSpeedKgPerWeekText: goalSpeedKgPerWeekText,
      lastNonMaintainGoalSpeedText: lastNonMaintainGoalSpeedText,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
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

  /// The birth date, when the user picked one.
  final DateTime? birthDate;

  /// The weight kg text.
  final String weightKgText;

  /// The target weight kg text.
  final String targetWeightKgText;

  /// The height cm text.
  final String heightCmText;

  /// The age years text.
  final String ageYearsText;

  /// Days of the week for workouts.
  final List<int> trainingWeekdays;

  /// Kcal offset for workout days.
  final double trainingDayKcalOffset;

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
    final weightKg = parsePositiveCalculatorDouble(weightKgText);
    final heightCm = parsePositiveCalculatorDouble(heightCmText);
    final ageYears = parsePositiveCalculatorInt(ageYearsText);
    final goalSpeedKgPerWeek = isMaintainMode
        ? 0.0
        : parsePositiveCalculatorDouble(goalSpeedKgPerWeekText);
    final targetWeightKg = isMaintainMode
        ? null
        : parsePositiveCalculatorDouble(targetWeightKgText);

    if (sex == null ||
        weightKg == null ||
        heightCm == null ||
        ageYears == null ||
        goalSpeedKgPerWeek == null ||
        (!isMaintainMode && targetWeightKg == null)) {
      return null;
    }

    return CalorieCalculatorProfile(
      sex: sex!,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      birthDate: birthDate,
      activityLevel: activityLevelOption.palValue,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      targetWeightKg: targetWeightKg,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
    );
  }

  /// Copy with.
  CalorieGoalCalculatorFormState copyWith({
    CalorieCalculatorSex? sex,
    DateTime? birthDate,
    String? weightKgText,
    String? targetWeightKgText,
    String? heightCmText,
    String? ageYearsText,
    CalorieActivityLevelOption? activityLevelOption,
    CalorieGoalMode? goalMode,
    String? goalSpeedKgPerWeekText,
    String? lastNonMaintainGoalSpeedText,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
    bool? isSaving,
  }) {
    return CalorieGoalCalculatorFormState._create(
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
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
      trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
      trainingDayKcalOffset:
          trainingDayKcalOffset ?? this.trainingDayKcalOffset,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
