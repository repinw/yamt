import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';

void main() {
  group('resolveDiaryDailyTargetKcal', () {
    test('adds only activity kcal not already included in goal', () {
      final targetKcal = resolveDiaryDailyTargetKcal(
        flexibleGoalKcal: 2000,
        goalKcal: 2100,
        baseGoalKcal: 2000,
        activitySegmentKcal: 250,
      );

      expect(targetKcal, 2150);
    });

    test('ignores negative activity segments', () {
      final targetKcal = resolveDiaryDailyTargetKcal(
        flexibleGoalKcal: 2000,
        goalKcal: 2000,
        baseGoalKcal: 2000,
        activitySegmentKcal: -150,
      );

      expect(targetKcal, 2000);
    });

    test('does not subtract when goal is below base goal', () {
      final targetKcal = resolveDiaryDailyTargetKcal(
        flexibleGoalKcal: 1800,
        goalKcal: 1700,
        baseGoalKcal: 2000,
        activitySegmentKcal: 120,
      );

      expect(targetKcal, 1920);
    });
  });
}
