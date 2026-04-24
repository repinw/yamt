import 'package:flutter/material.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_budget_details_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Callback fired when a Burn Week dialog route is created and pushed.
typedef BurnWeekDialogRouteReady =
    void Function(NavigatorState navigator, Route<void> route);

/// Heart actions available from live Burn Week dialog.
enum BurnWeekLiveHeartAction {
  /// Add one Burn day worth of kcal.
  add,

  /// Remove one Burn day worth of kcal.
  remove,
}

/// Recovery actions for below-target live Burn Week dialog.
enum BurnWeekLiveBelowZoneAction {
  /// User will recover by eating more.
  eatMore,

  /// User will recover by spending one heart.
  useHeart,
}

/// Preformatted details shown in live Burn Week info dialog.
class BurnWeekLiveDetailsData {
  /// Creates details data for live Burn Week dialog.
  const BurnWeekLiveDetailsData({
    required this.actualText,
    required this.targetText,
    required this.dailyGoalText,
    required this.weeklyGoalText,
    required this.currentTimeLabel,
    required this.weekRatioText,
    required this.targetFormulaText,
    required this.weekEatenSoFarText,
    required this.plannedLaterTodayText,
    required this.todayBudgetText,
    required this.todayFoodText,
    required this.todayLeftText,
    required this.weekActivityBonusText,
    required this.weekCarryoverText,
    required this.previousWeekOverflowText,
    required this.weekRemainingAfterFoodText,
    required this.safeMinText,
    required this.safeMaxText,
    required this.starsHeartsText,
    required this.heartCreditText,
  });

  /// Actual calories text.
  final String actualText;

  /// Target calories text.
  final String targetText;

  /// Daily goal text.
  final String dailyGoalText;

  /// Weekly goal text.
  final String weeklyGoalText;

  /// Current time label.
  final String currentTimeLabel;

  /// Week ratio text.
  final String weekRatioText;

  /// Target formula text.
  final String targetFormulaText;

  /// Week eaten so far text.
  final String weekEatenSoFarText;

  /// Planned later today text.
  final String plannedLaterTodayText;

  /// Full day budget text.
  final String todayBudgetText;

  /// Today food text.
  final String todayFoodText;

  /// Today remaining text.
  final String todayLeftText;

  /// Week activity bonus text.
  final String weekActivityBonusText;

  /// Week carryover text.
  final String weekCarryoverText;

  /// Previous week overflow text.
  final String previousWeekOverflowText;

  /// Week remaining after food text.
  final String weekRemainingAfterFoodText;

  /// Safe zone minimum text.
  final String safeMinText;

  /// Safe zone maximum text.
  final String safeMaxText;

  /// Stars/hearts text.
  final String starsHeartsText;

  /// Heart credit text.
  final String heartCreditText;
}

/// Shows simple close-only Burn Week dialog.
Future<void> showBurnWeekSimpleDialog({
  required BuildContext context,
  required String title,
  required String message,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  return _showBurnWeekDialog<void>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week use-heart dialog.
Future<BurnWeekLiveHeartAction?> showBurnWeekUseHeartDialog({
  required BuildContext context,
  required int dayKcal,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<BurnWeekLiveHeartAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekUseHeartTitle),
        content: Text(l10n.burnWeekUseHeartMessage(dayKcal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.burnWeekActionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekLiveHeartAction.remove);
            },
            child: Text(l10n.burnWeekActionRemoveDayKcal),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekLiveHeartAction.add);
            },
            child: Text(l10n.burnWeekActionAddDayKcal),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week "too far below" dialog.
Future<bool?> showBurnWeekBelowNeedsHeartDialog(
  BuildContext context, {
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<bool>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekZoneBelowNeedsHeartTitle),
        content: Text(l10n.burnWeekZoneBelowNeedsHeartMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.burnWeekActionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.burnWeekZoneUseHeartAction),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week recover-below dialog.
Future<BurnWeekLiveBelowZoneAction?> showBurnWeekBelowRecoverDialog({
  required BuildContext context,
  required bool hasHearts,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<BurnWeekLiveBelowZoneAction>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekZoneOutOfSafeZoneTitle),
        content: Text(
          hasHearts
              ? l10n.burnWeekZoneBelowRecoverMessage
              : l10n.burnWeekZoneBelowRecoverNoHeartsMessage,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekLiveBelowZoneAction.eatMore);
            },
            child: Text(l10n.burnWeekZoneEatMoreAction),
          ),
          if (hasHearts)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(BurnWeekLiveBelowZoneAction.useHeart);
              },
              child: Text(l10n.burnWeekZoneUseHeartAction),
            ),
        ],
      );
    },
  );
}

/// Shows live Burn Week "too far above" dialog.
Future<bool?> showBurnWeekAboveNeedsHeartDialog(
  BuildContext context, {
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<bool>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekUseHeartTitle),
        content: Text(l10n.burnWeekZoneAboveNeedsHeartMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.burnWeekActionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.burnWeekActionYes),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week details dialog.
Future<void> showBurnWeekDetailsDialog({
  required BuildContext context,
  required BurnWeekLiveDetailsData data,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showCalorieBudgetDetailsDialog(
    context: context,
    data: CalorieBudgetDetailsData(
      title: l10n.burnWeekDetailsTitle,
      primaryLabel: l10n.calorieBudgetDetailsActualLabel,
      primaryValue: data.actualText,
      secondaryLabel: l10n.calorieBudgetDetailsTargetLabel,
      secondaryValue: data.targetText,
      explanation: l10n.calorieBudgetDetailsBalanceExplanation,
      lines: [
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsDailyGoal,
          value: data.dailyGoalText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsWeekTarget,
          value: data.weeklyGoalText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsCurrentTime,
          value: data.currentTimeLabel,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsStarsHearts,
          value: data.starsHeartsText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsHeartKcalUsed,
          value: data.heartCreditText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsWeekRatio,
          value: data.weekRatioText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsTargetFormula,
          value: data.targetFormulaText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsLoggedFoodSoFar,
          value: data.weekEatenSoFarText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsPlannedLaterToday,
          value: data.plannedLaterTodayText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsTodayBudget,
          value: data.todayBudgetText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsFoodToday,
          value: data.todayFoodText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.calorieBudgetDetailsRemaining,
          value: data.todayLeftText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsActivityBonusSoFar,
          value: data.weekActivityBonusText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsWeekCarryover,
          value: data.weekCarryoverText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsPreviousWeekOverflow,
          value: data.previousWeekOverflowText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsWeekLeftAfterFood,
          value: data.weekRemainingAfterFoodText,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsSportCounting,
          value: l10n.burnWeekDetailsSportCountingValue,
        ),
        CalorieBudgetDetailsLine(
          label: l10n.burnWeekDetailsSafeZone,
          value: '${data.safeMinText} - ${data.safeMaxText}',
        ),
      ],
    ),
  );
}

Future<T?> _showBurnWeekDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    themes: themes,
    barrierColor:
        DialogTheme.of(context).barrierColor ??
        Theme.of(context).dialogTheme.barrierColor ??
        Colors.black54,
  );
  onRouteReady?.call(navigator, route);
  return navigator.push(route);
}
