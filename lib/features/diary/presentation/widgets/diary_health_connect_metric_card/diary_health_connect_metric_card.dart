import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_health_connect_metric_card/diary_health_connect_metric_shell.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

/// Compact Health Connect action card for blocked activity data.
class DiaryHealthConnectMetricCard extends ConsumerWidget {
  /// Creates a Health Connect card.
  const DiaryHealthConnectMetricCard({
    required this.accessState,
    super.key,
  });

  /// Current health data access state.
  final HealthDataAccessState accessState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(healthConnectionControllerProvider);
    final controller = ref.read(healthConnectionControllerProvider.notifier);
    final status = statusState.value;
    final latestAccessState = status?.accessState;
    final hasConnectionError = status?.errorMessage != null;
    final needsAppPermissionSettings =
        status?.errorMessage == healthActivityRecognitionPermissionErrorMessage;
    final resolvedAccessState = switch (latestAccessState) {
      HealthDataAccessState.ready => HealthDataAccessState.ready,
      HealthDataAccessState.unsupported => accessState,
      null => accessState,
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
    final effectiveAction = isBusy ? null : action;

    return DiaryHealthConnectMetricShell(
      accessState: resolvedAccessState,
      hasConnectionError: hasConnectionError,
      isBusy: isBusy,
      onPressed: effectiveAction == null
          ? null
          : () => unawaited(effectiveAction()),
    );
  }
}
