import 'package:health/health.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/diary_health_activity_trend_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_day_cache_store.dart';
import 'package:yamt/features/health/data/diary_health_mobile_activity_trend_loader.dart';
import 'package:yamt/features/health/data/diary_health_mobile_config.dart';
import 'package:yamt/features/health/data/diary_health_mobile_day_loader.dart';
import 'package:yamt/features/health/data/diary_health_mobile_health_reader.dart';
import 'package:yamt/features/health/data/diary_health_read_queue.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';

/// Create diary health service.
DiaryHealthService createDiaryHealthService({AppPreferences? preferences}) {
  return MobileDiaryHealthService(preferences: preferences);
}

/// Mobile implementation of diary health data access.
class MobileDiaryHealthService
    implements DiaryHealthService, DiaryHealthActivityTrendService {
  /// Creates an instance.
  MobileDiaryHealthService({
    Health? health,
    AppPreferences? preferences,
    DateTime Function()? now,
    Duration cacheTtl = diaryHealthTodayCacheTtl,
    Duration historicalCacheTtl = diaryHealthHistoricalCacheTtl,
  }) : _health = health ?? Health(),
       _now = now ?? DateTime.now {
    final readQueue = DiaryHealthReadQueue();
    final healthReader = DiaryHealthMobileHealthReader(
      health: _health,
      readQueue: readQueue,
      ensureConfigured: _ensureConfigured,
    );
    _activityTrendLoader = DiaryHealthMobileActivityTrendLoader(
      healthReader: healthReader,
      now: _now,
      todayCacheTtl: cacheTtl,
      historicalCacheTtl: historicalCacheTtl,
      cacheStore: preferences == null
          ? null
          : DiaryHealthActivityTrendDayCacheStore(
              preferences: preferences,
              maxEntries: maxActivityTrendCacheEntries,
            ),
    );
    _dayLoader = DiaryHealthMobileDayLoader(
      healthReader: healthReader,
      activityTrendLoader: _activityTrendLoader,
      now: _now,
      todayCacheTtl: cacheTtl,
      historicalCacheTtl: historicalCacheTtl,
      cacheStore: preferences == null
          ? null
          : DiaryHealthDayCacheStore(
              preferences: preferences,
              maxEntries: maxDiaryHealthCacheEntries,
            ),
    );
  }

  final Health _health;
  final DateTime Function() _now;
  late final DiaryHealthMobileDayLoader _dayLoader;
  late final DiaryHealthMobileActivityTrendLoader _activityTrendLoader;

  bool _isConfigured = false;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) {
    return _dayLoader.loadDayData(day: day, userHeightCm: userHeightCm);
  }

  @override
  Future<List<DiaryHealthActivityTrendDay>> loadActivityTrendDays({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _activityTrendLoader.loadActivityTrendDays(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }
}
