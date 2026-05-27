import 'package:yamt/features/health/data/diary_health_mobile_config.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// Whether derived day data contains no useful activity.
bool isEmptyDiaryHealthDayData(DiaryHealthDayData data) {
  return data.totalSteps <= 0 &&
      data.workouts.isEmpty &&
      data.unassignedActiveEnergySegments.isEmpty;
}

/// Whether every aggregate trend day is empty.
bool isEmptyDiaryHealthActivityTrendDays(
  List<DiaryHealthActivityTrendDay> days,
) {
  return days.every(isEmptyDiaryHealthActivityTrendDay);
}

/// Whether one aggregate trend day is empty.
bool isEmptyDiaryHealthActivityTrendDay(DiaryHealthActivityTrendDay day) {
  return day.totalSteps <= 0 && day.activeEnergyKcal <= 0;
}

/// Normalize user height for Health-derived estimates.
double? normalizeDiaryHealthUserHeightCm(double? userHeightCm) {
  if (userHeightCm == null || userHeightCm <= 0) {
    return null;
  }

  return userHeightCm.clamp(
    minPersonalizedHeightCm,
    maxPersonalizedHeightCm,
  );
}

/// Cache TTL for one diary health day.
Duration cacheTtlForDiaryHealthDay({
  required DateTime dayStart,
  required DateTime now,
  required Duration todayCacheTtl,
  required Duration historicalCacheTtl,
}) {
  final todayStart = DateTime(now.year, now.month, now.day);
  if (dayStart.isBefore(todayStart)) {
    return historicalCacheTtl;
  }
  return todayCacheTtl;
}

/// Cache TTL for an aggregate trend range.
Duration cacheTtlForActivityTrend({
  required DateTime endExclusive,
  required DateTime now,
  required Duration todayCacheTtl,
  required Duration historicalCacheTtl,
}) {
  final todayStart = DateTime(now.year, now.month, now.day);
  if (!endExclusive.isAfter(todayStart)) {
    return historicalCacheTtl;
  }
  return todayCacheTtl;
}
