import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';

void main() {
  test('uses the flexible goal as the daily target', () {
    final metrics = resolveDiaryDailyBalanceMetrics(
      flexibleGoalKcal: 2498,
      totalKcal: 655,
      goalKcal: 2498,
      baseGoalKcal: 2498,
    );

    expect(metrics.targetKcal, 2498);
    expect(metrics.dayLeftKcal, 1843);
  });

  test('applies buffer adjustment to display values only', () {
    final metrics = resolveDiaryDailyBalanceMetrics(
      flexibleGoalKcal: 2669,
      totalKcal: 655,
      goalKcal: 2669,
      baseGoalKcal: 2498,
      bufferAdjustmentKcal: 250,
    );

    expect(metrics.realEatenKcal, 655);
    expect(metrics.eatenKcal, 905);
    expect(metrics.realDayLeftKcal, 2014);
    expect(metrics.dayLeftKcal, 1764);
  });
}
