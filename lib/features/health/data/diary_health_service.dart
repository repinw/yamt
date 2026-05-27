// Health service stays class-based for provider overrides and test fakes.
// ignore_for_file: one_member_abstracts

import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// Defines diary health service.
abstract interface class DiaryHealthService {
  /// Load day data.
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  });
}

/// Optional day loader that bypasses fresh cache on demand.
abstract interface class DiaryHealthDayRefreshService {
  /// Loads day data from Health and refreshes cache.
  Future<DiaryHealthDayData> refreshDayData({
    required DateTime day,
    double? userHeightCm,
  });
}

/// Optional optimized activity trend loader.
abstract interface class DiaryHealthActivityTrendService {
  /// Loads aggregate activity trend data for local days in the range.
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}

/// Optional aggregate trend loader that bypasses fresh cache on demand.
abstract interface class DiaryHealthActivityTrendRefreshService {
  /// Loads aggregate activity trend data from Health and refreshes cache.
  Future<List<DiaryHealthActivityTrendDay>> refreshActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
