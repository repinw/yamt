import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';

/// The three macros of the budget card.
enum DiaryBudgetMacroKind {
  /// Protein.
  protein,

  /// Carbohydrates.
  carbs,

  /// Fat.
  fat,
}

/// One macro of the budget card.
typedef DiaryBudgetMacro = ({
  DiaryBudgetMacroKind kind,
  double eaten,
  double planned,
  double target,
});

/// Why the day does not count yet, while it can be tracked.
sealed class DiaryBudgetNotCounting {
  const new(this.startDate);

  /// First day that counts.
  final DateTime startDate;
}

/// A practice day before the goal starts.
final class DiaryBudgetPracticeDay extends DiaryBudgetNotCounting {
  /// Creates a practice day.
  const new(super.startDate);
}

/// A day after a run ended, before the new run starts.
final class DiaryBudgetRunEnded extends DiaryBudgetNotCounting {
  /// Creates a run-ended day.
  const new(super.startDate);
}

/// Render-ready state of the diary budget card.
class DiaryBudgetCardData {
  /// Creates the card data.
  const new({
    required this.day,
    required this.status,
    required this.metrics,
    required this.isPauseDay,
    required this.macros,
    this.openPlans,
    this.notCounting,
    this.budgetDetails,
    this.canClosePreviousDay = false,
    this.isPreviousDayClosed = false,
    this.runWeekStart,
    this.paceKcal,
  });

  /// Builds the card data of [card] for [today].
  factory from({
    required DiaryBalanceCardData card,
    required DateTime today,
    DiaryNutritionBarsData? nutrition,
    DiaryOpenPlans? openPlans,
    double? paceShare,
  }) {
    final practice = card.practiceDay;
    final restart = card.scheduledRestart;
    final loaded = card.loadedMetrics;
    final day = loaded?.selectedDay ?? practice?.day ?? restart!.day;
    final metrics = loaded?.daily ?? practice?.daily ?? restart!.daily;
    final status = DiaryDayStatus.of(
      day: day,
      today: today,
      isPreviousDayClosed: loaded?.isPreviousDayClosed ?? false,
    );
    final countedPlans = openPlans?.counted ?? false ? openPlans : null;
    final goals = nutrition?.goals;
    DiaryBudgetMacro macro(
      DiaryBudgetMacroKind kind,
      double? eaten,
      double? planned,
      double? target,
    ) => (
      kind: kind,
      eaten: eaten ?? 0,
      planned: planned ?? 0,
      target: target ?? 0,
    );

    return DiaryBudgetCardData(
      day: day,
      status: status,
      metrics: metrics,
      isPauseDay: loaded?.state.isPauseDay ?? false,
      openPlans: openPlans,
      notCounting: practice != null
          ? DiaryBudgetPracticeDay(practice.startDate)
          : restart != null
          ? DiaryBudgetRunEnded(restart.startDate)
          : null,
      budgetDetails: loaded?.budgetDetails,
      // Only a future day has a day before to close, and only when closing
      // it brings a carryover. A cached dashboard from yesterday may still
      // carry the values after midnight.
      canClosePreviousDay:
          status.isFuture && loaded?.previousDayCarryoverKcal != null,
      isPreviousDayClosed: status == DiaryDayStatus.afterClosedDay,
      runWeekStart: loaded?.runWeekStart,
      paceKcal: paceShare == null || (loaded?.state.isPauseDay ?? false)
          ? null
          : metrics.targetKcal * paceShare,
      macros: nutrition == null
          ? const []
          : [
              macro(
                DiaryBudgetMacroKind.protein,
                nutrition.protein,
                countedPlans?.protein,
                goals?.protein,
              ),
              macro(
                DiaryBudgetMacroKind.carbs,
                nutrition.carbs,
                countedPlans?.carbs,
                goals?.carbs,
              ),
              macro(
                DiaryBudgetMacroKind.fat,
                nutrition.fat,
                countedPlans?.fat,
                goals?.fat,
              ),
            ],
    );
  }

  /// Day of the card.
  final DateTime day;

  /// Where the day stands relative to today.
  final DiaryDayStatus status;

  /// Daily kcal values.
  final DiaryDailyBalanceMetrics metrics;

  /// Whether the day is a pause day, which counts nothing.
  final bool isPauseDay;

  /// The open plans of the day, or null when it offers none.
  final DiaryOpenPlans? openPlans;

  /// Set while the day can be tracked but does not count yet.
  final DiaryBudgetNotCounting? notCounting;

  /// Breakdown for the budget sheet, or null on a planned day.
  final DiaryDailyBudgetDetailsData? budgetDetails;

  /// Whether the day before can be closed (or reopened) from here.
  final bool canClosePreviousDay;

  /// Whether the day before is closed.
  final bool isPreviousDayClosed;

  /// First day of the run week the day belongs to, or null outside a run.
  final DateTime? runWeekStart;

  /// Protein, carbs, and fat, or empty while the macros load.
  final List<DiaryBudgetMacro> macros;

  /// Kcal the day should be at by now, which the kcal line marks; null on
  /// a pause day and while the marker is off or the day is not today.
  final double? paceKcal;

  /// Whether the open plans count toward what is left ("Nach Plan").
  bool get countsPlans => openPlans?.counted ?? false;

  /// Planned kcal that count toward what is left.
  double get countedPlannedKcal => countsPlans ? openPlans!.kcal : 0;

  /// Whether the whole day is a plan: a future day whose day before is open.
  bool get isPlannedDay => status.isPlanned;

  /// Kcal left, after the counted plans; negative when over the target.
  double get leftKcal => metrics.dayLeftKcal - countedPlannedKcal;

  /// Whether more is eaten (and counted as planned) than the target.
  bool get isOver => !isPauseDay && leftKcal.round() < 0;

  /// Macro with the lowest share of its target, which gets its color. Only
  /// today and later days have one, since only there can it change; none
  /// on a pause day, while all shares are equal, or when all are over.
  DiaryBudgetMacroKind? get lowestMacro {
    if (isPauseDay || status.isPast || macros.isEmpty) {
      return null;
    }
    double share(DiaryBudgetMacro m) =>
        m.target <= 0 ? double.infinity : (m.eaten + m.planned) / m.target;
    final shares = [for (final m in macros) share(m)];
    final lowest = shares.reduce((a, b) => a < b ? a : b);
    if (lowest >= 1 || shares.every((s) => s == lowest)) {
      return null;
    }
    return macros[shares.indexOf(lowest)].kind;
  }
}
