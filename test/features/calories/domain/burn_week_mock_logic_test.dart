import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';

void main() {
  test('fallback goal is used when no goal exists', () {
    expect(resolveBurnWeekMockGoalKcal(null), burnWeekMockFallbackGoalKcal);
    expect(resolveBurnWeekMockGoalKcal(0), burnWeekMockFallbackGoalKcal);
    expect(usesBurnWeekMockFallbackGoal(null), isTrue);
    expect(usesBurnWeekMockFallbackGoal(-10), isTrue);
    expect(usesBurnWeekMockFallbackGoal(2200), isFalse);
  });

  test(
    'difficulty tiers keep one heart and shrink safe zone at higher stars',
    () {
      expect(resolveBurnWeekMockDifficulty(0).label, 'Learning');
      expect(resolveBurnWeekMockDifficulty(2).label, 'Steady');
      expect(resolveBurnWeekMockDifficulty(4).label, 'Solid');
      expect(resolveBurnWeekMockDifficulty(6).label, 'Elite');
      expect(resolveBurnWeekMockDifficulty(8).label, 'Master');
      expect(resolveBurnWeekMockDifficulty(0).minimumHearts, 1);
      expect(resolveBurnWeekMockDifficulty(2).minimumHearts, 1);
      expect(resolveBurnWeekMockDifficulty(4).minimumHearts, 1);
      expect(resolveBurnWeekMockDifficulty(6).minimumHearts, 1);
      expect(resolveBurnWeekMockDifficulty(8).minimumHearts, 1);
      expect(resolveBurnWeekMockDifficulty(8).safeZoneMultiplier, 0.4);
    },
  );

  test('metrics use cumulative weekly target and full week bar', () {
    final metrics = resolveBurnWeekMockMetrics(
      elapsedDebugSeconds: 24 * 60 * 60,
      goalKcal: 2000,
      consumedKcal: 1800,
    );

    expect(metrics.dailyGoalKcal, 2000);
    expect(metrics.weeklyGoalKcal, 14000);
    expect(metrics.targetKcal, 2000);
    expect(metrics.safeZoneMinKcal, 0);
    expect(metrics.safeZoneMaxKcal, 4000);
    expect(metrics.barMinKcal, 0);
    expect(metrics.barMaxKcal, 14000);
  });

  test('metrics expose marker and range ratios', () {
    const metrics = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 2 / 7,
      targetKcal: 5000,
      consumedKcal: 3000,
      safeZoneMinKcal: 2500,
      safeZoneMaxKcal: 6500,
      barMinKcal: 1000,
      barMaxKcal: 9000,
      plannedLaterKcal: 1000,
    );

    expect(metrics.targetRatio, closeTo(0.5, 0.001));
    expect(metrics.consumedRatio, closeTo(0.25, 0.001));
    expect(metrics.effectiveConsumedRatio, closeTo(0.25, 0.001));
    expect(metrics.plannedEndRatio, closeTo(0.375, 0.001));
    expect(metrics.safeZoneStartRatio, closeTo(0.1875, 0.001));
    expect(metrics.safeZoneEndRatio, closeTo(0.6875, 0.001));
    expect(metrics.ratioForKcal(0), 0);
    expect(metrics.ratioForKcal(10000), 1);
  });

  test('metric ratios use midpoint when the visible range is invalid', () {
    const metrics = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0,
      targetKcal: 1000,
      consumedKcal: 1000,
      safeZoneMinKcal: 1000,
      safeZoneMaxKcal: 1000,
      barMinKcal: 1000,
      barMaxKcal: 1000,
    );

    expect(metrics.ratioForKcal(1000), 0.5);
    expect(metrics.targetRatio, 0.5);
    expect(metrics.consumedRatio, 0.5);
  });

  test('pace and elapsed days clamp at end of week', () {
    const overWeek = burnWeekMockSecondsPerWeek + 9999;

    expect(resolveBurnWeekMockElapsedDays(overWeek), 7);
    expect(resolveBurnWeekMockPaceRatio(overWeek), 1);
  });

  test('heart spend decrements counter and may break star', () {
    final breakResult = resolveBurnWeekHeartSpend(
      starCount: 2,
      heartCount: 1,
      heartCreditKcal: 300,
      kcalDelta: -500,
    );
    final resetResult = resolveBurnWeekHeartSpend(
      starCount: 0,
      heartCount: 1,
      heartCreditKcal: 300,
      kcalDelta: 500,
    );

    expect(breakResult.starCount, 1);
    expect(breakResult.heartCount, 0);
    expect(breakResult.heartCreditKcal, -200);
    expect(breakResult.didBreakStar, isTrue);
    expect(breakResult.didResetRun, isFalse);

    expect(resetResult.starCount, 0);
    expect(resetResult.heartCount, 0);
    expect(resetResult.heartCreditKcal, 800);
    expect(resetResult.didResetRun, isFalse);
  });

  test('earned star requires hearts and no broken star or missed tracking', () {
    expect(
      resolveBurnWeekEarnedStar(
        heartCount: 2,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
      isTrue,
    );
    expect(
      resolveBurnWeekEarnedStar(
        heartCount: 0,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
      isFalse,
    );
    expect(
      resolveBurnWeekEarnedStar(
        heartCount: 2,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: false,
      ),
      isFalse,
    );
    expect(
      resolveBurnWeekEarnedStar(
        heartCount: 2,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: true,
      ),
      isFalse,
    );
  });
}
