import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

part 'calorie_health_connection_actions.g.dart';

/// Calorie-aware Health Connect actions.
@riverpod
CalorieHealthConnectionActions calorieHealthConnectionActions(Ref ref) {
  final healthController = ref.read(
    healthConnectionControllerProvider.notifier,
  );

  Future<HealthConnectionStatus> trackReadyStatus(
    Future<HealthConnectionStatus> Function() action,
  ) async {
    final status = await action();
    if (status.accessState != HealthDataAccessState.ready || !ref.mounted) {
      return status;
    }
    await ref
        .read(calorieGoalControllerProvider.notifier)
        .markActivityTrackingStarted();
    return status;
  }

  return CalorieHealthConnectionActions(
    connect: () => trackReadyStatus(healthController.connect),
    requestAuthorization: () {
      return trackReadyStatus(healthController.requestAuthorization);
    },
    requestHistoryAuthorization: () {
      return trackReadyStatus(healthController.requestHistoryAuthorization);
    },
    installHealthConnect: () {
      return trackReadyStatus(healthController.installHealthConnect);
    },
    openHealthPermissionSettings: () {
      return trackReadyStatus(healthController.openHealthPermissionSettings);
    },
    openAppPermissionSettings: () {
      return trackReadyStatus(healthController.openAppPermissionSettings);
    },
    disconnect: healthController.disconnect,
  );
}

/// Health Connect actions that keep calorie settings in sync.
class CalorieHealthConnectionActions {
  /// Creates actions.
  const CalorieHealthConnectionActions({
    required this.connect,
    required this.requestAuthorization,
    required this.requestHistoryAuthorization,
    required this.installHealthConnect,
    required this.openHealthPermissionSettings,
    required this.openAppPermissionSettings,
    required this.disconnect,
  });

  /// Connect.
  final Future<HealthConnectionStatus> Function() connect;

  /// Request authorization.
  final Future<HealthConnectionStatus> Function() requestAuthorization;

  /// Request history authorization.
  final Future<HealthConnectionStatus> Function() requestHistoryAuthorization;

  /// Install Health Connect.
  final Future<HealthConnectionStatus> Function() installHealthConnect;

  /// Open Health Connect permission settings.
  final Future<HealthConnectionStatus> Function() openHealthPermissionSettings;

  /// Open Android app permission settings.
  final Future<HealthConnectionStatus> Function() openAppPermissionSettings;

  /// Disconnect.
  final Future<HealthDisconnectResult> Function() disconnect;
}
