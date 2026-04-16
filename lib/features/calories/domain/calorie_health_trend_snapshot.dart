import 'package:yamt/features/health/domain/health_connection_models.dart';

/// Defines calorie health trend weight source.
enum CalorieHealthTrendWeightSource {
  /// None.
  none,

  /// Health.
  health,

  /// Manual.
  manual,
}

/// Defines calorie health trend point.
class CalorieHealthTrendPoint {
  /// The calorie health trend point.
  const CalorieHealthTrendPoint({
    required this.day,
    required this.intakeKcal,
    required this.burnedKcal,
    required this.weightKg,
    required this.weightSource,
  });

  /// The day.
  final DateTime day;

  /// The intake kcal.
  final double intakeKcal;

  /// The burned kcal.
  final int? burnedKcal;

  /// The weight kg.
  final double? weightKg;

  /// The weight source.
  final CalorieHealthTrendWeightSource weightSource;
}

/// Defines calorie health trend snapshot.
class CalorieHealthTrendSnapshot {
  /// The calorie health trend snapshot.
  const CalorieHealthTrendSnapshot({
    required this.points,
    required this.healthAccessState,
    required this.healthPlatform,
  });

  /// The points.
  final List<CalorieHealthTrendPoint> points;

  /// The health access state.
  final HealthDataAccessState healthAccessState;

  /// The health platform.
  final HealthPlatform healthPlatform;

  /// Whether any chart data.
  bool get hasAnyChartData {
    return points.any((point) {
      return point.intakeKcal > 0 ||
          point.burnedKcal != null ||
          point.weightKg != null;
    });
  }

  /// Whether health series.
  bool get hasHealthSeries {
    return points.any(
      (point) => point.burnedKcal != null || point.weightKg != null,
    );
  }

  /// The plotted values.
  Iterable<double> get plottedValues sync* {
    for (final point in points) {
      if (point.intakeKcal > 0) {
        yield point.intakeKcal;
      }
      final burnedKcal = point.burnedKcal;
      if (burnedKcal != null) {
        yield burnedKcal.toDouble();
      }
      final weightKg = point.weightKg;
      if (weightKg != null) {
        yield weightKg;
      }
    }
  }
}
