import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_subtitle_resolver.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Discriminator for balance subtitle parts.
enum DiaryDailyBalanceSubtitleType {
  /// Base goal calorie target.
  base,

  /// Carryover adjustment from previous days.
  carryover,

  /// Extra sport / activity calorie adjustment.
  sport,
}

/// A localized text component of the daily balance subtitle.
typedef DiaryDailyBalanceSubtitlePart = ({
  String label,
  String value,
  DiaryDailyBalanceSubtitleType type,
});

/// Render-ready data for the daily Burn Week balance card.
class DiaryDailyBalanceData {
  /// Creates daily balance render data.
  const DiaryDailyBalanceData({
    required this.selectedDay,
    required this.metrics,
    required this.eatenValue,
    required this.leftValue,
    required this.isPauseDay,
    required this.numberFormat,
    this.leftUnit,
    this.targetAddition,
    this.baseNumber = '',
    this.plannedWithCarryoverNumber = '',
    this.caloriesUnit = '',
    this.bufferAdjustmentLabel,
    this.eatenSubtitle,
    this.leftSubtitle,
    this.leftSubtitleParts = const [],
    this.budgetDetails,
    this.isFutureDay = false,
    this.baseValue = '',
    this.plannedWithCarryoverValue = '',
  });

  /// Builds daily render data from raw metrics and localization dependencies.
  factory DiaryDailyBalanceData.from({
    required DateTime selectedDay,
    required DiaryDailyBalanceMetrics metrics,
    required bool isPauseDay,
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
    final bufferAdjustmentLabel = isPauseDay ? null : adjustmentLabel;
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
    final resolvedSubtitle = resolveDiaryDailyBalanceSubtitle(
      isFutureDay: isFutureDay,
      isPauseDay: isPauseDay,
      metrics: metrics,
      numberFormat: numberFormat,
      l10n: l10n,
    );

    final baseNumber = numberFormat.format(metrics.baseGoalKcal.round());
    final plannedWithCarryoverNumber = numberFormat.format(
      metrics.targetKcal.round(),
    );
    final eatenNumber = numberFormat.format(metrics.eatenKcal.round());
    final targetNumber = numberFormat.format(metrics.targetKcal.round());
    final leftNumber = isPauseDay
        ? l10n.diaryBalancePauseDayValue
        : numberFormat.format(metrics.dayLeftKcal.round());
    final leftUnit = isPauseDay ? null : l10n.caloriesUnitKcal;
    final targetAddition = '/ $targetNumber';

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
      eatenValue: eatenNumber,
      targetAddition: targetAddition,
      leftValue: leftNumber,
      leftUnit: leftUnit,
      baseNumber: baseNumber,
      plannedWithCarryoverNumber: plannedWithCarryoverNumber,
      caloriesUnit: l10n.caloriesUnitKcal,
      isPauseDay: isPauseDay,
      numberFormat: numberFormat,
      bufferAdjustmentLabel: bufferAdjustmentLabel,
      eatenSubtitle: eatenSubtitle,
      leftSubtitle: resolvedSubtitle.text,
      leftSubtitleParts: resolvedSubtitle.parts,
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

  /// Eaten numeric value (e.g. '800').
  final String eatenValue;

  /// Target supplement for the eaten metric (e.g. '/ 2,000').
  final String? targetAddition;

  /// Left numeric value or pause day label (e.g. '1,000').
  final String leftValue;

  /// Unit for the left value (e.g. 'kcal', or null on pause day).
  final String? leftUnit;

  /// Whether this card represents a future day.
  final bool isFutureDay;

  /// Base goal value string including unit (e.g. '2,000 kcal').
  final String baseValue;

  /// Base goal number without unit (e.g. '2,000').
  final String baseNumber;

  /// Target value including carryover and unit (e.g. '2,150 kcal').
  final String plannedWithCarryoverValue;

  /// Planned with carryover number without unit (e.g. '2,150').
  final String plannedWithCarryoverNumber;

  /// Localized calorie unit (e.g. 'kcal').
  final String caloriesUnit;

  /// Whether the selected day is currently marked as a pause day.
  final bool isPauseDay;

  /// Locale-aware number formatter.
  final NumberFormat numberFormat;

  /// Optional buffer adjustment label.
  final String? bufferAdjustmentLabel;

  /// Optional eaten subtitle.
  final String? eatenSubtitle;

  /// Optional left subtitle.
  final String? leftSubtitle;

  /// Subtitle components for the daily card (e.g. base, carryover, sport).
  final List<DiaryDailyBalanceSubtitlePart> leftSubtitleParts;

  /// Detailed budget and carryover breakdown.
  final DiaryDailyBudgetDetailsData? budgetDetails;
}
