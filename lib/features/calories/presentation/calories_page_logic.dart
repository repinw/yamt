import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

/// Resolve displayed week overview.
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

/// Handle visible window settled.
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
