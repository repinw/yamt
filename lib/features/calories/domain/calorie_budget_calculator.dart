import 'dart:math' as math;

/// Minimum kcal used by every calorie budget calculation.
const minimumDailyCalorieBudgetKcal = 1200.0;

/// One finished day used for carryover math.
class CalorieCarryoverDay {
  /// Creates a carryover day.
  const CalorieCarryoverDay({
    required this.goalKcal,
    required this.consumedKcal,
  });

  /// The canonical goal for this day.
  final double goalKcal;

  /// Logged kcal for this day.
  final double consumedKcal;
}

/// Result for a stored goal after activity and minimum floor are applied.
class CalorieResolvedGoalBreakdown {
  /// Creates resolved goal breakdown.
  const CalorieResolvedGoalBreakdown({
    required this.storedGoalKcal,
    required this.activityDeltaKcal,
    required this.goalBeforeMinimumKcal,
    required this.goalKcal,
    required this.wasClampedToMinimum,
  });

  /// Goal saved in settings before daily activity adjustment.
  final double storedGoalKcal;

  /// Eatable daily activity kcal above expected activity.
  final double activityDeltaKcal;

  /// Goal before safety minimum.
  final double goalBeforeMinimumKcal;

  /// Goal after activity and safety minimum.
  final double goalKcal;

  /// Whether safety minimum changed the goal.
  final bool wasClampedToMinimum;
}

/// Classic tab budget after optional view toggles.
class CalorieClassicBudgetBreakdown {
  /// Creates classic budget breakdown.
  const CalorieClassicBudgetBreakdown({
    required this.baseGoalKcal,
    required this.activityDeltaKcal,
    required this.carryoverKcal,
    required this.consumedKcal,
    required this.includeActivityDelta,
    required this.includeCarryover,
    required this.goalBeforeMinimumKcal,
    required this.goalKcal,
    required this.remainingKcal,
    required this.wasClampedToMinimum,
  });

  /// Stored goal without today's activity delta.
  final double baseGoalKcal;

  /// Today's eatable activity kcal above expected activity.
  final double activityDeltaKcal;

  /// Canonical carryover from previous days.
  final double carryoverKcal;

  /// Logged kcal for selected day.
  final double consumedKcal;

  /// Whether Classic shows today's activity delta.
  final bool includeActivityDelta;

  /// Whether Classic shows canonical carryover.
  final bool includeCarryover;

  /// Goal before safety minimum.
  final double goalBeforeMinimumKcal;

  /// Final Classic goal shown in UI.
  final double goalKcal;

  /// Final Classic remaining kcal.
  final double remainingKcal;

  /// Whether safety minimum changed the goal.
  final bool wasClampedToMinimum;

  /// Activity delta included in Classic goal.
  double get includedActivityDeltaKcal =>
      includeActivityDelta ? activityDeltaKcal : 0.0;

  /// Carryover included in Classic goal.
  double get includedCarryoverKcal => includeCarryover ? carryoverKcal : 0.0;
}

/// Shared calorie budget math for Classic and Balance views.
abstract final class CalorieBudgetCalculator {
  /// Resolve stored daily goal with eatable activity and minimum floor.
  static CalorieResolvedGoalBreakdown resolveDailyGoal({
    required double storedGoalKcal,
    required double activityDeltaKcal,
  }) {
    if (storedGoalKcal <= 0) {
      return CalorieResolvedGoalBreakdown(
        storedGoalKcal: storedGoalKcal,
        activityDeltaKcal: 0,
        goalBeforeMinimumKcal: storedGoalKcal,
        goalKcal: storedGoalKcal,
        wasClampedToMinimum: false,
      );
    }

    final goalBeforeMinimumKcal = storedGoalKcal + activityDeltaKcal;
    final goalKcal = math.max<double>(
      minimumDailyCalorieBudgetKcal,
      goalBeforeMinimumKcal,
    );
    return CalorieResolvedGoalBreakdown(
      storedGoalKcal: storedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
      goalBeforeMinimumKcal: goalBeforeMinimumKcal,
      goalKcal: goalKcal,
      wasClampedToMinimum: goalKcal != goalBeforeMinimumKcal,
    );
  }

  /// Calculate canonical carryover from finished days.
  static double calculateCarryover(Iterable<CalorieCarryoverDay> days) {
    return days.fold<double>(
      0,
      (sum, day) => sum + day.goalKcal - day.consumedKcal,
    );
  }

  /// Spread carryover across remaining days in the active goal run.
  static double distributeCarryover({
    required double carryoverKcal,
    required int remainingDays,
  }) {
    final resolvedRemainingDays = math.max(1, remainingDays);
    return carryoverKcal / resolvedRemainingDays;
  }

  /// Calculate Classic budget with optional activity and carryover toggles.
  static CalorieClassicBudgetBreakdown calculateClassicBudget({
    required double storedGoalKcal,
    required double activityDeltaKcal,
    required double carryoverKcal,
    required double consumedKcal,
    required bool includeActivityDelta,
    required bool includeCarryover,
  }) {
    final includedActivityDeltaKcal = includeActivityDelta
        ? activityDeltaKcal
        : 0.0;
    final includedCarryoverKcal = includeCarryover ? carryoverKcal : 0.0;
    final baseGoalBeforeMinimumKcal =
        storedGoalKcal + includedActivityDeltaKcal;
    final baseGoalKcal = storedGoalKcal <= 0
        ? storedGoalKcal
        : math.max<double>(
            minimumDailyCalorieBudgetKcal,
            baseGoalBeforeMinimumKcal,
          );
    final goalBeforeMinimumKcal =
        storedGoalKcal + includedActivityDeltaKcal + includedCarryoverKcal;
    final goalKcal = storedGoalKcal <= 0
        ? storedGoalKcal
        : baseGoalKcal + includedCarryoverKcal;
    return CalorieClassicBudgetBreakdown(
      baseGoalKcal: storedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
      carryoverKcal: carryoverKcal,
      consumedKcal: consumedKcal,
      includeActivityDelta: includeActivityDelta,
      includeCarryover: includeCarryover,
      goalBeforeMinimumKcal: goalBeforeMinimumKcal,
      goalKcal: goalKcal,
      remainingKcal: goalKcal - consumedKcal,
      wasClampedToMinimum:
          storedGoalKcal > 0 && baseGoalKcal != baseGoalBeforeMinimumKcal,
    );
  }

  /// Calculate full-day budget with every automatic adjustment included.
  static CalorieClassicBudgetBreakdown calculateFullDayBudget({
    required double storedGoalKcal,
    required double activityDeltaKcal,
    required double carryoverKcal,
    required double consumedKcal,
  }) {
    return calculateClassicBudget(
      storedGoalKcal: storedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
      carryoverKcal: carryoverKcal,
      consumedKcal: consumedKcal,
      includeActivityDelta: true,
      includeCarryover: true,
    );
  }
}
