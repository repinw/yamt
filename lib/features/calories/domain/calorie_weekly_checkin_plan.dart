import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_progress.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';
import 'package:yamt/features/calories/domain/macro_day_targets.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/domain/training_week_goals.dart';

/// The measured side of a ready weekly check-in.
typedef CalorieWeeklyCheckInMeasurement = ({
  double tdeeKcal,
  double goalKcal,
  double averageIntakeKcal,
});

/// What the weekly check-in shows and sets for the next run.
@immutable
class CalorieWeeklyCheckInPlan {
  /// Creates the plan of a weekly check-in.
  const new({
    required this.reviewedRunNumber,
    required this.nextRunNumber,
    required this.reviewedDays,
    required this.previousTrainingDayCount,
    required this.nextRunDays,
    required this.suggestedTrainingDays,
    required this.pauseDays,
    required this.pastDays,
    required this.hasWeeklyTrainingSchedule,
    required this.sessionKcal,
    required this.previousTdeeKcal,
    required this.previousGoalKcal,
    required this.measurement,
    required this.progress,
    required this.profile,
    required this.macroSettings,
    required this.previousMacroWeightKg,
    required this.newMacroWeightKg,
    required this.isLosingWeight,
  });

  /// Number of the run that the check-in looks back on, if known.
  final int? reviewedRunNumber;

  /// Number of the run that the check-in plans, if known.
  final int? nextRunNumber;

  /// First and last day of the run that the check-in looks back on.
  final ({DateTime start, DateTime end}) reviewedDays;

  /// Training days of the reviewed run.
  final int previousTrainingDayCount;

  /// The seven days of the next run, first to last.
  final List<DateTime> nextRunDays;

  /// Days of the next run that train on the weekdays of the reviewed run.
  /// Past days keep their type.
  final Set<DateTime> suggestedTrainingDays;

  /// Days of the next run that are pause days. They cannot train.
  final Set<DateTime> pauseDays;

  /// Days of the next run before today, after a late check-in. They keep
  /// their type, because their calorie goals were already in use.
  final Set<DateTime> pastDays;

  /// Whether the goal has weekly training days. Like the diary targets, the
  /// macros then count training even in a run without a session.
  final bool hasWeeklyTrainingSchedule;

  /// Whether the planning may change the type of [day].
  bool canChangeDay(DateTime day) =>
      !pauseDays.contains(day) && !pastDays.contains(day);

  /// kcal of one training session.
  final double sessionKcal;

  /// TDEE before this check-in.
  final double previousTdeeKcal;

  /// Daily goal before this check-in.
  final double previousGoalKcal;

  /// Measured TDEE and goal, or `null` while the check-in lacks data.
  final CalorieWeeklyCheckInMeasurement? measurement;

  /// Weight and TDEE since the goal start, or `null` without an active goal.
  final CalorieGoalProgress? progress;

  /// Calculator profile for the macro weight.
  final CalorieCalculatorProfile? profile;

  /// Macro settings of the user.
  final MacroGoalSettings macroSettings;

  /// Weight that the macros counted against before this check-in.
  final double? previousMacroWeightKg;

  /// Trend weight that the macros count against after this check-in.
  final double? newMacroWeightKg;

  /// Whether the active goal loses weight.
  final bool isLosingWeight;

  /// Targets of the next run with [trainingDays] sessions, from the measured
  /// TDEE when [useMeasured] is set and a measurement exists.
  CalorieWeeklyCheckInTargets targetsFor({
    required bool useMeasured,
    required int trainingDays,
  }) {
    final measured = useMeasured ? measurement : null;
    final goalKcal = measured?.goalKcal ?? previousGoalKcal;
    final week = resolveTrainingWeekGoals(
      baseGoalKcal: goalKcal,
      trainingDays: trainingDays,
      sessionKcal: sessionKcal,
    );
    return CalorieWeeklyCheckInTargets(
      goalKcal: goalKcal,
      previousGoalKcal: previousGoalKcal,
      isMeasured: measured != null,
      trainingDayKcal: week.trainingDayKcal,
      restDayKcal: week.restDayKcal,
      macros: _macros(
        goalKcal: goalKcal,
        macroWeightKg: newMacroWeightKg ?? previousMacroWeightKg,
        hasTrainingDays: hasWeeklyTrainingSchedule || trainingDays > 0,
      ),
      previousMacros: _macros(
        goalKcal: previousGoalKcal,
        macroWeightKg: previousMacroWeightKg,
        hasTrainingDays:
            hasWeeklyTrainingSchedule || previousTrainingDayCount > 0,
      ),
      macroWeightKg: macroCountedWeightKg(
        profile: profile,
        macroWeightKg: newMacroWeightKg ?? previousMacroWeightKg,
      ),
    );
  }

  MacroCalculationResult _macros({
    required double goalKcal,
    required double? macroWeightKg,
    required bool hasTrainingDays,
  }) {
    return resolveMacroDayTargets(
      macroSettings: macroSettings,
      profile: profile,
      macroWeightKg: macroWeightKg,
      goalKcal: goalKcal,
      baseGoalKcal: goalKcal,
      hasTrainingDays: hasTrainingDays,
      isLosingWeight: isLosingWeight,
    );
  }
}

/// Daily targets of the next run.
@immutable
class CalorieWeeklyCheckInTargets {
  /// Creates the targets of the next run.
  const new({
    required this.goalKcal,
    required this.previousGoalKcal,
    required this.isMeasured,
    required this.trainingDayKcal,
    required this.restDayKcal,
    required this.macros,
    required this.previousMacros,
    required this.macroWeightKg,
  });

  /// Average daily goal of the run.
  final double goalKcal;

  /// Daily goal before the check-in.
  final double previousGoalKcal;

  /// Whether [goalKcal] comes from the measured TDEE.
  final bool isMeasured;

  /// Goal of a training day.
  final double trainingDayKcal;

  /// Goal of a rest day.
  final double restDayKcal;

  /// Macros of an average day of the run.
  final MacroCalculationResult macros;

  /// Macros of an average day before the check-in.
  final MacroCalculationResult previousMacros;

  /// Weight that protein and fat count against.
  final double macroWeightKg;

  /// Change of the daily goal against the previous one.
  double get goalChangeKcal => goalKcal - previousGoalKcal;
}
