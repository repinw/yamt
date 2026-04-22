import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';

void main() {
  test('fallback goal is used when no goal exists', () {
    expect(resolveBurnWeekMockGoalKcal(null), burnWeekMockFallbackGoalKcal);
    expect(resolveBurnWeekMockGoalKcal(0), burnWeekMockFallbackGoalKcal);
    expect(usesBurnWeekMockFallbackGoal(null), isTrue);
    expect(usesBurnWeekMockFallbackGoal(-10), isTrue);
    expect(usesBurnWeekMockFallbackGoal(2200), isFalse);
  });

  test('difficulty tiers shrink hearts and safe zone at higher stars', () {
    expect(resolveBurnWeekMockDifficulty(0).label, 'Learning');
    expect(resolveBurnWeekMockDifficulty(2).label, 'Steady');
    expect(resolveBurnWeekMockDifficulty(4).label, 'Solid');
    expect(resolveBurnWeekMockDifficulty(6).label, 'Elite');
    expect(resolveBurnWeekMockDifficulty(8).label, 'Master');
    expect(resolveBurnWeekMockDifficulty(8).minimumHearts, 1);
    expect(resolveBurnWeekMockDifficulty(8).safeZoneMultiplier, 0.4);
  });

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

  test('pace and elapsed days clamp at end of week', () {
    const overWeek = burnWeekMockSecondsPerWeek + 9999;

    expect(resolveBurnWeekMockElapsedDays(overWeek), 7);
    expect(resolveBurnWeekMockPaceRatio(overWeek), 1);
  });

  test('zone decisions follow recovery rules', () {
    const recoverableBelow = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.5,
      targetKcal: 7000,
      consumedKcal: 5000,
      safeZoneMinKcal: 6000,
      safeZoneMaxKcal: 8000,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );
    const unrecoverableBelow = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.9,
      targetKcal: 12600,
      consumedKcal: 9000,
      safeZoneMinKcal: 11000,
      safeZoneMaxKcal: 14200,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );
    const recoverableAbove = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.5,
      targetKcal: 7000,
      consumedKcal: 9500,
      safeZoneMinKcal: 6000,
      safeZoneMaxKcal: 8000,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );
    const unrecoverableAbove = BurnWeekMockMetrics(
      dailyGoalKcal: 2000,
      weeklyGoalKcal: 14000,
      usesFallbackGoal: false,
      paceRatio: 0.9,
      targetKcal: 12600,
      consumedKcal: 14600,
      safeZoneMinKcal: 11000,
      safeZoneMaxKcal: 14200,
      barMinKcal: 0,
      barMaxKcal: 14000,
    );

    expect(
      resolveBurnWeekZoneDecision(recoverableBelow).type,
      BurnWeekZoneDecisionType.belowCanEatOrUseHeart,
    );
    expect(
      resolveBurnWeekZoneDecision(unrecoverableBelow).type,
      BurnWeekZoneDecisionType.belowNeedsHeart,
    );
    expect(
      resolveBurnWeekZoneDecision(recoverableAbove).type,
      BurnWeekZoneDecisionType.aboveFastOnly,
    );
    expect(
      resolveBurnWeekZoneDecision(unrecoverableAbove).type,
      BurnWeekZoneDecisionType.aboveNeedsHeart,
    );
  });

  test('heart spend breaks star or spends the last heart', () {
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
    expect(breakResult.heartCount, 3);
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
