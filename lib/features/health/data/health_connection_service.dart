import 'package:yamt/features/health/domain/health_connection_models.dart';

/// Defines health connection service.
abstract interface class HealthConnectionService {
  /// Load status.
  Future<HealthConnectionStatus> loadStatus();

  /// Request authorization.
  Future<HealthConnectionStatus> requestAuthorization();

  /// Request history authorization.
  Future<HealthConnectionStatus> requestHistoryAuthorization();

  /// Install health connect.
  Future<void> installHealthConnect();

  /// Open health permission settings.
  Future<void> openHealthPermissionSettings();

  /// Opens the Health app of the platform, where the user can delete
  /// weights of other apps. Throws when it cannot open it.
  Future<void> openHealthApp();

  /// Open app permission settings.
  Future<void> openAppPermissionSettings();

  /// Disconnect.
  Future<HealthDisconnectResult> disconnect();
}
