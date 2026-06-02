import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'health_connection_controller.dart';

part 'calorie_health_activity_cache_warmup.g.dart';

const _logName = 'CalorieHealthActivityCacheWarmup';
const _warmupChunkDayCount = 31;
const _activityWarmupDayCount = 30;

/// Warms aggregate Health activity cache for the rolling learning window.
@riverpod
void calorieHealthActivityCacheWarmup(Ref ref) {
  var isWarming = false;
  String? lastCompletedKey;
  String? queuedKey;
  late void Function() scheduleWarmup;

  Future<void> warmIfReady() async {
    if (isWarming || !ref.mounted) {
      return;
    }

    final status = ref.read(healthConnectionControllerProvider).asData?.value;
    final settings = ref.read(calorieGoalControllerProvider).asData?.value;
    if (status?.accessState != HealthDataAccessState.ready ||
        settings == null) {
      return;
    }

    final today = normalizeDiaryDay(DateTime.now());
    final start = _activityCacheStartDate(settings: settings, today: today);
    final endExclusive = nextDiaryDay(today);
    if (!start.isBefore(endExclusive)) {
      return;
    }

    final warmupKey =
        '${start.millisecondsSinceEpoch}:'
        '${endExclusive.millisecondsSinceEpoch}';
    if (warmupKey == lastCompletedKey) {
      return;
    }

    final diaryHealthService = ref.read(diaryHealthServiceProvider);
    final trendService = diaryHealthService is DiaryHealthActivityTrendService
        ? diaryHealthService as DiaryHealthActivityTrendService
        : null;
    if (trendService == null) {
      return;
    }

    isWarming = true;
    queuedKey = null;
    try {
      await _warmActivityCache(
        trendService: trendService,
        startInclusive: start,
        endExclusive: endExclusive,
      );
      if (!ref.mounted) {
        return;
      }
      lastCompletedKey = warmupKey;
      ref.read(calorieOverviewRevisionProvider.notifier).markChanged();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to warm Health activity cache. '
        'start=${start.toIso8601String()} '
        'end=${endExclusive.toIso8601String()}',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isWarming = false;
      if (queuedKey != null && ref.mounted) {
        scheduleWarmup();
      }
    }
  }

  scheduleWarmup = () {
    if (isWarming) {
      final today = normalizeDiaryDay(DateTime.now());
      queuedKey = today.millisecondsSinceEpoch.toString();
      return;
    }
    unawaited(Future<void>.microtask(warmIfReady));
  };

  ref
    ..listen(
      healthConnectionControllerProvider,
      (_, _) => scheduleWarmup(),
      fireImmediately: true,
    )
    ..listen(
      calorieGoalControllerProvider,
      (_, _) => scheduleWarmup(),
      fireImmediately: true,
    );
}

DateTime _activityCacheStartDate({
  required CalorieGoalSettings settings,
  required DateTime today,
}) {
  final trackingStartDate = settings.activityTrackingStartDate;
  final rollingStartDate = addDiaryDays(today, -(_activityWarmupDayCount - 1));
  if (trackingStartDate == null) {
    return rollingStartDate;
  }
  final normalizedTrackingStartDate = normalizeDiaryDay(trackingStartDate);
  if (normalizedTrackingStartDate.isAfter(rollingStartDate)) {
    return normalizedTrackingStartDate;
  }
  return rollingStartDate;
}

Future<void> _warmActivityCache({
  required DiaryHealthActivityTrendService trendService,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) async {
  for (
    var chunkStart = startInclusive;
    chunkStart.isBefore(endExclusive);
    chunkStart = addDiaryDays(chunkStart, _warmupChunkDayCount)
  ) {
    final chunkEndCandidate = addDiaryDays(chunkStart, _warmupChunkDayCount);
    final chunkEnd = chunkEndCandidate.isBefore(endExclusive)
        ? chunkEndCandidate
        : endExclusive;
    await trendService.loadActivityTrendDays(
      startInclusive: chunkStart,
      endExclusive: chunkEnd,
    );
  }
}
