import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Resolved presentation for the compact week balance banner.
class WeekBalanceSummaryBannerContent {
  const WeekBalanceSummaryBannerContent({
    required this.message,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String message;
  final Color accentColor;
  final Color backgroundColor;
}

/// Builds the message and colors for the compact week balance banner.
WeekBalanceSummaryBannerContent resolveWeekBalanceSummaryBannerContent({
  required CalorieWeekOverview overview,
  required AppLocalizations l10n,
  required DateTime referenceNow,
  required Color positiveAccentColor,
  required Color warningColor,
}) {
  final isGoalStartToday =
      normalizeDiaryDay(overview.balanceStartDate) ==
      normalizeDiaryDay(referenceNow);
  final carryoverBeforeTodayKcal = overview.carryoverBeforeTodayKcal;
  final accentColor = carryoverBeforeTodayKcal < 0
      ? warningColor
      : positiveAccentColor;
  final backgroundColor = carryoverBeforeTodayKcal < 0
      ? warningColor.withValues(alpha: 0.08)
      : positiveAccentColor.withValues(alpha: 0.08);
  final absoluteCarryover = carryoverBeforeTodayKcal.abs().round();
  final futureGoalStartLabel = _formatFutureGoalStartDate(
    overview.nextGoalStartDate,
    l10n.localeName,
  );
  final message = switch ((isGoalStartToday, carryoverBeforeTodayKcal)) {
    _ when overview.goalStartsInFuture && futureGoalStartLabel != null =>
      l10n.caloriesWeekBalanceStartsLater(futureGoalStartLabel),
    (true, _) => l10n.caloriesWeekBalanceStartedToday,
    (_, > 0) => l10n.caloriesWeekBalanceSaved(absoluteCarryover),
    (_, < 0) => l10n.caloriesWeekBalanceOverspent(absoluteCarryover),
    _ => l10n.caloriesWeekBalanceStable,
  };

  return WeekBalanceSummaryBannerContent(
    message: message,
    accentColor: accentColor,
    backgroundColor: backgroundColor,
  );
}

CalorieWeekOverview resolveDisplayedWeekOverview(
  AsyncValue<CalorieWeekOverview> weekOverviewState, {
  required double goalKcal,
  required DateTime visibleWindowEnd,
}) {
  return weekOverviewState.value ??
      _fallbackWeekOverview(
        goalKcal: goalKcal,
        visibleWindowEnd: visibleWindowEnd,
      );
}

void handleVisibleWindowSettled(WidgetRef ref, DateTime visibleWindowEnd) {
  final previousWindowEnd = ref.read(calorieVisibleWindowControllerProvider);
  final normalizedWindowEnd = normalizeDiaryDay(visibleWindowEnd);
  final selectedDay = ref.read(calorieDayControllerProvider);
  final resolvedSelectedDay = resolveSelectedDiaryDayForVisibleWindowChange(
    previousWindowEnd: previousWindowEnd,
    nextWindowEnd: normalizedWindowEnd,
    selectedDay: selectedDay,
  );

  ref
      .read(calorieVisibleWindowControllerProvider.notifier)
      .setWindowEnd(normalizedWindowEnd);
  if (isSameDiaryDay(selectedDay, resolvedSelectedDay)) {
    return;
  }
  ref.read(calorieDayControllerProvider.notifier).setDay(resolvedSelectedDay);
}

CalorieWeekOverview _fallbackWeekOverview({
  required double goalKcal,
  required DateTime visibleWindowEnd,
}) {
  final visibleDays = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable(
      visibleDays.map(
        (day) => CalorieWeekDayOverview(
          date: day,
          totalKcal: 0,
          goalKcal: goalKcal,
          entryCount: 0,
        ),
      ),
    ),
    totalConsumedKcal: 0,
    totalGoalKcal: goalKcal * visibleDays.length,
    remainingKcal: goalKcal * visibleDays.length,
    balanceStartDate: visibleDays.first,
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: goalKcal,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
  );
}

String? _formatFutureGoalStartDate(DateTime? date, String localeName) {
  if (date == null) {
    return null;
  }
  return DateFormat.yMMMd(localeName).format(date);
}
