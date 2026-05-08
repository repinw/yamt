import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';

/// Maximum kcal cap relative to the daily goal. Prevents absurd estimates
/// (e.g. early-day "high" selections) from producing more than 1.4x of the
/// user's daily calorie goal.
const double _maxKcalCapMultiplier = 1.4;

/// Modifier multipliers applied to the time-based expected kcal.
const Map<CalorieGoalOnboardingCatchUpEstimate, double> _modifierByEstimate = {
  CalorieGoalOnboardingCatchUpEstimate.low: 0.55,
  CalorieGoalOnboardingCatchUpEstimate.normal: 1.0,
  CalorieGoalOnboardingCatchUpEstimate.high: 1.30,
};

/// Returns the realistic fraction of the daily kcal goal that an average
/// person should have consumed by the given hour-of-day.
///
/// Profile (cumulative meal intake over the day):
///   before 7:00     → 0%   (sleep / pre-breakfast)
///   7:00 – 11:00    → up to 25% (breakfast)
///   11:00 – 15:00   → up to 55% (+ lunch)
///   15:00 – 19:00   → up to 70% (+ snack)
///   19:00 – 22:00   → up to 95% (+ dinner)
///   after 22:00     → 95%
double _expectedDailyFraction(double hourOfDay) {
  if (hourOfDay < 7) {
    return 0;
  }
  if (hourOfDay < 11) {
    return 0.25 * ((hourOfDay - 7) / 4);
  }
  if (hourOfDay < 15) {
    return 0.25 + 0.30 * ((hourOfDay - 11) / 4);
  }
  if (hourOfDay < 19) {
    return 0.55 + 0.15 * ((hourOfDay - 15) / 4);
  }
  if (hourOfDay < 22) {
    return 0.70 + 0.25 * ((hourOfDay - 19) / 3);
  }
  return 0.95;
}

/// Calculates the estimated kcal the user has already consumed today,
/// based on their daily kcal goal, the current time-of-day, and their
/// catch-up estimate selection (low / normal / high).
///
/// The result is capped at [_maxKcalCapMultiplier] times [dailyGoalKcal]
/// and floored at 0.
double calculateOnboardingCatchUpKcal({
  required double dailyGoalKcal,
  required DateTime now,
  required CalorieGoalOnboardingCatchUpEstimate estimate,
}) {
  if (dailyGoalKcal <= 0) {
    return 0;
  }
  final hourOfDay = now.hour + now.minute / 60.0;
  final expectedFraction = _expectedDailyFraction(hourOfDay);
  final expectedKcal = dailyGoalKcal * expectedFraction;
  final modifier = _modifierByEstimate[estimate] ?? 1.0;
  final raw = expectedKcal * modifier;
  final cap = dailyGoalKcal * _maxKcalCapMultiplier;
  if (raw > cap) {
    return cap;
  }
  if (raw < 0) {
    return 0;
  }
  return raw;
}

/// Distributes a total kcal value across the [MealType]s that should
/// already have happened by the given time-of-day.
///
/// Returns a map containing only meals with a positive kcal share.
/// The values sum (approximately) to [totalKcal].
///
/// Distribution per time-of-day:
///   before 11:00:   100% breakfast
///   11:00 – 16:00:  40% breakfast, 60% lunch
///   16:00 – 19:00:  30% breakfast, 45% lunch, 25% snack
///   after 19:00:    25% breakfast, 35% lunch, 15% snack, 25% dinner
Map<MealType, double> distributeKcalAcrossMeals({
  required double totalKcal,
  required DateTime now,
}) {
  if (totalKcal <= 0) {
    return const <MealType, double>{};
  }
  final hourOfDay = now.hour + now.minute / 60.0;
  final Map<MealType, double> shares;
  if (hourOfDay < 11) {
    shares = const <MealType, double>{MealType.breakfast: 1.0};
  } else if (hourOfDay < 16) {
    shares = const <MealType, double>{
      MealType.breakfast: 0.40,
      MealType.lunch: 0.60,
    };
  } else if (hourOfDay < 19) {
    shares = const <MealType, double>{
      MealType.breakfast: 0.30,
      MealType.lunch: 0.45,
      MealType.snack: 0.25,
    };
  } else {
    shares = const <MealType, double>{
      MealType.breakfast: 0.25,
      MealType.lunch: 0.35,
      MealType.snack: 0.15,
      MealType.dinner: 0.25,
    };
  }
  final result = <MealType, double>{};
  for (final entry in shares.entries) {
    final value = totalKcal * entry.value;
    if (value > 0) {
      result[entry.key] = value;
    }
  }
  return result;
}

/// Returns a typical mid-time for a given meal on the same calendar day
/// as [referenceDate]. Useful as `loggedAt` value when creating
/// onboarding placeholder entries so they sort naturally.
DateTime mealMidpointForDay(MealType mealType, DateTime referenceDate) {
  final hour = switch (mealType) {
    MealType.breakfast => 8,
    MealType.lunch => 13,
    MealType.snack => 16,
    MealType.dinner => 19,
  };
  return DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
    hour,
  );
}
