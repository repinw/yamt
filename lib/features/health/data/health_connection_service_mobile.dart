import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:health/health.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

const _logName = 'HealthConnectionService';

const _iosHealthConnectionEnabledPreferenceKey =
    'ios_health_connection_enabled_v1';
const _iosConnectionEnabledValue = '1';
const _iosConnectionDisabledValue = '0';

const _androidAuthorizationTypes = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.WEIGHT,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.WORKOUT,
];

const _iosAuthorizationTypes = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.WEIGHT,
  HealthDataType.WORKOUT,
];
const _iosPermissionStatusTypes = <HealthDataType>[HealthDataType.WEIGHT];
const _iosPermissionStatusPermissions = <HealthDataAccess>[
  HealthDataAccess.WRITE,
];

const _androidReconnectRequiresRestartMessage =
    'Restart YAMT after disconnecting Health Connect before reconnecting.';
const _manageHealthPermissionsAction =
    'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS';
const _healthHomeSettingsAction =
    'android.health.connect.action.HEALTH_HOME_SETTINGS';
const _legacyHealthConnectSettingsAction =
    'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS';
const _intentExtraPackageName = 'android.intent.extra.PACKAGE_NAME';

/// Create health connection service.
HealthConnectionService createHealthConnectionService({
  AppPreferences? preferences,
}) {
  return MobileHealthConnectionService(preferences: preferences);
}

/// Defines mobile health connection service.
class MobileHealthConnectionService implements HealthConnectionService {
  /// Creates an instance.
  MobileHealthConnectionService({
    Health? health,
    AppPreferences? preferences,
    bool? isAndroid,
    bool? isIOS,
    Future<String> Function()? packageNameLoader,
    Future<bool> Function(AndroidIntent intent)? androidIntentLauncher,
    Future<void> Function()? appSettingsLauncher,
  }) : _health = health ?? Health(),
       _preferences = preferences,
       _isAndroid = isAndroid ?? Platform.isAndroid,
       _isIOS = isIOS ?? Platform.isIOS,
       _packageNameLoader = packageNameLoader,
       _androidIntentLauncher = androidIntentLauncher,
       _appSettingsLauncher = appSettingsLauncher;

  final Health _health;
  final AppPreferences? _preferences;
  final bool _isAndroid;
  final bool _isIOS;
  final Future<String> Function()? _packageNameLoader;
  final Future<bool> Function(AndroidIntent intent)? _androidIntentLauncher;
  final Future<void> Function()? _appSettingsLauncher;
  bool _isConfigured = false;
  bool _requiresRestartAfterDisconnect = false;

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    if (!_isSupportedPlatform) {
      return const HealthConnectionStatus.unsupported();
    }

    try {
      await _ensureConfigured();
      final healthConnectAvailability = await _loadHealthConnectAvailability();
      final permissionState = await _loadPermissionState();
      final historyAccess = await _loadHistoryAccess();

      return _applyRestartRequiredMessage(
        HealthConnectionStatus(
          platform: _platform,
          healthConnectAvailability: healthConnectAvailability,
          permissionState: permissionState,
          historyAccess: historyAccess,
        ),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to inspect Health Connect status.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return HealthConnectionStatus(
        platform: _platform,
        healthConnectAvailability: _isAndroid
            ? HealthConnectAvailability.notInstalled
            : HealthConnectAvailability.notApplicable,
        permissionState: HealthPermissionState.unknown,
        historyAccess: HealthHistoryAccess.notApplicable,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    if (!_isSupportedPlatform) {
      return const HealthConnectionStatus.unsupported();
    }

    await _ensureConfigured();
    if (_requiresRestartAfterDisconnect) {
      return _applyRestartRequiredMessage(await loadStatus());
    }

    if (_isAndroid) {
      final permission = await Permission.activityRecognition.request();
      if (!permission.isGranted) {
        if (permission.isPermanentlyDenied || permission.isRestricted) {
          await openAppPermissionSettings();
        }
        return (await loadStatus()).copyWith(
          errorMessage: healthActivityRecognitionPermissionErrorMessage,
        );
      }
    }

    final authorized = await _health.requestAuthorization(
      _authorizationTypes,
      permissions: _authorizationPermissions,
    );
    if (authorized && _isIOS) {
      await _markIosConnectionEnabled();
    }
    if (authorized && _isAndroid) {
      await _requestHistoryIfAvailable();
    }

    final status = await loadStatus();
    if (authorized) {
      return status;
    }
    return status.copyWith(
      errorMessage:
          status.errorMessage ?? 'Health access was not granted by system.',
    );
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    if (!_isSupportedPlatform) {
      return const HealthConnectionStatus.unsupported();
    }

    await _ensureConfigured();
    if (_requiresRestartAfterDisconnect) {
      return _applyRestartRequiredMessage(await loadStatus());
    }

    final authorized = await _health.requestHealthDataHistoryAuthorization();
    final status = await loadStatus();
    if (authorized) {
      return status;
    }
    return status.copyWith(
      errorMessage:
          status.errorMessage ??
          'Historic health access was not granted by system.',
    );
  }

  @override
  Future<void> installHealthConnect() async {
    if (!_isAndroid) {
      return;
    }
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  @override
  Future<void> openHealthPermissionSettings() async {
    if (!_isAndroid) {
      return;
    }

    final packageName = await _loadPackageName();
    if (await _launchAndroidIntent(
      AndroidIntent(
        action: _manageHealthPermissionsAction,
        arguments: <String, Object>{_intentExtraPackageName: packageName},
      ),
    )) {
      return;
    }

    if (await _launchAndroidIntent(
      const AndroidIntent(action: _healthHomeSettingsAction),
    )) {
      return;
    }

    if (await _launchAndroidIntent(
      const AndroidIntent(action: _legacyHealthConnectSettingsAction),
    )) {
      return;
    }

    await installHealthConnect();
  }

  @override
  Future<void> openAppPermissionSettings() async {
    if (!_isAndroid) {
      return;
    }
    final launcher = _appSettingsLauncher;
    if (launcher != null) {
      await launcher();
      return;
    }
    await openAppSettings();
  }

  @override
  Future<HealthDisconnectResult> disconnect() async {
    if (!_isSupportedPlatform) {
      return HealthDisconnectResult.unsupported;
    }

    await _ensureConfigured();
    if (_isAndroid) {
      await _health.revokePermissions();
      _requiresRestartAfterDisconnect = true;
      return HealthDisconnectResult.disconnected;
    }

    // HealthKit access cannot be revoked programmatically on iOS, so
    // disconnect Apple Health locally inside YAMT instead.
    await _markIosConnectionDisabled();
    return HealthDisconnectResult.disconnected;
  }

  bool get _isSupportedPlatform => _isAndroid || _isIOS;

  HealthPlatform get _platform => _isAndroid
      ? HealthPlatform.android
      : _isIOS
      ? HealthPlatform.ios
      : HealthPlatform.unsupported;

  List<HealthDataType> get _authorizationTypes =>
      _isAndroid ? _androidAuthorizationTypes : _iosAuthorizationTypes;

  List<HealthDataAccess> get _authorizationPermissions =>
      _authorizationTypes.map(_authorizationAccessForType).toList();

  HealthDataAccess _authorizationAccessForType(HealthDataType type) {
    return switch (type) {
      HealthDataType.WEIGHT => HealthDataAccess.READ_WRITE,
      _ => HealthDataAccess.READ,
    };
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }
    await _health.configure();
    _isConfigured = true;
  }

  Future<void> _requestHistoryIfAvailable() async {
    final historyAvailable = await _health.isHealthDataHistoryAvailable();
    if (!historyAvailable) {
      return;
    }
    await _health.requestHealthDataHistoryAuthorization();
  }

  Future<bool> _launchAndroidIntent(AndroidIntent intent) async {
    try {
      final launcher = _androidIntentLauncher;
      if (launcher != null) {
        return await launcher(intent);
      }

      await intent.launch();
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to open Health Connect settings intent.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<String> _loadPackageName() async {
    final packageNameLoader = _packageNameLoader;
    if (packageNameLoader != null) {
      return packageNameLoader();
    }
    return (await PackageInfo.fromPlatform()).packageName;
  }

  Future<HealthConnectAvailability> _loadHealthConnectAvailability() async {
    if (!_isAndroid) {
      return HealthConnectAvailability.notApplicable;
    }
    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable =>
        HealthConnectAvailability.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        HealthConnectAvailability.updateRequired,
      HealthConnectSdkStatus.sdkUnavailable ||
      null => HealthConnectAvailability.notInstalled,
    };
  }

  Future<HealthPermissionState> _loadPermissionState() async {
    if (_isIOS) {
      if (!await _isIosConnectionEnabled()) {
        return HealthPermissionState.notGranted;
      }

      // HealthKit does not reveal read authorization status on iOS.
      // Use the required weight write permission as the best available
      // signal for whether YAMT currently has usable Apple Health access.
      final hasPermissions = await _health.hasPermissions(
        _iosPermissionStatusTypes,
        permissions: _iosPermissionStatusPermissions,
      );
      return _permissionStateFromHasPermissions(hasPermissions);
    }

    final hasPermissions = await _health.hasPermissions(
      _authorizationTypes,
      permissions: _authorizationPermissions,
    );
    return _permissionStateFromHasPermissions(hasPermissions);
  }

  Future<HealthHistoryAccess> _loadHistoryAccess() async {
    if (!_isAndroid) {
      return HealthHistoryAccess.notApplicable;
    }
    final historyAvailable = await _health.isHealthDataHistoryAvailable();
    if (!historyAvailable) {
      return HealthHistoryAccess.notApplicable;
    }
    final historyAuthorized = await _health.isHealthDataHistoryAuthorized();
    return historyAuthorized
        ? HealthHistoryAccess.granted
        : HealthHistoryAccess.notGranted;
  }

  HealthConnectionStatus _applyRestartRequiredMessage(
    HealthConnectionStatus status,
  ) {
    if (!_isAndroid || !_requiresRestartAfterDisconnect) {
      return status;
    }
    return status.copyWith(
      errorMessage:
          status.errorMessage ?? _androidReconnectRequiresRestartMessage,
    );
  }

  Future<bool> _isIosConnectionEnabled() async {
    if (!_isIOS || _preferences == null) {
      return true;
    }
    final value = await _preferences.getString(
      _iosHealthConnectionEnabledPreferenceKey,
    );
    return value != _iosConnectionDisabledValue;
  }

  Future<void> _markIosConnectionEnabled() async {
    if (!_isIOS || _preferences == null) {
      return;
    }
    await _preferences.setString(
      _iosHealthConnectionEnabledPreferenceKey,
      _iosConnectionEnabledValue,
    );
  }

  Future<void> _markIosConnectionDisabled() async {
    if (!_isIOS || _preferences == null) {
      return;
    }
    await _preferences.setString(
      _iosHealthConnectionEnabledPreferenceKey,
      _iosConnectionDisabledValue,
    );
  }
}

HealthPermissionState _permissionStateFromHasPermissions(bool? hasPermissions) {
  return switch (hasPermissions) {
    true => HealthPermissionState.granted,
    false => HealthPermissionState.notGranted,
    null => HealthPermissionState.unknown,
  };
}
