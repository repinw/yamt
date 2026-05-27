import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_cache_warmup.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/diary_health_activity_trend_day.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'health_connection_controller.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

void main() {
  test('warms rolling 30 day aggregate cache when Health is ready', () async {
    final beforeToday = normalizeDiaryDay(DateTime.now());
    final settingsRepository = FakeCalorieSettingsRepository();
    final healthService = FakeTrendDiaryHealthService(
      const <String, DiaryHealthDayData>{},
      trendDays: const <DiaryHealthActivityTrendDay>[],
    );
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthStatus: _readyStatus,
      diaryHealthService: healthService,
    );
    addTearDown(container.dispose);
    addTearDown(settingsRepository.dispose);

    container.read(calorieHealthActivityCacheWarmupProvider);
    await _loadInputs(container);
    await _flushAsync();
    final afterToday = normalizeDiaryDay(DateTime.now());

    expect(healthService.trendRequests, hasLength(1));
    final request = healthService.trendRequests.single;
    expect(
      request.startInclusive,
      isIn([
        addDiaryDays(beforeToday, -29),
        addDiaryDays(afterToday, -29),
      ]),
    );
    expect(
      request.endExclusive,
      isIn([nextDiaryDay(beforeToday), nextDiaryDay(afterToday)]),
    );
  });

  test('starts warmup at recent tracking boundary', () async {
    final today = normalizeDiaryDay(DateTime.now());
    final trackingStartDate = addDiaryDays(today, -2);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().copyWith(
        activityTrackingStartDate: trackingStartDate,
      ),
    );
    final healthService = FakeTrendDiaryHealthService(
      const <String, DiaryHealthDayData>{},
      trendDays: const <DiaryHealthActivityTrendDay>[],
    );
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthStatus: _readyStatus,
      diaryHealthService: healthService,
    );
    addTearDown(container.dispose);
    addTearDown(settingsRepository.dispose);

    container.read(calorieHealthActivityCacheWarmupProvider);
    await _loadInputs(container);
    await _flushAsync();

    expect(
      healthService.trendRequests.single.startInclusive,
      trackingStartDate,
    );
  });

  test('skips warmup when Health is not ready', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final healthService = FakeTrendDiaryHealthService(
      const <String, DiaryHealthDayData>{},
      trendDays: const <DiaryHealthActivityTrendDay>[],
    );
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthStatus: _permissionRequiredStatus,
      diaryHealthService: healthService,
    );
    addTearDown(container.dispose);
    addTearDown(settingsRepository.dispose);

    container.read(calorieHealthActivityCacheWarmupProvider);
    await _loadInputs(container);
    await _flushAsync();

    expect(healthService.trendRequests, isEmpty);
  });
}

ProviderContainer _buildContainer({
  required FakeCalorieSettingsRepository settingsRepository,
  required HealthConnectionStatus healthStatus,
  required FakeTrendDiaryHealthService diaryHealthService,
}) {
  return ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      healthConnectionServiceProvider.overrideWith(
        (ref) => FakeHealthConnectionService(healthStatus),
      ),
      diaryHealthServiceProvider.overrideWith((ref) => diaryHealthService),
    ],
  );
}

Future<void> _loadInputs(ProviderContainer container) async {
  await container.read(healthConnectionControllerProvider.future);
  await container.read(calorieGoalControllerProvider.future);
}

Future<void> _flushAsync() async {
  for (var index = 0; index < 5; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
