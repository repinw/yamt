import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';

void main() {
  group('DiaryDailyBudgetDetailsData.from', () {
    test('computes previousDays contributions and distributes carryover', () {
      final monday = DateTime(2026, 4, 13);
      final tuesday = DateTime(2026, 4, 14);
      final wednesday = DateTime(2026, 4, 15);

      final weekOverview = CalorieWeekOverview(
        days: [
          CalorieWeekDayOverview(
            date: monday,
            totalKcal: 1800,
            goalKcal: 2000,
            entryCount: 3,
          ),
          CalorieWeekDayOverview(
            date: tuesday,
            totalKcal: 1900,
            goalKcal: 2000,
            entryCount: 4,
          ),
          CalorieWeekDayOverview(
            date: wednesday,
            totalKcal: 500,
            goalKcal: 2000,
            activityBonusKcal: 100,
            entryCount: 1,
          ),
        ],
        totalConsumedKcal: 4200,
        totalGoalKcal: 6000,
        remainingKcal: 1800,
        balanceStartDate: monday,
        carryoverBeforeTodayKcal: 60,
        todayFlexibleGoalKcal: 2160,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 500,
        eatenKcal: 500,
        realDayLeftKcal: 1660,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 1660,
        targetKcal: 2160,
        baseGoalKcal: 2000,
        carryoverKcal: 60,
        activitySegmentKcal: 100,
        activitySegmentReferenceKcal: 2160,
      );

      final data = DiaryDailyBudgetDetailsData.from(
        weekOverview: weekOverview,
        selectedDayOverview: weekOverview.days.last,
        metrics: metrics,
        isHeartDay: false,
      );

      expect(data.baseGoalKcal, 2000);
      expect(data.carryoverKcal, 60);
      expect(data.activityBonusKcal, 100);
      expect(data.targetKcal, 2160);
      expect(data.eatenKcal, 500);
      expect(data.dayLeftKcal, 1660);
      expect(data.isHeartDay, isFalse);

      expect(data.previousDays.length, 2);
      expect(data.previousDays[0].date, monday);
      expect(data.previousDays[0].differenceKcal, 200);
      expect(data.previousDays[0].isHeartDay, isFalse);

      expect(data.previousDays[1].date, tuesday);
      expect(data.previousDays[1].differenceKcal, 100);
      expect(data.previousDays[1].isHeartDay, isFalse);

      expect(data.totalCarryoverBeforeTodayKcal, 300);
      expect(data.remainingRunDays, 5); // 7 - 2 finished days
      expect(data.expectedActivityKcal, 0);
      expect(data.hasExpectedActivity, isFalse);
      expect(data.baseGoalWithoutActivityKcal, 2000);
      expect(data.extraSportKcal, 100);
      expect(data.hasExceededActivity, isTrue);
    });

    test('correctly calculates baseGoalWithoutActivity and extraSport', () {
      final monday = DateTime(2026, 4, 13);
      final weekOverview = CalorieWeekOverview(
        days: [
          CalorieWeekDayOverview(
            date: monday,
            totalKcal: 500,
            goalKcal: 2000,
            baseGoalKcal: 2000,
            expectedActivityKcal: 400,
            activityBonusKcal: 150,
            entryCount: 2,
          ),
        ],
        totalConsumedKcal: 500,
        totalGoalKcal: 2000,
        remainingKcal: 1500,
        balanceStartDate: monday,
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      final metrics = resolveDiaryDailyBalanceMetrics(
        flexibleGoalKcal: 2000,
        totalKcal: 500,
        goalKcal: 2000,
        baseGoalKcal: 2000,
        activitySegmentKcal: 150,
        bufferAdjustmentKcal: 0,
        heartCreditKcal: 0,
        isHeartDay: false,
        expectedActivityKcal: 400,
        todayActiveKcal: 550,
        isActivityTrackingActive: true,
      );

      final data = DiaryDailyBudgetDetailsData.from(
        weekOverview: weekOverview,
        selectedDayOverview: weekOverview.days.first,
        metrics: metrics,
        isHeartDay: false,
      );

      expect(data.baseGoalKcal, 2000);
      expect(data.expectedActivityKcal, 400);
      expect(data.hasExpectedActivity, isTrue);
      expect(data.baseGoalWithoutActivityKcal, 1600);
      expect(data.extraSportKcal, 150);
      expect(data.hasExceededActivity, isTrue);
    });

    test('handles heart days in previous days history', () {
      final monday = DateTime(2026, 4, 13);
      final tuesday = DateTime(2026, 4, 14);

      final weekOverview = CalorieWeekOverview(
        days: [
          CalorieWeekDayOverview(
            date: monday,
            totalKcal: 2500,
            goalKcal: 2000,
            entryCount: 4,
            isHeartDay: true,
          ),
          CalorieWeekDayOverview(
            date: tuesday,
            totalKcal: 0,
            goalKcal: 2000,
            entryCount: 0,
          ),
        ],
        totalConsumedKcal: 2000,
        totalGoalKcal: 4000,
        remainingKcal: 2000,
        balanceStartDate: monday,
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 0,
        eatenKcal: 0,
        realDayLeftKcal: 2000,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 2000,
        targetKcal: 2000,
        baseGoalKcal: 2000,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 2000,
      );

      final data = DiaryDailyBudgetDetailsData.from(
        weekOverview: weekOverview,
        selectedDayOverview: weekOverview.days.last,
        metrics: metrics,
        isHeartDay: false,
      );

      expect(data.previousDays.length, 1);
      expect(data.previousDays.first.isHeartDay, isTrue);
      // For heart days, countedTotalKcal equals goalKcal, so diff is 0
      expect(data.previousDays.first.differenceKcal, 0);
      expect(data.totalCarryoverBeforeTodayKcal, 0);
      expect(data.remainingRunDays, 6);
    });

    test('handles day 1 of run with no previous days', () {
      final monday = DateTime(2026, 4, 13);

      final weekOverview = CalorieWeekOverview(
        days: [
          CalorieWeekDayOverview(
            date: monday,
            totalKcal: 400,
            goalKcal: 2000,
            entryCount: 1,
          ),
        ],
        totalConsumedKcal: 400,
        totalGoalKcal: 2000,
        remainingKcal: 1600,
        balanceStartDate: monday,
        carryoverBeforeTodayKcal: 0,
        todayFlexibleGoalKcal: 2000,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 400,
        eatenKcal: 400,
        realDayLeftKcal: 1600,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 1600,
        targetKcal: 2000,
        baseGoalKcal: 2000,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 2000,
      );

      final data = DiaryDailyBudgetDetailsData.from(
        weekOverview: weekOverview,
        selectedDayOverview: weekOverview.days.last,
        metrics: metrics,
        isHeartDay: false,
      );

      expect(data.previousDays, isEmpty);
      expect(data.totalCarryoverBeforeTodayKcal, 0);
      expect(data.remainingRunDays, 7);
    });

    test('computes carryover macro deltas and detects active safety cap', () {
      final tuesday = DateTime(2026, 4, 14);

      // Overate on Monday by 1000 kcal with 2 remaining days ->
      // raw reduction is 500 kcal, capped at 350 kcal.
      final cappedData = DiaryDailyBudgetDetailsData(
        selectedDay: tuesday,
        baseGoalKcal: 2000,
        carryoverKcal: -350,
        activityBonusKcal: 0,
        targetKcal: 1650,
        eatenKcal: 0,
        dayLeftKcal: 1650,
        isHeartDay: false,
        totalCarryoverBeforeTodayKcal: -1000,
        remainingRunDays: 2,
        previousDays: const [],
      );

      expect(cappedData.wasSafetyCapActive, isTrue);
      expect(
        cappedData.carryoverCarbsDeltaGrams,
        closeTo(-(350 * 0.75) / 4.1, 0.01),
      );
      expect(
        cappedData.carryoverFatDeltaGrams,
        closeTo(-(350 * 0.25) / 9.3, 0.01),
      );

      // Positive carryover +100 kcal: cap is false, positive macro deltas
      final positiveData = DiaryDailyBudgetDetailsData(
        selectedDay: tuesday,
        baseGoalKcal: 2000,
        carryoverKcal: 100,
        activityBonusKcal: 0,
        targetKcal: 2100,
        eatenKcal: 0,
        dayLeftKcal: 2100,
        isHeartDay: false,
        totalCarryoverBeforeTodayKcal: 300,
        remainingRunDays: 3,
        previousDays: const [],
      );

      expect(positiveData.wasSafetyCapActive, isFalse);
      expect(
        positiveData.carryoverCarbsDeltaGrams,
        closeTo((100 * 0.75) / 4.1, 0.01),
      );
      expect(
        positiveData.carryoverFatDeltaGrams,
        closeTo((100 * 0.25) / 9.3, 0.01),
      );
    });
  });
}
