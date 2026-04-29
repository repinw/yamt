import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:yamt/features/health/data/health_connection_service_mobile.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

import '../../../helpers/memory_app_preferences.dart';

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
    'requestAuthorization keeps iOS not granted without weight write',
    () async {
      final preferences = MemoryAppPreferences();
      final fakeHealth = _FakeHealth(hasPermissionsResult: false);
      final service = MobileHealthConnectionService(
        health: fakeHealth,
        preferences: preferences,
        isAndroid: false,
        isIOS: true,
      );

      final status = await service.requestAuthorization();

      expect(status.permissionState, HealthPermissionState.notGranted);
      expect(status.accessState, HealthDataAccessState.permissionRequired);
      expect(fakeHealth.requestAuthorizationCallCount, 1);
      expect(
        await preferences.getString('ios_health_connection_enabled_v1'),
        '1',
      );
    },
  );

  test('loadStatus ignores stale remembered iOS authorization', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        'ios_health_authorization_requested_v1': '1',
        'ios_health_connection_enabled_v1': '1',
      },
    );
    final fakeHealth = _FakeHealth(hasPermissionsResult: false);
    final service = MobileHealthConnectionService(
      health: fakeHealth,
      preferences: preferences,
      isAndroid: false,
      isIOS: true,
    );

    final status = await service.loadStatus();

    expect(status.permissionState, HealthPermissionState.notGranted);
    expect(status.accessState, HealthDataAccessState.permissionRequired);
  });

  test('disconnect on iOS disables local Apple Health access', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        'ios_health_connection_enabled_v1': '1',
      },
    );
    final fakeHealth = _FakeHealth(hasPermissionsResult: true);
    final service = MobileHealthConnectionService(
      health: fakeHealth,
      preferences: preferences,
      isAndroid: false,
      isIOS: true,
    );

    final result = await service.disconnect();
    final status = await service.loadStatus();

    expect(result, HealthDisconnectResult.disconnected);
    expect(status.permissionState, HealthPermissionState.notGranted);
    expect(status.accessState, HealthDataAccessState.permissionRequired);
    expect(
      await preferences.getString('ios_health_connection_enabled_v1'),
      '0',
    );
  });

  test('requestAuthorization re-enables local Apple Health access', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        'ios_health_connection_enabled_v1': '0',
      },
    );
    final fakeHealth = _FakeHealth(hasPermissionsResult: true);
    final service = MobileHealthConnectionService(
      health: fakeHealth,
      preferences: preferences,
      isAndroid: false,
      isIOS: true,
    );

    final status = await service.requestAuthorization();

    expect(status.permissionState, HealthPermissionState.granted);
    expect(status.accessState, HealthDataAccessState.ready);
    expect(
      await preferences.getString('ios_health_connection_enabled_v1'),
      '1',
    );
  });

  test(
    'openHealthPermissionSettings launches manage permissions intent first',
    () async {
      final launchedIntents = <AndroidIntent>[];
      final service = MobileHealthConnectionService(
        health: _FakeHealth(hasPermissionsResult: true),
        isAndroid: true,
        isIOS: false,
        packageNameLoader: () async => 'de.yamt.app',
        androidIntentLauncher: (intent) async {
          launchedIntents.add(intent);
          return true;
        },
      );

      await service.openHealthPermissionSettings();

      expect(launchedIntents, hasLength(1));
      expect(
        launchedIntents.single.action,
        'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS',
      );
      expect(launchedIntents.single.arguments, {
        'android.intent.extra.PACKAGE_NAME': 'de.yamt.app',
      });
    },
  );

  test(
    'openHealthPermissionSettings falls back through settings intents '
    'to install',
    () async {
      final fakeHealth = _FakeHealth(hasPermissionsResult: true);
      final launchedActions = <String?>[];
      final service = MobileHealthConnectionService(
        health: fakeHealth,
        isAndroid: true,
        isIOS: false,
        packageNameLoader: () async => 'de.yamt.app',
        androidIntentLauncher: (intent) async {
          launchedActions.add(intent.action);
          return false;
        },
      );

      await service.openHealthPermissionSettings();

      expect(launchedActions, [
        'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS',
        'android.health.connect.action.HEALTH_HOME_SETTINGS',
        'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
      ]);
      expect(fakeHealth.installHealthConnectCallCount, 1);
    },
  );

  test(
    'openAppPermissionSettings uses injected app settings launcher',
    () async {
      var openAppSettingsCallCount = 0;
      final service = MobileHealthConnectionService(
        health: _FakeHealth(hasPermissionsResult: true),
        isAndroid: true,
        isIOS: false,
        appSettingsLauncher: () async {
          openAppSettingsCallCount += 1;
        },
      );

      await service.openAppPermissionSettings();

      expect(openAppSettingsCallCount, 1);
    },
  );

  test(
    'openHealthPermissionSettings uses app settings launcher on iOS',
    () async {
      var openAppSettingsCallCount = 0;
      final service = MobileHealthConnectionService(
        health: _FakeHealth(hasPermissionsResult: true),
        isAndroid: false,
        isIOS: true,
        appSettingsLauncher: () async {
          openAppSettingsCallCount += 1;
        },
      );

      await service.openHealthPermissionSettings();

      expect(openAppSettingsCallCount, 1);
    },
  );
}

class _FakeHealth extends Health {
  _FakeHealth({required this.hasPermissionsResult});

  final bool? hasPermissionsResult;

  int requestAuthorizationCallCount = 0;
  int installHealthConnectCallCount = 0;
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
    return true;
  }

  @override
  Future<void> installHealthConnect() async {
    installHealthConnectCallCount += 1;
  }
}
