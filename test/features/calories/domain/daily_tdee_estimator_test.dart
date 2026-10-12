import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/daily_tdee_estimator.dart';

List<DailyTdeeInput> _steadyDays({
  required int count,
  required double intakeKcal,
  required double startWeightKg,
  double weightChangePerDay = 0,
}) {
  return [
    for (var day = 0; day < count; day++)
      (
        intakeKcal: intakeKcal,
        weightKg: startWeightKg + weightChangePerDay * day,
      ),
  ];
}

void main() {
  test('converges to intake when the weight stays flat', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2000,
      floorKcal: 750,
      days: _steadyDays(count: 60, intakeKcal: 2500, startWeightKg: 80),
    );

    expect(estimates.last.tdeeKcal, closeTo(2500, 1));
    expect(estimates.last.isHolding, isFalse);
  });

  test('adds the energy of a steady loss to the intake', () {
    // 0.5 kg per week less: 550 kcal per day above intake.
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2500,
      floorKcal: 750,
      days: _steadyDays(
        count: 120,
        intakeKcal: 2000,
        startWeightKg: 90,
        weightChangePerDay: -0.5 / 7,
      ),
    );

    expect(estimates.last.tdeeKcal, closeTo(2550, 15));
  });

  test('moves a third of the gap in the first days', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2000,
      floorKcal: 750,
      days: _steadyDays(count: 1, intakeKcal: 2600, startWeightKg: 80),
    );

    expect(estimates.single.tdeeKcal, closeTo(2000 + 0.33 * 600, 0.001));
  });

  test('caps the daily change at 150 kcal per week after day 13', () {
    final days = [
      ..._steadyDays(count: 30, intakeKcal: 2500, startWeightKg: 80),
      ..._steadyDays(count: 1, intakeKcal: 4000, startWeightKg: 80),
    ];
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2500,
      floorKcal: 750,
      days: days,
    );

    final change = estimates.last.tdeeKcal - estimates[29].tdeeKcal;
    expect(change, closeTo(150 / 7, 0.001));
  });

  test('holds while 4 of the last 7 days have no intake', () {
    final logged = _steadyDays(count: 30, intakeKcal: 2500, startWeightKg: 80);
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2500,
      floorKcal: 750,
      days: [
        ...logged,
        for (var day = 0; day < 4; day++) (intakeKcal: null, weightKg: 79.0),
      ],
    );

    expect(estimates[32].isHolding, isFalse);
    expect(estimates[33].isHolding, isTrue);
    expect(estimates[33].tdeeKcal, estimates[32].tdeeKcal);
  });

  test('ignores implausible intake and weights', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2500,
      floorKcal: 750,
      days: [
        ..._steadyDays(count: 30, intakeKcal: 2500, startWeightKg: 80),
        (intakeKcal: 0, weightKg: 20),
        (intakeKcal: 60000, weightKg: 80),
      ],
    );

    expect(estimates.last.tdeeKcal, closeTo(2500, 1));
  });

  test('never drops below the floor', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 1200,
      floorKcal: 1100,
      days: _steadyDays(count: 60, intakeKcal: 600, startWeightKg: 80),
    );

    expect(estimates.last.tdeeKcal, 1100);
  });

  test('starts the ramp-up with the first update, not the first day', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2000,
      floorKcal: 750,
      days: [
        for (var day = 0; day < 20; day++) (intakeKcal: null, weightKg: 80.0),
        for (var day = 0; day < 4; day++) (intakeKcal: 2600.0, weightKg: 80.0),
      ],
    );

    // The fourth logged day is the first with fewer than 4 gaps in 7.
    expect(estimates[22].tdeeKcal, 2000);
    expect(estimates.last.tdeeKcal, closeTo(2000 + 0.33 * 600, 0.001));
  });

  test('has no measured value on a day without intake', () {
    final estimates = DailyTdeeEstimator.estimate(
      seedKcal: 2500,
      floorKcal: 750,
      days: [
        ..._steadyDays(count: 10, intakeKcal: 2500, startWeightKg: 80),
        (intakeKcal: null, weightKg: 80),
      ],
    );

    expect(estimates[9].measuredTdeeKcal, isNotNull);
    expect(estimates.last.measuredTdeeKcal, isNull);
  });
}
