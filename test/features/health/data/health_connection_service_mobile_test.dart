import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_connection_service_mobile.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

void main() {
  test(
    'loadStatus treats iOS weight write permission as granted access',
    () async {
      final fakeHealth = _FakeHealth(hasPermissionsResult: true);
      final service = MobileHealthConnectionService(
        health: fakeHealth,
        isAndroid: false,
        isIOS: true,
      );

      final status = await service.loadStatus();

      expect(status.platform, HealthPlatform.ios);
      expect(status.permissionState, HealthPermissionState.granted);
      expect(status.accessState, HealthDataAccessState.ready);
      expect(fakeHealth.lastHasPermissionsTypes, <HealthDataType>[
        HealthDataType.WEIGHT,
      ]);
      expect(fakeHealth.lastHasPermissionsAccess, <HealthDataAccess>[
        HealthDataAccess.WRITE,
      ]);
    },
  );

  test(
    'requestAuthorization keeps iOS access blocked without weight write',
    () async {
      final fakeHealth = _FakeHealth(
        hasPermissionsResult: false,
        requestAuthorizationResult: true,
      );
      final service = MobileHealthConnectionService(
        health: fakeHealth,
        isAndroid: false,
        isIOS: true,
      );

      final status = await service.requestAuthorization();

      expect(status.permissionState, HealthPermissionState.notGranted);
      expect(status.accessState, HealthDataAccessState.permissionRequired);
      expect(fakeHealth.requestAuthorizationCallCount, 1);
    },
  );
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.hasPermissionsResult,
    this.requestAuthorizationResult = true,
  });

  final bool? hasPermissionsResult;
  final bool requestAuthorizationResult;

  int requestAuthorizationCallCount = 0;
  List<HealthDataType>? lastHasPermissionsTypes;
  List<HealthDataAccess>? lastHasPermissionsAccess;

  @override
  Future<void> configure() async {}

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    lastHasPermissionsTypes = types;
    lastHasPermissionsAccess = permissions;
    return hasPermissionsResult;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    requestAuthorizationCallCount += 1;
    return requestAuthorizationResult;
  }
}
