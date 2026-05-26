import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// In-memory cache entry for one diary health day.
class DiaryHealthDayCacheEntry {
  /// Creates a day cache entry.
  const DiaryHealthDayCacheEntry({
    required this.dayStart,
    required this.loadedAt,
    required this.checkedAt,
    required this.data,
  });

  /// Normalized local day start.
  final DateTime dayStart;

  /// Time when Health data was loaded.
  final DateTime loadedAt;

  /// Time when the entry was last validated or reused.
  final DateTime checkedAt;

  /// Cached day data.
  final DiaryHealthDayData data;
}

/// In-memory cache entry for aggregated diary activity trend days.
class DiaryHealthActivityTrendCacheEntry {
  /// Creates an activity trend cache entry.
  const DiaryHealthActivityTrendCacheEntry({
    required this.startInclusive,
    required this.endExclusive,
    required this.loadedAt,
    required this.checkedAt,
    required this.days,
  });

  /// Normalized range start.
  final DateTime startInclusive;

  /// Normalized exclusive range end.
  final DateTime endExclusive;

  /// Time when Health data was loaded.
  final DateTime loadedAt;

  /// Time when the entry was last validated or reused.
  final DateTime checkedAt;

  /// Cached derived activity trend totals.
  final List<DiaryHealthActivityTrendDay> days;
}
