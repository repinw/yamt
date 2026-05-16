import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_health_connection_sync.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
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
  test('marks activity tracking start when Health is ready', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: FakeHealthConnectionService(_readyStatus),
    );
    final expectedTrackingStartBefore = normalizeDiaryDay(DateTime.now());

    container.read(calorieHealthConnectionSyncProvider);
    final settings = await _waitForActivityTrackingStart(container);
    final expectedTrackingStartAfter = normalizeDiaryDay(DateTime.now());

    expect([
      expectedTrackingStartBefore,
      expectedTrackingStartAfter,
    ], contains(settings.activityTrackingStartDate));
  });

  test('skips activity tracking start when Health is not ready', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: FakeHealthConnectionService(_permissionRequiredStatus),
    );

    _startSync(container);
    await _loadHealthConnection(container);
    await _loadCalorieGoal(container);
    await _flushAsync();
    final settings = await settingsRepository.readSettings();

    expect(settings.activityTrackingStartDate, isNull);
  });

  test('marks activity tracking start after Health becomes ready', () async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final healthService = _MutableHealthConnectionService(
      initialStatus: _permissionRequiredStatus,
      authorizationStatus: _readyStatus,
    );
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: healthService,
    );
    _startSync(container);
    await _loadHealthConnection(container);

    await container
        .read(healthConnectionControllerProvider.notifier)
        .requestAuthorization();
    final settings = await _waitForActivityTrackingStart(container);

    expect(healthService.requestAuthorizationCallCount, 1);
    expect(settings.activityTrackingStartDate, isNotNull);
  });

  test('keeps app alive when activity tracking start cannot save', () async {
    final settingsRepository = FakeCalorieSettingsRepository()
      ..saveShouldFail = true;
    final container = _buildContainer(
      settingsRepository: settingsRepository,
      healthService: FakeHealthConnectionService(_readyStatus),
    );

    _startSync(container);
    await _loadHealthConnection(container);
    await _loadCalorieGoal(container);
    await _flushAsync();
    final settings = await settingsRepository.readSettings();

    expect(settings.activityTrackingStartDate, isNull);
  });

  test('keeps app alive when activity tracking start throws', () async {
    final container = ProviderContainer(
      overrides: [
        calorieGoalControllerProvider.overrideWith(
          _ThrowingCalorieGoalController.new,
        ),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_readyStatus),
        ),
      ],
    );
    addTearDown(container.dispose);

    _startSync(container);
    await _loadHealthConnection(container);
    await _loadCalorieGoal(container);
    await _flushAsync();
    final settings = container.read(calorieGoalControllerProvider).value;

    expect(settings?.activityTrackingStartDate, isNull);
  });
}

ProviderContainer _buildContainer({
  required FakeCalorieSettingsRepository settingsRepository,
  required HealthConnectionService healthService,
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

void _startSync(ProviderContainer container) {
  container.read(calorieHealthConnectionSyncProvider);
}

Future<HealthConnectionStatus> _loadHealthConnection(
  ProviderContainer container,
) {
  return container.read(healthConnectionControllerProvider.future);
}

Future<CalorieGoalSettings> _loadCalorieGoal(ProviderContainer container) {
  return container.read(calorieGoalControllerProvider.future);
}

Future<CalorieGoalSettings> _waitForActivityTrackingStart(
  ProviderContainer container,
) async {
  final completer = Completer<CalorieGoalSettings>();
  final subscription = container.listen(
    calorieGoalControllerProvider,
    (_, next) {
      final settings = next.asData?.value;
      if (settings?.activityTrackingStartDate != null &&
          !completer.isCompleted) {
        completer.complete(settings);
      }
    },
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  await _loadHealthConnection(container);
  await _loadCalorieGoal(container);
  return completer.future.timeout(const Duration(seconds: 1));
}

Future<void> _flushAsync() async {
  for (var index = 0; index < 5; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _MutableHealthConnectionService implements HealthConnectionService {
  _MutableHealthConnectionService({
    required HealthConnectionStatus initialStatus,
    required HealthConnectionStatus authorizationStatus,
  }) : _status = initialStatus,
       _authorizationStatus = authorizationStatus;

  HealthConnectionStatus _status;
  final HealthConnectionStatus _authorizationStatus;
  int requestAuthorizationCallCount = 0;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    _status = const HealthConnectionStatus.unsupported();
    return HealthDisconnectResult.disconnected;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<HealthConnectionStatus> loadStatus() async => _status;

  @override
  Future<void> openAppPermissionSettings() async {}

  @override
  Future<void> openHealthPermissionSettings() async {}

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
    return _status = _authorizationStatus;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    return _status = _authorizationStatus;
  }
}

class _ThrowingCalorieGoalController extends CalorieGoalController {
  @override
  CalorieGoalSettings build() {
    return const CalorieGoalSettings.empty();
  }

  @override
  Future<bool> markActivityTrackingStarted({DateTime? startedAt}) async {
    throw StateError('settings failed');
  }
}
