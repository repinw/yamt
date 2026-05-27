import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';

void main() {
  test('adds activity to the daily target only when it is not counted yet', () {
    final metrics = resolveDiaryDailyBalanceMetrics(
      flexibleGoalKcal: 2498,
      totalKcal: 655,
      goalKcal: 2498,
      baseGoalKcal: 2498,
      activitySegmentKcal: 171,
      bufferAdjustmentKcal: 0,
      heartCreditKcal: 0,
      isHeartDay: false,
    );

    expect(metrics.activitySegmentKcal, 171);
    expect(metrics.targetKcal, 2669);
    expect(metrics.dayLeftKcal, 2014);
  });

  test('does not add already-counted activity twice', () {
    final metrics = resolveDiaryDailyBalanceMetrics(
      flexibleGoalKcal: 2669,
      totalKcal: 655,
      goalKcal: 2669,
      baseGoalKcal: 2498,
      activitySegmentKcal: 171,
      bufferAdjustmentKcal: 0,
      heartCreditKcal: 0,
      isHeartDay: false,
    );

    expect(metrics.activitySegmentKcal, 171);
    expect(metrics.targetKcal, 2669);
    expect(metrics.dayLeftKcal, 2014);
  });

  test(
    'keeps activity segment based on base plus activity when carryover grows',
    () {
      final metrics = resolveDiaryDailyBalanceMetrics(
        flexibleGoalKcal: 5000,
        totalKcal: 655,
        goalKcal: 2669,
        baseGoalKcal: 2498,
        activitySegmentKcal: 171,
        bufferAdjustmentKcal: 0,
        heartCreditKcal: 0,
        isHeartDay: false,
      );

      expect(metrics.targetKcal, 5000);
      expect(metrics.activitySegmentReferenceKcal, 2669);
    },
  );

  test('applies heart credit to display values only', () {
    final metrics = resolveDiaryDailyBalanceMetrics(
      flexibleGoalKcal: 2669,
      totalKcal: 655,
      goalKcal: 2669,
      baseGoalKcal: 2498,
      activitySegmentKcal: 171,
      bufferAdjustmentKcal: 250,
      heartCreditKcal: 250,
      isHeartDay: false,
    );

    expect(metrics.realEatenKcal, 655);
    expect(metrics.eatenKcal, 905);
    expect(metrics.realDayLeftKcal, 2014);
    expect(metrics.dayLeftKcal, 1764);
  });
}
