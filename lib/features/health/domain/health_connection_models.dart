enum HealthPlatform { unsupported, android, ios }

enum HealthConnectAvailability {
  notApplicable,
  available,
  notInstalled,
  updateRequired,
}

enum HealthPermissionState { granted, notGranted, unknown }

enum HealthHistoryAccess { notApplicable, granted, notGranted }

enum HealthDataAccessState {
  ready,
  permissionRequired,
  historyRequired,
  installRequired,
  unsupported,
}

enum HealthDisconnectResult { disconnected, openedSettings, unsupported }

class HealthConnectionStatus {
  const HealthConnectionStatus({
    required this.platform,
    required this.healthConnectAvailability,
    required this.permissionState,
    required this.historyAccess,
    this.errorMessage,
  });

  const HealthConnectionStatus.unsupported()
    : platform = HealthPlatform.unsupported,
      healthConnectAvailability = HealthConnectAvailability.notApplicable,
      permissionState = HealthPermissionState.notGranted,
      historyAccess = HealthHistoryAccess.notApplicable,
      errorMessage = null;

  final HealthPlatform platform;
  final HealthConnectAvailability healthConnectAvailability;
  final HealthPermissionState permissionState;
  final HealthHistoryAccess historyAccess;
  final String? errorMessage;

  bool get isSupported => platform != HealthPlatform.unsupported;

  bool get needsInstall =>
      platform == HealthPlatform.android &&
      healthConnectAvailability != HealthConnectAvailability.available;

  bool get needsHistoryOnly =>
      permissionState == HealthPermissionState.granted &&
      historyAccess == HealthHistoryAccess.notGranted;

  HealthDataAccessState get accessState {
    if (!isSupported) {
      return HealthDataAccessState.unsupported;
    }
    if (needsInstall) {
      return HealthDataAccessState.installRequired;
    }
    if (permissionState != HealthPermissionState.granted) {
      return HealthDataAccessState.permissionRequired;
    }
    if (historyAccess == HealthHistoryAccess.notGranted) {
      return HealthDataAccessState.historyRequired;
    }
    return HealthDataAccessState.ready;
  }

  HealthConnectionStatus copyWith({
    HealthPlatform? platform,
    HealthConnectAvailability? healthConnectAvailability,
    HealthPermissionState? permissionState,
    HealthHistoryAccess? historyAccess,
    String? errorMessage,
  }) {
    return HealthConnectionStatus(
      platform: platform ?? this.platform,
      healthConnectAvailability:
          healthConnectAvailability ?? this.healthConnectAvailability,
      permissionState: permissionState ?? this.permissionState,
      historyAccess: historyAccess ?? this.historyAccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
