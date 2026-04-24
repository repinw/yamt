import 'dart:math' as math;

/// Fraction of above-baseline tracker activity granted as eatable calories.
const activityCreditFactor = 0.5;

/// Calculates signed activity against an expected baseline.
double calculateLearnedActivityComparisonKcal({
  required int todayActiveKcal,
  required double averageActiveKcal,
}) {
  return todayActiveKcal - averageActiveKcal;
}

/// Calculates eatable activity above an expected baseline.
double calculateLearnedActivityBonusKcal({
  required int todayActiveKcal,
  required double averageActiveKcal,
}) {
  final rawExtraActivityKcal = math.max<double>(
    0,
    calculateLearnedActivityComparisonKcal(
      todayActiveKcal: todayActiveKcal,
      averageActiveKcal: averageActiveKcal,
    ),
  );
  return rawExtraActivityKcal * activityCreditFactor;
}
