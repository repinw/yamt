// Internal helper is public only so the legacy provider can import it.
// ignore_for_file: public_member_api_docs

import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _weeklyCheckInDisposedMessage = 'Calorie weekly check-in disposed.';

Future<CalorieWeeklyCheckInHealthData> loadCalorieWeeklyCheckInHealthData({
  required Future<HealthConnectionStatus> healthStatusFuture,
  required HealthWeightService healthWeightService,
  required DiaryHealthService diaryHealthService,
  required CalorieGoalSettings settings,
  required CalorieWeeklyCheckInWindowDates dates,
  required DateTime today,
  required bool Function() isMounted,
}) async {
  final activeKcalByDay = <String, int>{
    for (final day in dates.learningDays) diaryDayKey(day): 0,
  };
  const todayActiveKcal = 0;

  final status = await healthStatusFuture;
  _throwIfUnmounted(isMounted);
  if (status.accessState != HealthDataAccessState.ready) {
    return CalorieWeeklyCheckInHealthData(
      activeKcalByDay: activeKcalByDay,
      todayActiveKcal: todayActiveKcal,
      healthWeightSamples: const <HealthWeightSample>[],
      usesHealthActivity: false,
    );
  }

  final healthWeightSamples = await healthWeightService.loadWeightSamples(
    startInclusive: _earliestDay([
      dates.learningStartDate,
      ...dates.healthWeightStartCandidates,
    ]),
    endExclusive: nextDiaryDay(dates.nextBoundaryDay),
  );
  _throwIfUnmounted(isMounted);

  return CalorieWeeklyCheckInHealthData(
    activeKcalByDay: activeKcalByDay,
    todayActiveKcal: todayActiveKcal,
    healthWeightSamples: healthWeightSamples,
    usesHealthActivity: false,
  );
}

DateTime _earliestDay(List<DateTime> days) {
  assert(days.isNotEmpty, 'At least one day is required.');
  var earliest = normalizeDiaryDay(days.first);
  for (final day in days.skip(1)) {
    final normalizedDay = normalizeDiaryDay(day);
    if (normalizedDay.isBefore(earliest)) {
      earliest = normalizedDay;
    }
  }
  return earliest;
}

void _throwIfUnmounted(bool Function() isMounted) {
  if (!isMounted()) {
    throw StateError(_weeklyCheckInDisposedMessage);
  }
}
