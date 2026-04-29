import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';

import '../../calories/support/fake_calories_repositories.dart';

const _installRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.notInstalled,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notApplicable,
);

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

const _historyRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.notGranted,
);

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

class _FakeHealthConnectionService implements HealthConnectionService {
  HealthConnectionStatus status = _permissionRequiredStatus;
  HealthDisconnectResult disconnectResult = HealthDisconnectResult.disconnected;
  Future<HealthConnectionStatus> Function()? onLoadStatus;
  Future<HealthConnectionStatus> Function()? onRequestAuthorization;
  Future<HealthConnectionStatus> Function()? onRequestHistoryAuthorization;
  Future<void> Function()? onInstallHealthConnect;
  Future<void> Function()? onOpenAppPermissionSettings;
  Future<void> Function()? onOpenHealthPermissionSettings;
  Future<HealthDisconnectResult> Function()? onDisconnect;
  int loadStatusCallCount = 0;
  int requestAuthorizationCallCount = 0;
  int requestHistoryAuthorizationCallCount = 0;
  int installHealthConnectCallCount = 0;
  int openAppPermissionSettingsCallCount = 0;
  int openHealthPermissionSettingsCallCount = 0;
  int disconnectCallCount = 0;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    disconnectCallCount += 1;
    final handler = onDisconnect;
    if (handler != null) {
      return handler();
    }
    return disconnectResult;
  }

  @override
  Future<void> installHealthConnect() async {
    installHealthConnectCallCount += 1;
    final handler = onInstallHealthConnect;
    if (handler != null) {
      await handler();
    }
  }

  @override
  Future<void> openAppPermissionSettings() async {
    openAppPermissionSettingsCallCount += 1;
    final handler = onOpenAppPermissionSettings;
    if (handler != null) {
      await handler();
    }
  }

  @override
  Future<void> openHealthPermissionSettings() async {
    openHealthPermissionSettingsCallCount += 1;
    final handler = onOpenHealthPermissionSettings;
    if (handler != null) {
      await handler();
    }
  }

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    loadStatusCallCount += 1;
    final handler = onLoadStatus;
    if (handler != null) {
      return handler();
    }
    return status;
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
    final handler = onRequestAuthorization;
    if (handler != null) {
      return handler();
    }
    return status;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    requestHistoryAuthorizationCallCount += 1;
    final handler = onRequestHistoryAuthorization;
    if (handler != null) {
      return handler();
    }
    return status;
  }
}

ProviderContainer _createContainer(_FakeHealthConnectionService service) {
  final calorieSettingsRepository = FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      healthConnectionServiceProvider.overrideWith((ref) => service),
    ],
  );
  addTearDown(calorieSettingsRepository.dispose);
  addTearDown(container.dispose);
  return container;
}

ProviderContainer _createContainerWithHealthServiceFactory(
  HealthConnectionService Function() createService,
) {
  final calorieSettingsRepository = FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      healthConnectionServiceProvider.overrideWith((ref) => createService()),
    ],
  );
  addTearDown(calorieSettingsRepository.dispose);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('build falls back to unsupported status when load fails', () async {
    final service = _FakeHealthConnectionService()
      ..onLoadStatus = () async => throw StateError('load failed');
    final container = _createContainer(service);

    final status = await container.read(
      healthConnectionControllerProvider.future,
    );

    expect(status.accessState, HealthDataAccessState.unsupported);
    expect(status.errorMessage, contains('load failed'));
    expect(
      container
          .read(healthConnectionControllerProvider)
          .requireValue
          .errorMessage,
      contains('load failed'),
    );
  });

  test(
    'requestAuthorization exposes loading and stores returned status',
    () async {
      final requestCompleter = Completer<HealthConnectionStatus>();
      final service = _FakeHealthConnectionService()
        ..status = _permissionRequiredStatus
        ..onRequestAuthorization = () => requestCompleter.future;
      final container = _createContainer(service);
      final sub = container.listen(
        healthConnectionControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(healthConnectionControllerProvider.future);

      final future = container
          .read(healthConnectionControllerProvider.notifier)
          .requestAuthorization();

      expect(
        container.read(healthConnectionControllerProvider).isLoading,
        isTrue,
      );

      requestCompleter.complete(_readyStatus);
      final status = await future;

      expect(status.accessState, HealthDataAccessState.ready);
      expect(service.requestAuthorizationCallCount, 1);
      expect(
        container
            .read(healthConnectionControllerProvider)
            .requireValue
            .accessState,
        HealthDataAccessState.ready,
      );
    },
  );

  test(
    'connect requests history when only history access is missing',
    () async {
      final service = _FakeHealthConnectionService()
        ..status = _historyRequiredStatus
        ..onRequestHistoryAuthorization = () async => _readyStatus;
      final container = _createContainer(service);

      await container.read(healthConnectionControllerProvider.future);
      final status = await container
          .read(healthConnectionControllerProvider.notifier)
          .connect();

      expect(status.accessState, HealthDataAccessState.ready);
      expect(service.requestAuthorizationCallCount, 0);
      expect(service.requestHistoryAuthorizationCallCount, 1);
    },
  );

  test('connect keeps existing service instance', () async {
    var createServiceCallCount = 0;
    final service = _FakeHealthConnectionService()
      ..status = _historyRequiredStatus
      ..onRequestHistoryAuthorization = () async => _readyStatus;
    final container = _createContainerWithHealthServiceFactory(() {
      createServiceCallCount += 1;
      return service;
    });

    await container.read(healthConnectionControllerProvider.future);
    await container.read(healthConnectionControllerProvider.notifier).connect();

    expect(createServiceCallCount, 1);
    expect(service.requestHistoryAuthorizationCallCount, 1);
  });

  test('ready authorization marks activity tracking start day', () async {
    final service = _FakeHealthConnectionService()
      ..status = _permissionRequiredStatus
      ..onRequestAuthorization = () async => _readyStatus;
    final calorieSettingsRepository = FakeCalorieSettingsRepository();
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(
          calorieSettingsRepository,
        ),
        healthConnectionServiceProvider.overrideWith((ref) => service),
      ],
    );
    addTearDown(calorieSettingsRepository.dispose);
    addTearDown(container.dispose);

    final expectedTrackingStartBefore = normalizeDiaryDay(DateTime.now());
    await container.read(healthConnectionControllerProvider.future);
    await container
        .read(healthConnectionControllerProvider.notifier)
        .requestAuthorization();
    final settings = await calorieSettingsRepository.readSettings();
    final expectedTrackingStartAfter = normalizeDiaryDay(DateTime.now());

    expect([
      expectedTrackingStartBefore,
      expectedTrackingStartAfter,
    ], contains(settings.activityTrackingStartDate));
  });

  test(
    'requestAuthorization returns fallback status when service throws',
    () async {
      final service = _FakeHealthConnectionService()
        ..status = _permissionRequiredStatus
        ..onRequestAuthorization = () async =>
            throw StateError('authorization denied');
      final container = _createContainer(service);

      await container.read(healthConnectionControllerProvider.future);
      final status = await container
          .read(healthConnectionControllerProvider.notifier)
          .requestAuthorization();

      expect(status.accessState, HealthDataAccessState.permissionRequired);
      expect(status.errorMessage, contains('authorization denied'));
      expect(
        container
            .read(healthConnectionControllerProvider)
            .requireValue
            .errorMessage,
        contains('authorization denied'),
      );
    },
  );

  test('installHealthConnect stays loading until install finishes', () async {
    final installCompleter = Completer<void>();
    final service = _FakeHealthConnectionService()
      ..status = _installRequiredStatus
      ..onInstallHealthConnect = () => installCompleter.future;
    final container = _createContainer(service);
    final sub = container.listen(healthConnectionControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(healthConnectionControllerProvider.future);

    final future = container
        .read(healthConnectionControllerProvider.notifier)
        .installHealthConnect();

    expect(
      container.read(healthConnectionControllerProvider).isLoading,
      isTrue,
    );

    service.status = _permissionRequiredStatus;
    installCompleter.complete();
    final status = await future;

    expect(service.installHealthConnectCallCount, 1);
    expect(status.accessState, HealthDataAccessState.permissionRequired);
  });

  test(
    'openHealthPermissionSettings reloads status after settings intent',
    () async {
      final service = _FakeHealthConnectionService()
        ..status = _permissionRequiredStatus;
      service.onOpenHealthPermissionSettings = () async {
        service.status = _readyStatus;
      };
      final container = _createContainer(service);

      await container.read(healthConnectionControllerProvider.future);
      final status = await container
          .read(healthConnectionControllerProvider.notifier)
          .openHealthPermissionSettings();

      expect(service.openHealthPermissionSettingsCallCount, 1);
      expect(service.loadStatusCallCount, 2);
      expect(status.accessState, HealthDataAccessState.ready);
      expect(
        container
            .read(healthConnectionControllerProvider)
            .requireValue
            .accessState,
        HealthDataAccessState.ready,
      );
    },
  );

  test(
    'openAppPermissionSettings reloads status after settings intent',
    () async {
      final service = _FakeHealthConnectionService()
        ..status = _permissionRequiredStatus;
      service.onOpenAppPermissionSettings = () async {
        service.status = _readyStatus;
      };
      final container = _createContainer(service);

      await container.read(healthConnectionControllerProvider.future);
      final status = await container
          .read(healthConnectionControllerProvider.notifier)
          .openAppPermissionSettings();

      expect(service.openAppPermissionSettingsCallCount, 1);
      expect(service.loadStatusCallCount, 2);
      expect(status.accessState, HealthDataAccessState.ready);
      expect(
        container
            .read(healthConnectionControllerProvider)
            .requireValue
            .accessState,
        HealthDataAccessState.ready,
      );
    },
  );

  test('disconnect refreshes state after service call', () async {
    final service = _FakeHealthConnectionService()..status = _readyStatus;
    service.onDisconnect = () async {
      service.status = _permissionRequiredStatus;
      return HealthDisconnectResult.disconnected;
    };
    final container = _createContainer(service);

    await container.read(healthConnectionControllerProvider.future);
    final result = await container
        .read(healthConnectionControllerProvider.notifier)
        .disconnect();

    expect(result, HealthDisconnectResult.disconnected);
    expect(service.disconnectCallCount, 1);
    expect(
      container
          .read(healthConnectionControllerProvider)
          .requireValue
          .accessState,
      HealthDataAccessState.permissionRequired,
    );
  });
}
