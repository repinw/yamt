import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/presentation/widgets/burn_week_live_overview_logic.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_metrics.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Localized labels for the loaded Burn Week balance card.
class DiaryBalanceLoadedLabels {
  /// Creates loaded-card labels.
  const DiaryBalanceLoadedLabels({
    required this.weekDayLabel,
    required this.scaleStartLabel,
    required this.scaleEndLabel,
    required this.eatenValue,
    required this.leftValue,
    this.bufferAdjustmentLabel,
    this.eatenSubtitle,
    this.leftSubtitle,
  });

  /// Builds loaded-card labels from localized context.
  factory DiaryBalanceLoadedLabels.from({
    required BuildContext context,
    required DiaryBalanceLoadedMetrics resolvedMetrics,
  }) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final adjustmentLabel = resolvedMetrics.bufferAdjustmentKcal.round() == 0
        ? null
        : l10n.diaryBalanceBufferAdjustmentLabel(
            formatBurnWeekSignedKcal(
              resolvedMetrics.bufferAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          );
    final bufferAdjustmentLabel = resolvedMetrics.isHeartDay
        ? null
        : adjustmentLabel;
    final eatenSubtitle = resolvedMetrics.bufferAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealEatenLabel(
            _formatKcal(
              numberFormat,
              resolvedMetrics.realEatenKcal,
              l10n.caloriesUnitKcal,
            ),
          )} · $adjustmentLabel';
    final leftSubtitle = resolvedMetrics.heartAdjustmentKcal.round() == 0
        ? null
        : '${l10n.diaryBalanceRealLeftLabel(
            _formatKcal(
              numberFormat,
              resolvedMetrics.realDayLeftKcal,
              l10n.caloriesUnitKcal,
            ),
          )} · ${l10n.diaryBalanceHeartAdjustmentLabel(
            formatBurnWeekSignedKcal(
              resolvedMetrics.heartAdjustmentKcal,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
          )}';

    return DiaryBalanceLoadedLabels(
      weekDayLabel: formatBurnWeekLiveWeekDayLabel(
        currentDay: resolvedMetrics.selectedDay,
        currentWeekStartDate: resolvedMetrics.currentWeekStartDate,
        runWeekNumber: resolvedMetrics.runWeekNumber,
        l10n: l10n,
      ),
      scaleStartLabel: '0 ${l10n.caloriesUnitKcal}',
      scaleEndLabel: _formatKcal(
        numberFormat,
        resolvedMetrics.metrics.barMaxKcal,
        l10n.caloriesUnitKcal,
      ),
      eatenValue: _formatKcal(
        numberFormat,
        resolvedMetrics.eatenKcal,
        l10n.caloriesUnitKcal,
      ),
      leftValue: resolvedMetrics.isHeartDay
          ? l10n.diaryBalanceHeartDayValue
          : _formatKcal(
              numberFormat,
              resolvedMetrics.dayLeftKcal,
              l10n.caloriesUnitKcal,
            ),
      bufferAdjustmentLabel: bufferAdjustmentLabel,
      eatenSubtitle: eatenSubtitle,
      leftSubtitle: resolvedMetrics.isHeartDay
          ? l10n.diaryBalanceHeartDaySubtitle
          : leftSubtitle,
    );
  }

  /// Header week/day label.
  final String weekDayLabel;

  /// Scale start label.
  final String scaleStartLabel;

  /// Scale end label.
  final String scaleEndLabel;

  /// Optional buffer adjustment label.
  final String? bufferAdjustmentLabel;

  /// Eaten value label.
  final String eatenValue;

  /// Optional eaten subtitle.
  final String? eatenSubtitle;

  /// Left value label.
  final String leftValue;

  /// Optional left subtitle.
  final String? leftSubtitle;
}

String _formatKcal(NumberFormat numberFormat, double value, String unit) {
  return '${numberFormat.format(value.round())} $unit';
}
