import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';

/// The minimum calorie goal kcal.
const double minimumCalorieGoalKcal = minimumDailyCalorieBudgetKcal;
const _kcalPerKilogram = 7000.0;
const _daysPerWeek = 7.0;
const _calculatorLogName = 'CalorieGoalCalculator';

/// Defines calorie goal calculation result.
class CalorieGoalCalculationResult {
  /// The calorie goal calculation result.
  const CalorieGoalCalculationResult({
    required this.bmrKcal,
    required this.tdeeKcal,
    required this.expectedActivityKcal,
    required this.dailyAdjustmentKcal,
    required this.finalGoalKcal,
    required this.wasClampedToMinimum,
  });

  /// The bmr kcal.
  final double bmrKcal;

  /// The tdee kcal.
  final double tdeeKcal;

  /// Expected daily activity kcal from PAL.
  final double expectedActivityKcal;

  /// The daily adjustment kcal.
  final double dailyAdjustmentKcal;

  /// The final goal kcal.
  final double finalGoalKcal;

  /// Whether clamped to minimum.
  final bool wasClampedToMinimum;
}

/// Defines calorie goal calculator.
abstract final class CalorieGoalCalculator {
  /// Calculate.
  static CalorieGoalCalculationResult calculate(
    CalorieCalculatorProfile profile,
  ) {
    final bmrKcal = _calculateBmr(profile);
    final tdeeKcal = bmrKcal * profile.activityLevel;
    final expectedActivityKcal = tdeeKcal - bmrKcal;
    final goalSpeedKgPerWeek = profile.goalMode == CalorieGoalMode.maintain
        ? 0.0
        : profile.goalSpeedKgPerWeek;
    final dailyAdjustmentKcal =
        (goalSpeedKgPerWeek * _kcalPerKilogram) / _daysPerWeek;
    final adjustedGoalKcal = switch (profile.goalMode) {
      CalorieGoalMode.lose => tdeeKcal - dailyAdjustmentKcal,
      CalorieGoalMode.maintain => tdeeKcal,
      CalorieGoalMode.gain => tdeeKcal + dailyAdjustmentKcal,
    };
    final wasClampedToMinimum =
        profile.goalMode == CalorieGoalMode.lose &&
        adjustedGoalKcal < minimumCalorieGoalKcal;

    final result = CalorieGoalCalculationResult(
      bmrKcal: bmrKcal,
      tdeeKcal: tdeeKcal,
      expectedActivityKcal: expectedActivityKcal,
      dailyAdjustmentKcal: dailyAdjustmentKcal,
      finalGoalKcal: wasClampedToMinimum
          ? minimumCalorieGoalKcal
          : adjustedGoalKcal,
      wasClampedToMinimum: wasClampedToMinimum,
    );
    if (!kReleaseMode) {
      final message =
          'CALC_RESULT_DEBUG '
          'sex=${profile.sex.name} '
          'weightKg=${_format(profile.weightKg)} '
          'heightCm=${_format(profile.heightCm)} '
          'ageYears=${profile.ageYears} '
          'activityLevel=${_format(profile.activityLevel)} '
          'goalMode=${profile.goalMode.name} '
          'goalSpeedKgPerWeek=${_format(profile.goalSpeedKgPerWeek)} '
          '-> bmrKcal=${_format(result.bmrKcal)} '
          'tdeeKcal=${_format(result.tdeeKcal)} '
          'expectedActivityKcal=${_format(result.expectedActivityKcal)} '
          'dailyAdjustmentKcal=${_format(result.dailyAdjustmentKcal)} '
          'finalGoalKcal=${_format(result.finalGoalKcal)} '
          'wasClampedToMinimum=${result.wasClampedToMinimum}';
      log(message, name: _calculatorLogName);
    }
    return result;
  }

  static double _calculateBmr(CalorieCalculatorProfile profile) {
    final base =
        (10 * profile.weightKg) +
        (6.25 * profile.heightCm) -
        (5 * profile.ageYears);
    return switch (profile.sex) {
      CalorieCalculatorSex.male => base + 5,
      CalorieCalculatorSex.female => base - 161,
    };
  }

  static String _format(double value) {
    return value.toStringAsFixed(2);
  }
}
