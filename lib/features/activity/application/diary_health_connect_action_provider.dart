import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

part 'diary_health_connect_action_provider.g.dart';

/// Health Connect action state for diary activity cards.
@immutable
class DiaryHealthConnectActionData {
  /// Creates Health Connect action state.
  const DiaryHealthConnectActionData({
    required this.accessState,
    required this.hasConnectionError,
    required this.isBusy,
    required this.action,
  });

  /// Effective access state to render.
  final HealthDataAccessState accessState;

  /// Whether the latest connection attempt ended with an error.
  final bool hasConnectionError;

  /// Whether Health Connect state is currently loading.
  final bool isBusy;

  /// Optional action that resolves the current access state.
  final Future<void> Function()? action;
}

/// Resolves the Health Connect card state and action.
@riverpod
DiaryHealthConnectActionData diaryHealthConnectAction(
  Ref ref,
  HealthDataAccessState fallbackAccessState,
) {
  final statusState = ref.watch(healthConnectionControllerProvider);
  final controller = ref.read(healthConnectionControllerProvider.notifier);
  final status = statusState.value;
  final latestAccessState = status?.accessState;
  final hasConnectionError = status?.errorMessage != null;
  final needsAppPermissionSettings =
      status?.errorMessage == healthActivityRecognitionPermissionErrorMessage;
  final resolvedAccessState = switch (latestAccessState) {
    HealthDataAccessState.ready => HealthDataAccessState.ready,
    HealthDataAccessState.unsupported => fallbackAccessState,
    null => fallbackAccessState,
    _ => latestAccessState,
  };
  final isBusy = statusState.isLoading;
  final action = switch (resolvedAccessState) {
    HealthDataAccessState.permissionRequired ||
    HealthDataAccessState.historyRequired =>
      hasConnectionError
          ? needsAppPermissionSettings
                ? controller.openAppPermissionSettings
                : controller.openHealthPermissionSettings
          : controller.connect,
    HealthDataAccessState.installRequired => controller.installHealthConnect,
    HealthDataAccessState.ready || HealthDataAccessState.unsupported => null,
  };

  return DiaryHealthConnectActionData(
    accessState: resolvedAccessState,
    hasConnectionError: hasConnectionError,
    isBusy: isBusy,
    action: isBusy ? null : action,
  );
}
