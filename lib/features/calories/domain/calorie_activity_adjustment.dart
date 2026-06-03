import 'dart:math' as math;

/// Fraction of imported activity calories trusted by calorie math.
const importedActivityCorrectionFactor = 0.75;

/// Corrected activity calories for one day.
class CalorieActivityCreditBreakdown {
  /// Creates a calorie activity credit breakdown.
  const CalorieActivityCreditBreakdown({
    required this.rawActivityKcal,
    required this.correctedActivityKcal,
    required this.activityCapKcal,
    required this.creditedActivityKcal,
    required this.wasCapped,
  });

  /// Imported activity kcal before correction.
  final double rawActivityKcal;

  /// Activity kcal after tracker correction.
  final double correctedActivityKcal;

  /// Maximum kcal accepted for the day, currently equal to corrected kcal.
  final double activityCapKcal;

  /// Final eatable activity kcal.
  final double creditedActivityKcal;

  /// Whether [activityCapKcal] lowered the final credit.
  final bool wasCapped;
}

/// Calculates corrected activity credit for one day.
CalorieActivityCreditBreakdown calculateActivityCredit({
  required num rawActivityKcal,
}) {
  final resolvedRawActivityKcal = math.max<double>(
    0,
    rawActivityKcal.toDouble(),
  );
  final correctedActivityKcal =
      resolvedRawActivityKcal * importedActivityCorrectionFactor;
  return CalorieActivityCreditBreakdown(
    rawActivityKcal: resolvedRawActivityKcal,
    correctedActivityKcal: correctedActivityKcal,
    activityCapKcal: correctedActivityKcal,
    creditedActivityKcal: correctedActivityKcal,
    wasCapped: false,
  );
}

/// Calculates only final credited activity kcal.
double calculateActivityCreditKcal({
  required num rawActivityKcal,
}) {
  return calculateActivityCredit(
    rawActivityKcal: rawActivityKcal,
  ).creditedActivityKcal;
}

/// Removes expected activity credit from a Total-TDEE based goal.
double calculateActivityAdjustedBaseGoalKcal({
  required double totalGoalKcal,
  required double? expectedActivityKcal,
  required bool isActivityTrackingActive,
}) {
  if (!isActivityTrackingActive || expectedActivityKcal == null) {
    return totalGoalKcal;
  }
  return totalGoalKcal -
      calculateActivityCreditKcal(rawActivityKcal: expectedActivityKcal);
}

/// Solves Base-TDEE after subtracting corrected activity.
double calculateMeasuredBaseTdeeKcal({
  required double measuredTotalTdeeKcal,
  required Iterable<int> rawActivityKcalByDay,
}) {
  final averageCreditedActivityKcal = calculateAverageActivityCreditKcal(
    rawActivityKcalByDay: rawActivityKcalByDay,
  );
  return measuredTotalTdeeKcal - averageCreditedActivityKcal;
}

/// Calculates average corrected activity kcal.
double calculateAverageActivityCreditKcal({
  required Iterable<int> rawActivityKcalByDay,
}) {
  final rawActivityKcals = rawActivityKcalByDay.toList(growable: false);
  if (rawActivityKcals.isEmpty) {
    return 0;
  }
  final total = rawActivityKcals.fold<double>(
    0,
    (sum, rawActivityKcal) =>
        sum +
        calculateActivityCreditKcal(
          rawActivityKcal: rawActivityKcal,
        ),
  );
  return total / rawActivityKcals.length;
}
