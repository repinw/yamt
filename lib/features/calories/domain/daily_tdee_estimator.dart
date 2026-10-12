import 'dart:math' as math;

/// One day of input for [DailyTdeeEstimator]: the logged intake and the
/// weight of that day, each null when missing.
typedef DailyTdeeInput = ({double? intakeKcal, double? weightKg});

/// The TDEE estimate of one day.
class DailyTdeeEstimate {
  /// Creates a daily TDEE estimate.
  const new({
    required this.tdeeKcal,
    required this.measuredTdeeKcal,
    required this.isHolding,
  });

  /// The smoothed TDEE after the ramp-up, the daily cap, and the floor.
  final double tdeeKcal;

  /// The TDEE that the smoothed intake and weight trend of this day imply, or
  /// null on a day without logged intake.
  final double? measuredTdeeKcal;

  /// Whether too few logged days kept the estimate where it was.
  final bool isHolding;
}

/// Estimates TDEE every day from smoothed intake and weight trend:
/// TDEE = smoothed intake - weight trend (kg/day) x 7700.
abstract final class DailyTdeeEstimator {
  /// Share of a new weigh-in in the weight level.
  static const weightLevelAlpha = 0.25;

  /// Share of a new level change in the weight trend.
  static const weightTrendBeta = 0.06;

  /// Share of a new day in the smoothed intake.
  static const intakeGamma = 0.15;

  /// Energy of one kilogram of body weight.
  static const kcalPerKilogram = 7700.0;

  /// The largest change from one day to the next after the ramp-up.
  static const double maxDailyChangeKcal = 150 / 7;

  /// The estimate holds when this many of the last 7 days have no intake.
  static const holdMissingIntakeDays = 4;

  static const _minimumWeightKg = 25.0;
  static const _maximumIntakeKcal = 50000.0;

  /// Returns one estimate per entry of [days], starting from [seedKcal].
  ///
  /// The first 6 updates move a third of the way to the measured value,
  /// updates 6 to 12 two thirds, update 13 all of it; later ones move at most
  /// [maxDailyChangeKcal]. A day without intake counts with the intake that
  /// yesterday's TDEE and the weight trend imply.
  static List<DailyTdeeEstimate> estimate({
    required double seedKcal,
    required double floorKcal,
    required List<DailyTdeeInput> days,
  }) {
    final estimates = <DailyTdeeEstimate>[];
    final loggedDays = <bool>[];
    var tdee = math.max(seedKcal, floorKcal);
    double? level;
    var trend = 0.0;
    double? intake;
    var updates = 0;
    for (final day in days) {
      final weight = day.weightKg;
      if (weight != null && weight >= _minimumWeightKg) {
        if (level == null) {
          level = weight;
        } else {
          final predicted = level + trend;
          final newLevel = predicted + weightLevelAlpha * (weight - predicted);
          trend += weightTrendBeta * (newLevel - level - trend);
          level = newLevel;
        }
      } else if (level != null) {
        level += trend;
      }

      final logged = day.intakeKcal;
      final isLogged =
          logged != null && logged > 0 && logged < _maximumIntakeKcal;
      loggedDays.add(isLogged);
      final dayIntake = isLogged
          ? logged
          : (intake == null ? null : tdee + trend * kcalPerKilogram);
      if (dayIntake != null) {
        intake = intake == null
            ? dayIntake
            : intake + intakeGamma * (dayIntake - intake);
      }

      final recentMissing = loggedDays
          .skip(math.max(0, loggedDays.length - 7))
          .where((logged) => !logged)
          .length;
      final isHolding = recentMissing >= holdMissingIntakeDays;
      final measured = intake == null ? null : intake - trend * kcalPerKilogram;
      if (measured != null && !isHolding) {
        tdee = math.max(floorKcal, tdee + _step(updates, measured - tdee));
        updates++;
      }
      estimates.add(
        DailyTdeeEstimate(
          tdeeKcal: tdee,
          measuredTdeeKcal: isLogged ? measured : null,
          isHolding: isHolding,
        ),
      );
    }
    return List<DailyTdeeEstimate>.unmodifiable(estimates);
  }

  static double _step(int update, double gapKcal) {
    if (update < 6) {
      return 0.33 * gapKcal;
    }
    if (update < 13) {
      return 0.66 * gapKcal;
    }
    if (update == 13) {
      return gapKcal;
    }
    return gapKcal.clamp(-maxDailyChangeKcal, maxDailyChangeKcal);
  }
}
