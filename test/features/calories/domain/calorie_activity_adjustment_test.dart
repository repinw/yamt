import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';

void main() {
  test('credits corrected activity without a dynamic cap', () {
    final credit = calculateActivityCredit(rawActivityKcal: 899);

    expect(credit.rawActivityKcal, 899);
    expect(credit.correctedActivityKcal, 899);
    expect(credit.activityCapKcal, 899);
    expect(credit.creditedActivityKcal, 899);
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

    expect(average, closeTo(133.33, 0.01));
  });

  test('subtracts average credited activity from measured total tdee', () {
    final measuredBaseTdee = calculateMeasuredBaseTdeeKcal(
      measuredTotalTdeeKcal: 2500,
      rawActivityKcalByDay: const <int>[200, 400],
    );

    expect(measuredBaseTdee, closeTo(2200, 0.01));
  });

  test(
    'keeps base goal unchanged without upfront deduction when tracking',
    () {
      final baseGoal = calculateActivityAdjustedBaseGoalKcal(
        totalGoalKcal: 2100,
        expectedActivityKcal: 500,
        isActivityTrackingActive: true,
      );

      expect(baseGoal, 2100);
    },
  );

  test(
    'calculates activity bonus only when activity exceeds baseline',
    () {
      final noBonus = calculateActivityBonusKcal(
        rawActivityKcal: 400, // 400 <= 500
        expectedActivityKcal: 500,
        isActivityTrackingActive: true,
      );
      final surplusBonus = calculateActivityBonusKcal(
        rawActivityKcal: 800, // 800 > 500 -> +300
        expectedActivityKcal: 500,
        isActivityTrackingActive: true,
      );
      final inactiveBonus = calculateActivityBonusKcal(
        rawActivityKcal: 800,
        expectedActivityKcal: 500,
        isActivityTrackingActive: false,
      );

      expect(noBonus, 0);
      expect(surplusBonus, closeTo(300, 0.01));
      expect(inactiveBonus, 0);
    },
  );
}
