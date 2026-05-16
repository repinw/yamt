import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_health_connection_actions.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

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

ProviderContainer _buildContainer({
  required FakeCalorieSettingsRepository settingsRepository,
  required FakeHealthConnectionService healthService,
}) {
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(
        settingsRepository,
      ),
      healthConnectionServiceProvider.overrideWith((ref) => healthService),
    ],
  );
  addTearDown(settingsRepository.dispose);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('requestAuthorization marks activity tracking start day', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: FakeHealthConnectionService(_readyStatus),
    );

    final expectedTrackingStartBefore = normalizeDiaryDay(DateTime.now());
    await container
        .read(calorieHealthConnectionActionsProvider)
        .requestAuthorization();
    final settings = await settingsRepository.readSettings();
    final expectedTrackingStartAfter = normalizeDiaryDay(DateTime.now());

    expect([
      expectedTrackingStartBefore,
      expectedTrackingStartAfter,
    ], contains(settings.activityTrackingStartDate));
  });

  test(
    'requestAuthorization skips start day when access is not ready',
    () async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final container = _buildContainer(
        settingsRepository: settingsRepository,
        healthService: FakeHealthConnectionService(_permissionRequiredStatus),
      );

      await container
          .read(calorieHealthConnectionActionsProvider)
          .requestAuthorization();
      final settings = await settingsRepository.readSettings();

      expect(settings.activityTrackingStartDate, isNull);
    },
  );

  test('delegates Health Connect actions through health controller', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final healthService = FakeHealthConnectionService(_readyStatus);
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: healthService,
    );
    final actions = container.read(calorieHealthConnectionActionsProvider);

    await actions.connect();
    await actions.requestHistoryAuthorization();
    await actions.installHealthConnect();
    await actions.openHealthPermissionSettings();
    await actions.openAppPermissionSettings();
    final disconnectResult = await actions.disconnect();
    final settings = await settingsRepository.readSettings();

    expect(healthService.requestAuthorizationCallCount, 1);
    expect(healthService.requestHistoryAuthorizationCallCount, 1);
    expect(healthService.installHealthConnectCallCount, 1);
    expect(healthService.openHealthPermissionSettingsCallCount, 1);
    expect(healthService.openAppPermissionSettingsCallCount, 1);
    expect(disconnectResult, HealthDisconnectResult.disconnected);
    expect(settings.activityTrackingStartDate, isNotNull);
  });
}
