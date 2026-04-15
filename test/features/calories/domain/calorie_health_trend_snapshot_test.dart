import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

void main() {
  test('snapshot getters reflect plotted health and intake data', () {
    final snapshot = CalorieHealthTrendSnapshot(
      points: [
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 14),
          intakeKcal: 0,
          burnedKcal: null,
          weightKg: null,
          weightSource: CalorieHealthTrendWeightSource.none,
        ),
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 15),
          intakeKcal: 1900,
          burnedKcal: 420,
          weightKg: 71.2,
          weightSource: CalorieHealthTrendWeightSource.health,
        ),
      ],
      healthAccessState: HealthDataAccessState.ready,
      healthPlatform: HealthPlatform.android,
    );

    expect(snapshot.hasAnyChartData, isTrue);
    expect(snapshot.hasHealthSeries, isTrue);
    expect(snapshot.plottedValues, [1900, 420, 71.2]);
  });

  test('snapshot getters report empty series when only zero intake exists', () {
    final snapshot = CalorieHealthTrendSnapshot(
      points: [
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 14),
          intakeKcal: 0,
          burnedKcal: null,
          weightKg: null,
          weightSource: CalorieHealthTrendWeightSource.none,
        ),
      ],
      healthAccessState: HealthDataAccessState.permissionRequired,
      healthPlatform: HealthPlatform.android,
    );

    expect(snapshot.hasAnyChartData, isFalse);
    expect(snapshot.hasHealthSeries, isFalse);
    expect(snapshot.plottedValues, isEmpty);
  });
}
