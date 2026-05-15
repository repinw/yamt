import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

/// Calculator values shown in the first diary intro.
@immutable
class DiaryIntroData {
  /// Creates intro data.
  const DiaryIntroData({
    required this.goalMode,
    required this.maintenanceKcal,
    required this.dailyAdjustmentKcal,
    required this.targetKcal,
    required this.goalSpeedKgPerWeek,
    required this.activityLevelOption,
    required this.expectedActivityKcal,
  });

  /// Creates intro data from current calorie settings.
  factory DiaryIntroData.fromSettings(CalorieGoalSettings settings) {
    final entry = settings.latestGoalEntry;
    final profile = entry?.calculatorProfile ?? settings.calculatorProfile;
    final targetKcal = entry?.dailyKcalGoal ?? settings.dailyKcalGoal;
    if (profile == null || targetKcal == null) {
      throw ArgumentError('Diary intro needs calculator profile and target.');
    }
    final calculation = CalorieGoalCalculator.calculate(profile);
    return DiaryIntroData(
      goalMode: profile.goalMode,
      maintenanceKcal: calculation.tdeeKcal.round(),
      dailyAdjustmentKcal: calculation.dailyAdjustmentKcal.round(),
      targetKcal: targetKcal.round(),
      goalSpeedKgPerWeek: profile.goalSpeedKgPerWeek,
      activityLevelOption: CalorieActivityLevelOption.fromActivityLevel(
        profile.activityLevel,
      ),
      expectedActivityKcal: calculation.expectedActivityKcal.round(),
    );
  }

  /// Whether settings can build intro data.
  static bool canBuildFrom(CalorieGoalSettings settings) {
    final entry = settings.latestGoalEntry;
    final profile = entry?.calculatorProfile ?? settings.calculatorProfile;
    final targetKcal = entry?.dailyKcalGoal ?? settings.dailyKcalGoal;
    return profile != null && targetKcal != null;
  }

  /// Goal mode.
  final CalorieGoalMode goalMode;

  /// Estimated maintenance calories.
  final int maintenanceKcal;

  /// Daily goal adjustment from weekly speed.
  final int dailyAdjustmentKcal;

  /// Initial daily target.
  final int targetKcal;

  /// Selected weekly speed.
  final double goalSpeedKgPerWeek;

  /// Selected activity profile.
  final CalorieActivityLevelOption activityLevelOption;

  /// Expected daily activity calories.
  final int expectedActivityKcal;
}
