import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';

void main() {
  test('credits corrected activity without a dynamic cap', () {
    final credit = calculateActivityCredit(rawActivityKcal: 899);

    expect(credit.rawActivityKcal, 899);
    expect(credit.correctedActivityKcal, closeTo(674.25, 0.01));
    expect(credit.activityCapKcal, closeTo(674.25, 0.01));
    expect(credit.creditedActivityKcal, closeTo(674.25, 0.01));
    expect(credit.wasCapped, isFalse);
  });

  test('clamps negative imported activity to zero', () {
    final credit = calculateActivityCredit(rawActivityKcal: -120);

    expect(credit.rawActivityKcal, 0);
    expect(credit.correctedActivityKcal, 0);
    expect(credit.creditedActivityKcal, 0);
  });

  test('averages corrected activity across all provided days', () {
    final average = calculateAverageActivityCreditKcal(
      rawActivityKcalByDay: const <int>[0, 100, 300],
    );

    expect(average, closeTo(100, 0.01));
  });

  test('subtracts average credited activity from measured total tdee', () {
    final measuredBaseTdee = calculateMeasuredBaseTdeeKcal(
      measuredTotalTdeeKcal: 2500,
      rawActivityKcalByDay: const <int>[200, 400],
    );

    expect(measuredBaseTdee, closeTo(2275, 0.01));
  });

  test('removes expected activity credit from total goal when tracking', () {
    final baseGoal = calculateActivityAdjustedBaseGoalKcal(
      totalGoalKcal: 2100,
      expectedActivityKcal: 500,
      isActivityTrackingActive: true,
    );

    expect(baseGoal, 1725);
  });
}
