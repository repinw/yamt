import 'dart:math' as math;

import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

/// Fallback goal used when no diary goal is available.
const double burnWeekMockFallbackGoalKcal = 1400;

/// Total debug seconds in one Burn Week mock cycle.
const int burnWeekMockSecondsPerWeek = burnWeekDaysPerWeek * _secondsPerDay;

const int _secondsPerDay = 24 * 60 * 60;

/// Difficulty tier for Burn Week mock progression.
class BurnWeekMockDifficulty {
  /// Creates Burn Week mock difficulty.
  const BurnWeekMockDifficulty({
    required this.label,
    required this.minimumHearts,
    required this.safeZoneMultiplier,
  });

  /// User-facing tier label.
  final String label;

  /// Minimum hearts restored at week start or after star break.
  final int minimumHearts;

  /// Multiplier applied to one-day safe-zone width.
  final double safeZoneMultiplier;
}

/// Burn Week zone state for current metrics.
enum BurnWeekZoneStatus {
  /// Actual sits inside safe zone.
  inside,

  /// Actual sits left of safe zone and needs more kcal.
  below,

  /// Actual sits right of safe zone and needs less kcal.
  above,
}

/// Next game-loop step when user leaves safe zone.
enum BurnWeekZoneDecisionType {
  /// No dialog or correction needed.
  inside,

  /// User can recover by eating more or spending one heart.
  belowCanEatOrUseHeart,

  /// User can no longer recover by eating alone.
  belowNeedsHeart,

  /// Fasting alone can still recover this week.
  aboveFastOnly,

  /// User is beyond weekly limit and needs one heart.
  aboveNeedsHeart,
}

/// Pure game-loop decision from current Burn Week state.
class BurnWeekZoneDecision {
  /// Creates Burn Week zone decision.
  const BurnWeekZoneDecision({
    required this.type,
    required this.status,
  });

  /// Decision type for UI flow.
  final BurnWeekZoneDecisionType type;

  /// Coarse zone status.
  final BurnWeekZoneStatus status;
}

/// Result after spending one Burn Week heart.
class BurnWeekHeartSpendResult {
  /// Creates Burn Week heart spend result.
  const BurnWeekHeartSpendResult({
    required this.starCount,
    required this.heartCount,
    required this.heartCreditKcal,
    required this.didBreakStar,
    required this.didResetRun,
  });

  /// Next star count.
  final int starCount;

  /// Next heart count.
  final int heartCount;

  /// Next signed heart kcal credit.
  final double heartCreditKcal;

  /// Whether one star broke during this spend.
  final bool didBreakStar;

  /// Whether run must reset.
  final bool didResetRun;
}

/// Pure view data for Burn Week mock calculations.
class BurnWeekMockMetrics {
  /// Creates calculated Burn Week mock metrics.
  const BurnWeekMockMetrics({
    required this.dailyGoalKcal,
    required this.weeklyGoalKcal,
    required this.usesFallbackGoal,
    required this.paceRatio,
    required this.targetKcal,
    required this.consumedKcal,
    required this.safeZoneMinKcal,
    required this.safeZoneMaxKcal,
    required this.barMinKcal,
    required this.barMaxKcal,
    this.plannedLaterKcal = 0,
  });

  /// The resolved daily goal used by the mock.
  final double dailyGoalKcal;

  /// The resolved weekly goal used by the mock.
  final double weeklyGoalKcal;

  /// Whether fallback goal was used.
  final bool usesFallbackGoal;

  /// Week progress from `0` to `1`.
  final double paceRatio;

  /// Target calories for current time.
  final double targetKcal;

  /// Demo actual calories after button taps.
  final double consumedKcal;

  /// Safe-zone lower bound.
  final double safeZoneMinKcal;

  /// Safe-zone upper bound.
  final double safeZoneMaxKcal;

  /// Visible bar lower bound.
  final double barMinKcal;

  /// Visible bar upper bound.
  final double barMaxKcal;

  /// Planned kcal for later in same day, shown as shadow only.
  final double plannedLaterKcal;

  /// Target marker position inside visible bar.
  double get targetRatio => ratioForKcal(targetKcal);

  /// Heart marker position inside visible bar.
  double get consumedRatio => ratioForKcal(consumedKcal);

  /// Planned-shadow end position inside visible bar.
  double get plannedEndRatio => ratioForKcal(consumedKcal + plannedLaterKcal);

  /// Safe-zone start position inside visible bar.
  double get safeZoneStartRatio => ratioForKcal(safeZoneMinKcal);

  /// Safe-zone end position inside visible bar.
  double get safeZoneEndRatio => ratioForKcal(safeZoneMaxKcal);

  /// Maps kcal value into the visible bar range.
  double ratioForKcal(double value) {
    final span = barMaxKcal - barMinKcal;
    if (span <= 0) {
      return 0.5;
    }
    return ((value - barMinKcal) / span).clamp(0.0, 1.0);
  }
}

/// Resolves daily goal for Burn Week mock.
double resolveBurnWeekMockGoalKcal(double? goalKcal) {
  if (goalKcal == null || goalKcal <= 0) {
    return burnWeekMockFallbackGoalKcal;
  }
  return goalKcal;
}

/// Resolves whether the fallback goal is active.
bool usesBurnWeekMockFallbackGoal(double? goalKcal) {
  return goalKcal == null || goalKcal <= 0;
}

/// Resolves difficulty tier from current star count.
BurnWeekMockDifficulty resolveBurnWeekMockDifficulty(int starCount) {
  if (starCount >= 8) {
    return const BurnWeekMockDifficulty(
      label: 'Master',
      minimumHearts: 1,
      safeZoneMultiplier: 0.4,
    );
  }
  if (starCount >= 6) {
    return const BurnWeekMockDifficulty(
      label: 'Elite',
      minimumHearts: 2,
      safeZoneMultiplier: 0.55,
    );
  }
  if (starCount >= 4) {
    return const BurnWeekMockDifficulty(
      label: 'Solid',
      minimumHearts: 2,
      safeZoneMultiplier: 0.7,
    );
  }
  if (starCount >= 2) {
    return const BurnWeekMockDifficulty(
      label: 'Steady',
      minimumHearts: 3,
      safeZoneMultiplier: 0.85,
    );
  }
  return const BurnWeekMockDifficulty(
    label: 'Learning',
    minimumHearts: 3,
    safeZoneMultiplier: 1,
  );
}

/// Resolves zone state from current metrics.
BurnWeekZoneStatus resolveBurnWeekZoneStatus(BurnWeekMockMetrics metrics) {
  if (metrics.consumedKcal < metrics.safeZoneMinKcal) {
    return BurnWeekZoneStatus.below;
  }
  if (metrics.consumedKcal > metrics.safeZoneMaxKcal) {
    return BurnWeekZoneStatus.above;
  }
  return BurnWeekZoneStatus.inside;
}

/// Resolves full Burn Week decision for out-of-zone state.
BurnWeekZoneDecision resolveBurnWeekZoneDecision(BurnWeekMockMetrics metrics) {
  final status = resolveBurnWeekZoneStatus(metrics);
  switch (status) {
    case BurnWeekZoneStatus.inside:
      return const BurnWeekZoneDecision(
        type: BurnWeekZoneDecisionType.inside,
        status: BurnWeekZoneStatus.inside,
      );
    case BurnWeekZoneStatus.below:
      final underTargetKcal = metrics.targetKcal - metrics.consumedKcal;
      final remainingWeekKcal = metrics.weeklyGoalKcal - metrics.targetKcal;
      return BurnWeekZoneDecision(
        type: underTargetKcal > remainingWeekKcal
            ? BurnWeekZoneDecisionType.belowNeedsHeart
            : BurnWeekZoneDecisionType.belowCanEatOrUseHeart,
        status: BurnWeekZoneStatus.below,
      );
    case BurnWeekZoneStatus.above:
      return BurnWeekZoneDecision(
        type: metrics.consumedKcal > metrics.weeklyGoalKcal
            ? BurnWeekZoneDecisionType.aboveNeedsHeart
            : BurnWeekZoneDecisionType.aboveFastOnly,
        status: BurnWeekZoneStatus.above,
      );
  }
}

/// Whether current week earns one new star.
bool resolveBurnWeekEarnedStar({
  required int heartCount,
  required bool starBrokeThisWeek,
  required bool missedTrackingThisWeek,
}) {
  return heartCount > 0 && !starBrokeThisWeek && !missedTrackingThisWeek;
}

/// Resolves state transition after one heart spend.
BurnWeekHeartSpendResult resolveBurnWeekHeartSpend({
  required int starCount,
  required int heartCount,
  required double heartCreditKcal,
  required double kcalDelta,
}) {
  if (heartCount <= 0) {
    return BurnWeekHeartSpendResult(
      starCount: starCount,
      heartCount: heartCount,
      heartCreditKcal: heartCreditKcal,
      didBreakStar: false,
      didResetRun: false,
    );
  }

  final remainingHearts = heartCount - 1;
  final nextHeartCreditKcal = heartCreditKcal + kcalDelta;
  if (remainingHearts > 0) {
    return BurnWeekHeartSpendResult(
      starCount: starCount,
      heartCount: remainingHearts,
      heartCreditKcal: nextHeartCreditKcal,
      didBreakStar: false,
      didResetRun: false,
    );
  }

  if (starCount > 0) {
    final nextStarCount = starCount - 1;
    return BurnWeekHeartSpendResult(
      starCount: nextStarCount,
      heartCount: resolveBurnWeekMockDifficulty(
        nextStarCount,
      ).minimumHearts,
      heartCreditKcal: nextHeartCreditKcal,
      didBreakStar: true,
      didResetRun: false,
    );
  }

  return BurnWeekHeartSpendResult(
    starCount: 0,
    heartCount: 0,
    heartCreditKcal: nextHeartCreditKcal,
    didBreakStar: false,
    didResetRun: false,
  );
}

int _resolveClampedElapsedDebugSeconds(int elapsedDebugSeconds) {
  return elapsedDebugSeconds.clamp(0, burnWeekMockSecondsPerWeek);
}

/// Resolves cumulative elapsed debug days across the week.
double resolveBurnWeekMockElapsedDays(int elapsedDebugSeconds) {
  final clampedSeconds = elapsedDebugSeconds.clamp(
    0,
    burnWeekMockSecondsPerWeek,
  );
  return clampedSeconds / _secondsPerDay;
}

/// Resolves week progress from `0` to `1` in debug timeline.
double resolveBurnWeekMockPaceRatio(int elapsedDebugSeconds) {
  final clampedSeconds = _resolveClampedElapsedDebugSeconds(
    elapsedDebugSeconds,
  );
  return (clampedSeconds / burnWeekMockSecondsPerWeek).clamp(0.0, 1.0);
}

/// Resolves all visible Burn Week mock metrics for given state.
BurnWeekMockMetrics resolveBurnWeekMockMetrics({
  required int elapsedDebugSeconds,
  required double? goalKcal,
  required double consumedKcal,
  double safeZoneMultiplier = 1,
}) {
  final resolvedGoalKcal = resolveBurnWeekMockGoalKcal(goalKcal);
  final elapsedDays = resolveBurnWeekMockElapsedDays(elapsedDebugSeconds);
  final weeklyGoalKcal = resolvedGoalKcal * burnWeekDaysPerWeek;
  final paceRatio = resolveBurnWeekMockPaceRatio(elapsedDebugSeconds);
  final targetKcal = resolvedGoalKcal * elapsedDays;
  final safeZoneWidthKcal = resolvedGoalKcal * safeZoneMultiplier;
  final safeZoneMinKcal = targetKcal - safeZoneWidthKcal;
  final safeZoneMaxKcal = targetKcal + safeZoneWidthKcal;
  const barMinKcal = 0.0;
  final barMaxKcal = math.max(weeklyGoalKcal, resolvedGoalKcal);

  return BurnWeekMockMetrics(
    dailyGoalKcal: resolvedGoalKcal,
    weeklyGoalKcal: weeklyGoalKcal,
    usesFallbackGoal: usesBurnWeekMockFallbackGoal(goalKcal),
    paceRatio: paceRatio,
    targetKcal: targetKcal,
    consumedKcal: consumedKcal,
    safeZoneMinKcal: safeZoneMinKcal,
    safeZoneMaxKcal: safeZoneMaxKcal,
    barMinKcal: barMinKcal,
    barMaxKcal: barMaxKcal,
  );
}
