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
    test('formats activity included label when no bonus earned', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 1200,
        eatenKcal: 1200,
        realDayLeftKcal: 800,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 800,
        targetKcal: 2000,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 2000,
        todayActiveKcal: 200,
        expectedActivityKcal: 400,
        isActivityTrackingActive: true,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: false,
        canRevertHeartDay: false,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(
        data.activityStatusLabel,
        '200 kcal activity included in daily goal',
      );
    });

    test('formats activity bonus label when bonus earned', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 1200,
        eatenKcal: 1200,
        realDayLeftKcal: 950,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 950,
        targetKcal: 2150,
        activitySegmentKcal: 150,
        activitySegmentReferenceKcal: 2150,
        todayActiveKcal: 600,
        expectedActivityKcal: 400,
        isActivityTrackingActive: true,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: false,
        canRevertHeartDay: false,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(data.activityStatusLabel, '150 kcal extra sport bonus');
    });

    test('returns null when tracking is inactive or todayActive is 0', () {
      const metrics = DiaryDailyBalanceMetrics(
        bufferAdjustmentKcal: 0,
        realEatenKcal: 1200,
        eatenKcal: 1200,
        realDayLeftKcal: 800,
        heartAdjustmentKcal: 0,
        dayLeftKcal: 800,
        targetKcal: 2000,
        activitySegmentKcal: 0,
        activitySegmentReferenceKcal: 2000,
        expectedActivityKcal: 400,
        isActivityTrackingActive: true,
      );

      final data = DiaryDailyBalanceData.from(
        selectedDay: selectedDay,
        metrics: metrics,
        isHeartDay: false,
        canRevertHeartDay: false,
        numberFormat: numberFormat,
        l10n: l10n,
      );

      expect(data.activityStatusLabel, isNull);
    });
  });
}
