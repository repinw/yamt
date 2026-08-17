import 'package:intl/intl.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Render-ready data for the daily Burn Week balance card.
class DiaryDailyBalanceData {
  /// Creates daily balance render data.
  const DiaryDailyBalanceData({
    required this.selectedDay,
    required this.metrics,
    required this.eatenValue,
    required this.leftValue,
    required this.isHeartDay,
    required this.canRevertHeartDay,
    required this.numberFormat,
    this.bufferAdjustmentLabel,
    this.eatenSubtitle,
    this.leftSubtitle,
    this.activityStatusLabel,
  });

  /// Builds daily render data from raw metrics and localization dependencies.
  factory DiaryDailyBalanceData.from({
    required DateTime selectedDay,
    required DiaryDailyBalanceMetrics metrics,
    required bool isHeartDay,
    required bool canRevertHeartDay,
    required NumberFormat numberFormat,
    required AppLocalizations l10n,
  }) {
    final adjustmentLabel = metrics.bufferAdjustmentKcal.round() == 0
        ? null
        : l10n.diaryBalanceBufferAdjustmentLabel(
            formatDiarySignedKcal(
              metrics.bufferAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          );
    final bufferAdjustmentLabel = isHeartDay ? null : adjustmentLabel;
    final eatenSubtitle = metrics.bufferAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealEatenLabel(
            formatDiaryKcal(
              numberFormat,
              metrics.realEatenKcal,
              l10n.caloriesUnitKcal,
            ),
          )} · $adjustmentLabel';
    final leftSubtitle = metrics.heartAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealLeftLabel(
            formatDiaryKcal(
              numberFormat,
              metrics.realDayLeftKcal,
              l10n.caloriesUnitKcal,
            ),
          )} · ${l10n.diaryBalanceHeartAdjustmentLabel(
            formatDiarySignedKcal(
              metrics.heartAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          )}';

    final String? activityStatusLabel;
    if (!isHeartDay &&
        metrics.isActivityTrackingActive &&
        metrics.todayActiveKcal > 0) {
      if (metrics.activitySegmentKcal > 0) {
        activityStatusLabel = l10n.diaryBalanceActivityBonusLabel(
          formatDiaryKcal(
            numberFormat,
            metrics.activitySegmentKcal,
            l10n.caloriesUnitKcal,
          ),
        );
      } else {
        activityStatusLabel = l10n.diaryBalanceActivityIncludedLabel(
          formatDiaryKcal(
            numberFormat,
            metrics.todayActiveKcal.toDouble(),
            l10n.caloriesUnitKcal,
          ),
        );
      }
    } else {
      activityStatusLabel = null;
    }

    return DiaryDailyBalanceData(
      selectedDay: selectedDay,
      metrics: metrics,
      eatenValue: formatDiaryKcal(
        numberFormat,
        metrics.eatenKcal,
        l10n.caloriesUnitKcal,
      ),
      leftValue: isHeartDay
          ? l10n.diaryBalanceHeartDayValue
          : formatDiaryKcal(
              numberFormat,
              metrics.dayLeftKcal,
              l10n.caloriesUnitKcal,
            ),
      isHeartDay: isHeartDay,
      canRevertHeartDay: canRevertHeartDay,
      numberFormat: numberFormat,
      bufferAdjustmentLabel: bufferAdjustmentLabel,
      eatenSubtitle: eatenSubtitle,
      leftSubtitle: isHeartDay
          ? l10n.diaryBalanceHeartDaySubtitle
          : leftSubtitle,
      activityStatusLabel: activityStatusLabel,
    );
  }

  /// Date represented by the daily card.
  final DateTime selectedDay;

  /// Derived metrics for the daily card.
  final DiaryDailyBalanceMetrics metrics;

  /// Eaten value label.
  final String eatenValue;

  /// Left value label.
  final String leftValue;

  /// Whether the selected day is currently marked as a heart day.
  final bool isHeartDay;

  /// Whether the selected heart day can be reverted.
  final bool canRevertHeartDay;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  /// Optional buffer adjustment label.
  final String? bufferAdjustmentLabel;

  /// Optional eaten subtitle.
  final String? eatenSubtitle;

  /// Optional left subtitle.
  final String? leftSubtitle;

  /// Optional activity baseline / bonus status label.
  final String? activityStatusLabel;
}
