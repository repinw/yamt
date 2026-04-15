import 'dart:developer' show log;
import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

const _logName = 'HealthConnectionService';

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

const _androidReconnectRequiresRestartMessage =
    'Restart YAMT after disconnecting Health Connect before reconnecting.';

HealthConnectionService createHealthConnectionService() {
  return MobileHealthConnectionService();
}

class MobileHealthConnectionService implements HealthConnectionService {
  MobileHealthConnectionService({Health? health})
    : _health = health ?? Health();

  final Health _health;
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
    } catch (error, stackTrace) {
      log(
        'Failed to inspect Health Connect status.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return HealthConnectionStatus(
        platform: _platform,
        healthConnectAvailability: Platform.isAndroid
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

    if (Platform.isAndroid) {
      final permission = await Permission.activityRecognition.request();
      if (!permission.isGranted) {
        return (await loadStatus()).copyWith(
          errorMessage: 'Android activity recognition permission not granted.',
        );
      }
    }

    final authorized = await _health.requestAuthorization(
      _authorizationTypes,
      permissions: _authorizationPermissions,
    );
    if (authorized && Platform.isAndroid) {
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
    if (!Platform.isAndroid) {
      return;
    }
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  @override
  Future<HealthDisconnectResult> disconnect() async {
    if (!_isSupportedPlatform) {
      return HealthDisconnectResult.unsupported;
    }

    await _ensureConfigured();
    if (Platform.isAndroid) {
      await _health.revokePermissions();
      _requiresRestartAfterDisconnect = true;
      return HealthDisconnectResult.disconnected;
    }

    final opened = await openAppSettings();
    return opened
        ? HealthDisconnectResult.openedSettings
        : HealthDisconnectResult.unsupported;
  }

  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  HealthPlatform get _platform => Platform.isAndroid
      ? HealthPlatform.android
      : Platform.isIOS
      ? HealthPlatform.ios
      : HealthPlatform.unsupported;

  List<HealthDataType> get _authorizationTypes =>
      Platform.isAndroid ? _androidAuthorizationTypes : _iosAuthorizationTypes;

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

  Future<HealthConnectAvailability> _loadHealthConnectAvailability() async {
    if (!Platform.isAndroid) {
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
    final hasPermissions = await _health.hasPermissions(
      _authorizationTypes,
      permissions: _authorizationPermissions,
    );
    return switch (hasPermissions) {
      true => HealthPermissionState.granted,
      false => HealthPermissionState.notGranted,
      null => HealthPermissionState.unknown,
    };
  }

  Future<HealthHistoryAccess> _loadHistoryAccess() async {
    if (!Platform.isAndroid) {
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
    if (!Platform.isAndroid || !_requiresRestartAfterDisconnect) {
      return status;
    }
    return status.copyWith(
      errorMessage:
          status.errorMessage ?? _androidReconnectRequiresRestartMessage,
    );
  }
}
