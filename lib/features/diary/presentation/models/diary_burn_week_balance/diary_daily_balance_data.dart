import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_balance_formatters.dart';
import 'package:yamt/features/diary/presentation/models/diary_burn_week_balance/diary_daily_balance_subtitle_resolver.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Discriminator for balance subtitle parts.
enum DiaryDailyBalanceSubtitleType {
  /// Base goal calorie target.
  base,

  /// Carryover adjustment from previous days.
  carryover,
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
  const new({
    required this.selectedDay,
    required this.metrics,
    required this.eatenValue,
    required this.leftValue,
    required this.leftLabel,
    required this.isPauseDay,
    required this.numberFormat,
    this.leftUnit,
    this.targetAddition,
    this.targetNumber = '',
    this.caloriesUnit = '',
    this.bufferAdjustmentLabel,
    this.eatenSubtitle,
    this.leftSubtitle,
    this.leftSubtitleParts = const [],
    this.budgetDetails,
    this.isPlanned = false,
    this.isOverTarget = false,
    this.previousDayCarryoverValue,
    this.isPreviousDayClosed = false,
    this.plannedKcal = 0,
    this.countsOpenPlans,
    this.withoutPlanValue,
  });

  /// Builds daily render data from raw metrics and localization dependencies.
  factory from({
    required DateTime selectedDay,
    required DiaryDailyBalanceMetrics metrics,
    required bool isPauseDay,
    required NumberFormat numberFormat,
    required AppLocalizations l10n,
    required DateTime now,
    DiaryDailyBudgetDetailsData? budgetDetails,
    double? previousDayCarryoverKcal,
    bool isPreviousDayClosed = false,
    DiaryOpenPlans? openPlans,
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
    final realEatenLabel = l10n.diaryBalanceRealEatenLabel(
      formatDiaryKcal(
        numberFormat,
        metrics.realEatenKcal,
        l10n.caloriesUnitKcal,
      ),
    );
    final eatenSubtitle = metrics.bufferAdjustmentKcal.round() == 0
        ? null
        : '$realEatenLabel · $adjustmentLabel';

    final today = normalizeDiaryDay(now);
    final status = DiaryDayStatus.of(
      day: selectedDay,
      today: today,
      isPreviousDayClosed: isPreviousDayClosed,
    );
    // Only a future day has a day before to close. A cached dashboard from
    // yesterday may still carry the values after midnight.
    final previousDayCarryover = status.isFuture
        ? previousDayCarryoverKcal
        : null;
    final isClosed = status == DiaryDayStatus.afterClosedDay;
    final isPlanned = status.isPlanned;
    final plans = isPlanned || isPauseDay ? null : openPlans;
    final countsPlans = plans?.counted ?? false;
    final resolvedSubtitle = resolveDiaryDailyBalanceSubtitle(
      isPlanned: isPlanned,
      isPauseDay: isPauseDay,
      metrics: metrics,
      numberFormat: numberFormat,
      l10n: l10n,
    );

    final eatenNumber = numberFormat.format(metrics.eatenKcal.round());
    final targetNumber = numberFormat.format(metrics.targetKcal.round());
    final roundedLeftWithoutPlan = metrics.dayLeftKcal.round();
    final roundedLeftKcal = countsPlans
        ? (metrics.dayLeftKcal - plans!.kcal).round()
        : roundedLeftWithoutPlan;
    final isOverTarget = !isPauseDay && roundedLeftKcal < 0;
    final leftNumber = isPauseDay
        ? l10n.diaryBalancePauseDayValue
        : numberFormat.format(roundedLeftKcal.abs());
    final leftUnit = isPauseDay ? null : l10n.caloriesUnitKcal;
    final targetAddition = '/ $targetNumber';

    return DiaryDailyBalanceData(
      selectedDay: selectedDay,
      metrics: metrics,
      eatenValue: eatenNumber,
      targetAddition: targetAddition,
      leftValue: leftNumber,
      leftUnit: leftUnit,
      targetNumber: targetNumber,
      caloriesUnit: l10n.caloriesUnitKcal,
      isPauseDay: isPauseDay,
      numberFormat: numberFormat,
      bufferAdjustmentLabel: bufferAdjustmentLabel,
      eatenSubtitle: eatenSubtitle,
      leftSubtitle: resolvedSubtitle.text,
      leftSubtitleParts: resolvedSubtitle.parts,
      budgetDetails: budgetDetails,
      isPlanned: isPlanned,
      leftLabel: countsPlans
          ? l10n.diaryBalanceLeftAfterPlanLabel
          : isSameDiaryDay(selectedDay, today)
          ? l10n.diaryBalanceLeftTodayLabel
          : l10n.diaryBalanceLeftLabel,
      isOverTarget: isOverTarget,
      previousDayCarryoverValue: previousDayCarryover == null
          ? null
          : formatDiarySignedKcal(
              previousDayCarryover,
              numberFormat,
              l10n.caloriesUnitKcal,
            ),
      isPreviousDayClosed: isClosed,
      plannedKcal: plans?.kcal ?? 0,
      countsOpenPlans: plans?.counted,
      withoutPlanValue: !countsPlans
          ? null
          : roundedLeftWithoutPlan < 0
          ? l10n.diaryBalanceOverWithoutPlan(
              numberFormat.format(-roundedLeftWithoutPlan),
            )
          : l10n.diaryBalanceWithoutPlan(
              numberFormat.format(roundedLeftWithoutPlan),
            ),
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

  /// Whether this card shows a plan: a future day whose day before is not
  /// closed yet.
  final bool isPlanned;

  /// Label over what is left: "today" only on the real today.
  final String leftLabel;

  /// Whether more was eaten than the target. [leftValue] then holds the
  /// amount over the target without a sign.
  final bool isOverTarget;

  /// Target number without unit, carryover included (e.g. '2,150').
  final String targetNumber;

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

  /// Subtitle components for the daily card (base and carryover).
  final List<DiaryDailyBalanceSubtitlePart> leftSubtitleParts;

  /// Detailed budget and carryover breakdown.
  final DiaryDailyBudgetDetailsData? budgetDetails;

  /// Carryover per day from closing the day before, signed with unit
  /// (e.g. '+218 kcal'). Set only when the day before can be closed.
  final String? previousDayCarryoverValue;

  /// Whether the day before is closed, so this day counts like a started day.
  final bool isPreviousDayClosed;

  /// Kcal of the open plans, striped on the ruler; 0 without any.
  final double plannedKcal;

  /// Whether the head counts the open plans ("Nach Plan"); null when the
  /// day offers none, so no chip shows.
  final bool? countsOpenPlans;

  /// What is left without the open plans, when the head counts them.
  final String? withoutPlanValue;
}
