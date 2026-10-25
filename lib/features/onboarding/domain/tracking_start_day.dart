import 'package:yamt/core/domain/local_day_window.dart';

/// Hour from which onboarding proposes tomorrow instead of today.
///
/// Later in the day most meals are already eaten and not tracked, so the day
/// would spoil the first learning week.
const trackingStartTomorrowFromHour = 12;

/// Latest start day the picker offers, in days after today.
const maximumTrackingStartDelayDays = 14;

/// Start day onboarding proposes for the first tracked week at [now].
DateTime defaultTrackingStartDay(DateTime now) {
  final today = normalizeLocalDay(now);
  return now.hour < trackingStartTomorrowFromHour ? today : nextLocalDay(today);
}

/// Latest start day the user may pick at [now].
DateTime latestTrackingStartDay(DateTime now) {
  return addLocalDays(normalizeLocalDay(now), maximumTrackingStartDelayDays);
}
