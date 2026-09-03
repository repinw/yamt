import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
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
    this.budgetDetails,
    this.isFutureDay = false,
    this.baseValue = '',
    this.plannedWithCarryoverValue = '',
  });

  /// Builds daily render data from raw metrics and localization dependencies.
  factory DiaryDailyBalanceData.from({
    required DateTime selectedDay,
    required DiaryDailyBalanceMetrics metrics,
    required bool isHeartDay,
    required bool canRevertHeartDay,
    required NumberFormat numberFormat,
    required AppLocalizations l10n,
    DiaryDailyBudgetDetailsData? budgetDetails,
    DateTime? now,
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

    final today = normalizeDiaryDay(now ?? DateTime.now());
    final isFutureDay = normalizeDiaryDay(selectedDay).isAfter(today);
    final leftSubtitle = _resolveLeftSubtitle(
      isFutureDay: isFutureDay,
      isHeartDay: isHeartDay,
      metrics: metrics,
      numberFormat: numberFormat,
      l10n: l10n,
    );

    final baseValue = formatDiaryKcal(
      numberFormat,
      metrics.baseGoalKcal,
      l10n.caloriesUnitKcal,
    );
    final plannedWithCarryoverValue = formatDiaryKcal(
      numberFormat,
      metrics.targetKcal,
      l10n.caloriesUnitKcal,
    );

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
      leftSubtitle: leftSubtitle,
      budgetDetails: budgetDetails,
      isFutureDay: isFutureDay,
      baseValue: baseValue,
      plannedWithCarryoverValue: plannedWithCarryoverValue,
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

  /// Whether this card represents a future day.
  final bool isFutureDay;

  /// Base goal value string.
  final String baseValue;

  /// Target value including carryover.
  final String plannedWithCarryoverValue;

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

  /// Detailed budget and carryover breakdown.
  final DiaryDailyBudgetDetailsData? budgetDetails;
}

String? _resolveLeftSubtitle({
  required bool isFutureDay,
  required bool isHeartDay,
  required DiaryDailyBalanceMetrics metrics,
  required NumberFormat numberFormat,
  required AppLocalizations l10n,
}) {
  if (isFutureDay) {
    if (metrics.carryoverKcal.round() != 0) {
      return l10n.diaryBalanceCarryoverShort(
        formatDiarySignedKcal(
          metrics.carryoverKcal,
          numberFormat,
          l10n.caloriesUnitKcal,
        ),
      );
    }
    return null;
  }
  if (isHeartDay) {
    return l10n.diaryBalanceHeartDaySubtitle;
  }
  if (metrics.heartAdjustmentKcal.round() != 0) {
    return '${l10n.diaryBalanceRealLeftLabel(
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
  }
  final parts = <String>[];
  if (metrics.baseGoalKcal.round() > 0) {
    final hasOtherAdjustments =
        metrics.carryoverKcal.round() != 0 ||
        metrics.activitySegmentKcal.round() > 0;
    final baseValue = hasOtherAdjustments
        ? numberFormat.format(metrics.baseGoalKcal.round())
        : formatDiaryKcal(
            numberFormat,
            metrics.baseGoalKcal,
            l10n.caloriesUnitKcal,
          );
    parts.add(l10n.diaryBalanceBaseGoalShort(baseValue));
  }
  if (metrics.carryoverKcal.round() != 0) {
    parts.add(
      l10n.diaryBalanceCarryoverShort(
        formatDiarySignedKcal(
          metrics.carryoverKcal,
          numberFormat,
          '',
        ).trim(),
      ),
    );
  }
  if (metrics.activitySegmentKcal.round() > 0) {
    parts.add(
      l10n.diaryBalanceSportShort(
        formatDiarySignedKcal(
          metrics.activitySegmentKcal,
          numberFormat,
          '',
        ).trim(),
      ),
    );
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
