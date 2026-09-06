import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_data.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final numberFormat = NumberFormat.decimalPattern('en');
  final selectedDay = DateTime(2026, 4, 15);

  group('DiaryDailyBalanceData.from', () {
    test('formats leftSubtitle with base, carryover, and sport components', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 1000,
        eatenKcal: 1000,
        realDayLeftKcal: 1350,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 1350,
        targetKcal: 2350,
        baseGoalKcal: 2000,
        carryoverKcal: 150,
        activitySegmentKcal: 200,
        activitySegmentReferenceKcal: 2350,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: false,
        canRevertHeartDay: false,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(data.leftValue, '1,350');
      expect(data.leftUnit, 'kcal');
      expect(data.eatenValue, '1,000');
      expect(data.targetAddition, '/ 2,350');
      expect(data.leftSubtitle, 'Base 2,000 · Carryover +150 · Sport +200');
      expect(data.leftSubtitleParts, [
        (
          label: 'Base',
          value: '2,000',
          type: DiaryDailyBalanceSubtitleType.base,
        ),
        (
          label: 'Carryover',
          value: '+150',
          type: DiaryDailyBalanceSubtitleType.carryover,
        ),
        (
          label: 'Sport',
          value: '+200',
          type: DiaryDailyBalanceSubtitleType.sport,
        ),
      ]);
    });

    test('formats leftSubtitle with negative carryover', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 1000,
        eatenKcal: 1000,
        realDayLeftKcal: 920,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 920,
        targetKcal: 1920,
        baseGoalKcal: 2000,
        carryoverKcal: -80,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 1920,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: false,
        canRevertHeartDay: false,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(data.leftSubtitle, 'Base 2,000 · Carryover -80');
      expect(data.leftSubtitleParts, [
        (
          label: 'Base',
          value: '2,000',
          type: DiaryDailyBalanceSubtitleType.base,
        ),
        (
          label: 'Carryover',
          value: '-80',
          type: DiaryDailyBalanceSubtitleType.carryover,
        ),
      ]);
    });

    test(
      'formats leftSubtitle with standalone base goal when no adjustments',
      () {
        const metrics = DiaryDailyBalanceMetrics(
          bufferAdjustmentKcal: 0,
          realEatenKcal: 1000,
          eatenKcal: 1000,
          realDayLeftKcal: 1000,
          heartAdjustmentKcal: 0,
          dayLeftKcal: 1000,
          targetKcal: 2000,
          baseGoalKcal: 2000,
          activitySegmentKcal: 0,
          activitySegmentReferenceKcal: 2000,
        );

        final data = DiaryDailyBalanceData.from(
          selectedDay: selectedDay,
          metrics: metrics,
          isHeartDay: false,
          canRevertHeartDay: false,
          numberFormat: numberFormat,
          l10n: l10n,
        );

        expect(data.leftSubtitle, 'Base 2,000 kcal');
        expect(data.leftSubtitleParts, [
          (
            label: 'Base',
            value: '2,000 kcal',
            type: DiaryDailyBalanceSubtitleType.base,
          ),
        ]);
      },
    );

    test('formats leftSubtitle with heart day message on heart days', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 2500,
        eatenKcal: 2500,
        realDayLeftKcal: 0,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 0,
        targetKcal: 2000,
        baseGoalKcal: 2000,
        carryoverKcal: 150,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 2000,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: true,
        canRevertHeartDay: true,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(data.leftValue, 'Heart day');
      expect(data.leftUnit, isNull);
      expect(data.leftSubtitle, 'Ignored for learning');
      expect(data.leftSubtitleParts, isEmpty);
    });

    test(
      'formats future day with baseValue, plannedWithCarryoverValue, '
      'and carryover',
      () {
        const metrics = DiaryDailyBalanceMetrics(
          bufferAdjustmentKcal: 0,
          realEatenKcal: 0,
          eatenKcal: 0,
          realDayLeftKcal: 2150,
          heartAdjustmentKcal: 0,
          dayLeftKcal: 2150,
          targetKcal: 2150,
          baseGoalKcal: 2000,
          carryoverKcal: 150,
          activitySegmentKcal: 0,
          activitySegmentReferenceKcal: 2150,
        );

        final futureDay = selectedDay.add(const Duration(days: 1));
        final data = DiaryDailyBalanceData.from(
          selectedDay: futureDay,
          metrics: metrics,
          isHeartDay: false,
          canRevertHeartDay: false,
          numberFormat: numberFormat,
          l10n: l10n,
          now: selectedDay,
        );

        expect(data.isFutureDay, isTrue);
        expect(data.baseNumber, '2,000');
        expect(data.plannedWithCarryoverNumber, '2,150');
        expect(data.caloriesUnit, 'kcal');
        expect(data.baseValue, '2,000 kcal');
        expect(data.plannedWithCarryoverValue, '2,150 kcal');
        expect(data.leftSubtitle, 'Carryover +150 kcal');
        expect(data.leftSubtitleParts, isEmpty);
      },
    );

    test(
      'formats future day without carryover subtitle when carryover is zero',
      () {
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

        final futureDay = selectedDay.add(const Duration(days: 1));
        final data = DiaryDailyBalanceData.from(
          selectedDay: futureDay,
          metrics: metrics,
          isHeartDay: false,
          canRevertHeartDay: false,
          numberFormat: numberFormat,
          l10n: l10n,
          now: selectedDay,
        );

        expect(data.isFutureDay, isTrue);
        expect(data.baseValue, '2,000 kcal');
        expect(data.plannedWithCarryoverValue, '2,000 kcal');
        expect(data.leftSubtitle, isNull);
        expect(data.leftSubtitleParts, isEmpty);
      },
    );
  });
}
