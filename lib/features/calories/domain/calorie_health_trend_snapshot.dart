import 'package:yamt/features/health/domain/health_connection_models.dart';

enum CalorieHealthTrendWeightSource { none, health, manual }

class CalorieHealthTrendPoint {
  const CalorieHealthTrendPoint({
    required this.day,
    required this.intakeKcal,
    required this.burnedKcal,
    required this.weightKg,
    required this.weightSource,
  });

  final DateTime day;
  final double intakeKcal;
  final int? burnedKcal;
  final double? weightKg;
  final CalorieHealthTrendWeightSource weightSource;
}

class CalorieHealthTrendSnapshot {
  const CalorieHealthTrendSnapshot({
    required this.points,
    required this.healthAccessState,
    required this.healthPlatform,
  });

  final List<CalorieHealthTrendPoint> points;
  final HealthDataAccessState healthAccessState;
  final HealthPlatform healthPlatform;

  bool get hasAnyChartData {
    return points.any((point) {
      return point.intakeKcal > 0 ||
          point.burnedKcal != null ||
          point.weightKg != null;
    });
  }

  bool get hasHealthSeries {
    return points.any(
      (point) => point.burnedKcal != null || point.weightKg != null,
    );
  }

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
