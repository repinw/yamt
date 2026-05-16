import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/application/diary_health_connect_action_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _permissionRequiredWithAppSettingsError = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
  errorMessage: healthActivityRecognitionPermissionErrorMessage,
);

const _installRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.notInstalled,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notApplicable,
);

void main() {
  test('ready status exposes no action', () async {
    final controller = _FakeHealthConnectionController(_readyStatus);
    final container = _container(controller);

    await container.read(healthConnectionControllerProvider.future);
    final data = container.read(
      diaryHealthConnectActionProvider(
        HealthDataAccessState.permissionRequired,
      ),
    );

    expect(data.accessState, HealthDataAccessState.ready);
    expect(data.hasConnectionError, isFalse);
    expect(data.isBusy, isFalse);
    expect(data.action, isNull);
  });

  test('permission error action opens Android app settings', () async {
    final controller = _FakeHealthConnectionController(
      _permissionRequiredWithAppSettingsError,
    );
    final container = _container(controller);

    await container.read(healthConnectionControllerProvider.future);
    final data = container.read(
      diaryHealthConnectActionProvider(HealthDataAccessState.unsupported),
    );
    await data.action?.call();

    expect(data.accessState, HealthDataAccessState.permissionRequired);
    expect(data.hasConnectionError, isTrue);
    expect(controller._openAppPermissionSettingsCallCount, 1);
    expect(controller._openHealthPermissionSettingsCallCount, 0);
    expect(controller._connectCallCount, 0);
  });

  test('install required action installs Health Connect', () async {
    final controller = _FakeHealthConnectionController(_installRequiredStatus);
    final container = _container(controller);

    await container.read(healthConnectionControllerProvider.future);
    final data = container.read(
      diaryHealthConnectActionProvider(HealthDataAccessState.unsupported),
    );
    await data.action?.call();

    expect(data.accessState, HealthDataAccessState.installRequired);
    expect(data.hasConnectionError, isFalse);
    expect(controller._installHealthConnectCallCount, 1);
    expect(controller._connectCallCount, 0);
  });
}

ProviderContainer _container(_FakeHealthConnectionController controller) {
  final container = ProviderContainer(
    overrides: [
      healthConnectionControllerProvider.overrideWith(() => controller),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeHealthConnectionController extends HealthConnectionController {
  _FakeHealthConnectionController(this._status);

  final HealthConnectionStatus _status;
  int _connectCallCount = 0;
  int _installHealthConnectCallCount = 0;
  int _openAppPermissionSettingsCallCount = 0;
  int _openHealthPermissionSettingsCallCount = 0;

  @override
  FutureOr<HealthConnectionStatus> build() => _status;

  @override
  Future<HealthConnectionStatus> connect() async {
    _connectCallCount += 1;
    return _status;
  }

  @override
  Future<HealthConnectionStatus> installHealthConnect() async {
    _installHealthConnectCallCount += 1;
    return _status;
  }

  @override
  Future<HealthConnectionStatus> openAppPermissionSettings() async {
    _openAppPermissionSettingsCallCount += 1;
    return _status;
  }

  @override
  Future<HealthConnectionStatus> openHealthPermissionSettings() async {
    _openHealthPermissionSettingsCallCount += 1;
    return _status;
  }
}
