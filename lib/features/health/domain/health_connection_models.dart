/// Defines health platform.
enum HealthPlatform {
  /// Unsupported.
  unsupported,

  /// Android.
  android,

  /// Ios.
  ios,
}

/// Defines health connect availability.
enum HealthConnectAvailability {
  /// Documented member.
  notApplicable,

  /// Documented member.
  available,

  /// Documented member.
  notInstalled,

  /// Documented member.
  updateRequired,
}

/// Defines health permission state.
enum HealthPermissionState {
  /// Granted.
  granted,

  /// Not granted.
  notGranted,

  /// Unknown.
  unknown,
}

/// Defines health history access.
enum HealthHistoryAccess {
  /// Not applicable.
  notApplicable,

  /// Granted.
  granted,

  /// Not granted.
  notGranted,
}

/// Defines health data access state.
enum HealthDataAccessState {
  /// Documented member.
  ready,

  /// Documented member.
  permissionRequired,

  /// Documented member.
  historyRequired,

  /// Documented member.
  installRequired,

  /// Documented member.
  unsupported,
}

/// Defines health disconnect result.
enum HealthDisconnectResult {
  /// Disconnected.
  disconnected,

  /// Opened settings.
  openedSettings,

  /// Unsupported.
  unsupported,
}

/// Defines health connection status.
class HealthConnectionStatus {
  /// The health connection status.
  const HealthConnectionStatus({
    required this.platform,
    required this.healthConnectAvailability,
    required this.permissionState,
    required this.historyAccess,
    this.errorMessage,
  });

  /// Creates a [HealthConnectionStatus] for unsupported.
  const HealthConnectionStatus.unsupported()
    : platform = HealthPlatform.unsupported,
      healthConnectAvailability = HealthConnectAvailability.notApplicable,
      permissionState = HealthPermissionState.notGranted,
      historyAccess = HealthHistoryAccess.notApplicable,
      errorMessage = null;

  /// The platform.
  final HealthPlatform platform;

  /// The health connect availability.
  final HealthConnectAvailability healthConnectAvailability;

  /// The permission state.
  final HealthPermissionState permissionState;

  /// The history access.
  final HealthHistoryAccess historyAccess;

  /// The error message.
  final String? errorMessage;

  /// Whether supported.
  bool get isSupported => platform != HealthPlatform.unsupported;

  /// Whether install.
  bool get needsInstall =>
      platform == HealthPlatform.android &&
      healthConnectAvailability != HealthConnectAvailability.available;

  /// Whether history only.
  bool get needsHistoryOnly =>
      permissionState == HealthPermissionState.granted &&
      historyAccess == HealthHistoryAccess.notGranted;

  /// The access state.
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

  /// Copy with.
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
