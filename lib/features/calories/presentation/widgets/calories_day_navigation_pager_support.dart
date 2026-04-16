import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';

/// The calories day navigation prefetch day count.
const caloriesDayNavigationPrefetchDayCount = 14;

/// The calories day navigation max fling velocity.
const caloriesDayNavigationMaxFlingVelocity = 900.0;

/// The calories day navigation fling velocity factor.
const caloriesDayNavigationFlingVelocityFactor = 0.18;

/// Build prefetched calories day overviews.
Map<String, CalorieWeekDayOverview> buildPrefetchedCaloriesDayOverviews({
  required WidgetRef ref,
  required DateTime earliestDay,
  required DateTime referenceToday,
  required DateTime visibleWindowEnd,
  required List<CalorieWeekDayOverview> visibleDaysOverview,
}) {
  final visibleDays = buildDiaryVisibleDays(anchorDay: visibleWindowEnd);
  final bufferStart = addDiaryDays(
    visibleDays.first,
    -caloriesDayNavigationPrefetchDayCount,
  );
  final bufferEnd = addDiaryDays(
    visibleDays.last,
    caloriesDayNavigationPrefetchDayCount,
  );
  final normalizedStart = bufferStart.isBefore(earliestDay)
      ? earliestDay
      : normalizeDiaryDay(bufferStart);
  var normalizedEnd = normalizeDiaryDay(bufferEnd);
  if (bufferEnd.isAfter(referenceToday)) {
    normalizedEnd = referenceToday;
  }

  final prefetchedDaysByKey = <String, CalorieWeekDayOverview>{
    for (final day in visibleDaysOverview) diaryDayKey(day.date): day,
  };
  for (
    var day = normalizedStart;
    !day.isAfter(normalizedEnd);
    day = nextDiaryDay(day)
  ) {
    final overview = ref
        .watch(calorieWeekDayOverviewForDateProvider(day))
        .value;
    if (overview == null) {
      continue;
    }
    prefetchedDaysByKey[diaryDayKey(day)] = overview;
  }
  return prefetchedDaysByKey;
}

/// Defines calories day navigation scroll physics.
class CaloriesDayNavigationScrollPhysics extends ClampingScrollPhysics {
  /// The calories day navigation scroll physics.
  const CaloriesDayNavigationScrollPhysics({super.parent});

  @override
  CaloriesDayNavigationScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CaloriesDayNavigationScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get maxFlingVelocity => caloriesDayNavigationMaxFlingVelocity;

  @override
  double carriedMomentum(double existingVelocity) => 0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final clampedVelocity = velocity.clamp(
      -caloriesDayNavigationMaxFlingVelocity,
      caloriesDayNavigationMaxFlingVelocity,
    );
    final adjustedVelocity =
        clampedVelocity * caloriesDayNavigationFlingVelocityFactor;
    return super.createBallisticSimulation(position, adjustedVelocity);
  }
}

/// Should restore calories day navigation press.
bool shouldRestoreCaloriesDayNavigationPress({
  required bool isSnapping,
  required bool isPressEnabled,
  required ScrollController scrollController,
}) {
  if (isSnapping || isPressEnabled) {
    return false;
  }
  if (scrollController.hasClients &&
      scrollController.position.isScrollingNotifier.value) {
    return false;
  }
  return true;
}

/// Animate calories day navigation to target if needed.
Future<void> animateCaloriesDayNavigationToTargetIfNeeded({
  required ScrollController scrollController,
  required double targetOffset,
  required Duration duration,
  Curve curve = Curves.easeOutCubic,
}) {
  if ((scrollController.offset - targetOffset).abs() < 0.5) {
    return Future<void>.value();
  }
  return scrollController.animateTo(
    targetOffset,
    duration: duration,
    curve: curve,
  );
}
