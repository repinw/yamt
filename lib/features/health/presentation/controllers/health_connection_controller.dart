import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'health_connection_controller.g.dart';

const _logName = 'HealthConnectionController';

/// Defines health connection controller.
@riverpod
class HealthConnectionController extends _$HealthConnectionController {
  Future<HealthConnectionStatus>? _runningStatusAction;

  @override
  FutureOr<HealthConnectionStatus> build() async {
    return _loadStatusFallback(previousStatus: null);
  }

  /// Connect.
  Future<HealthConnectionStatus> connect() async {
    return _runStatusAction(() async {
      final service = ref.read(healthConnectionServiceProvider);
      final currentStatus = await service.loadStatus();
      if (currentStatus.needsHistoryOnly) {
        return service.requestHistoryAuthorization();
      }
      return service.requestAuthorization();
    });
  }

  /// Request authorization.
  Future<HealthConnectionStatus> requestAuthorization() async {
    return _runStatusAction(
      () => ref.read(healthConnectionServiceProvider).requestAuthorization(),
    );
  }

  /// Request history authorization.
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    return _runStatusAction(
      () => ref
          .read(healthConnectionServiceProvider)
          .requestHistoryAuthorization(),
    );
  }

  /// Install health connect.
  Future<HealthConnectionStatus> installHealthConnect() async {
    return _runStatusAction(() async {
      final service = ref.read(healthConnectionServiceProvider);
      await service.installHealthConnect();
      return service.loadStatus();
    });
  }

  /// Open Health Connect permission settings.
  Future<HealthConnectionStatus> openHealthPermissionSettings() async {
    return _runStatusAction(() async {
      final service = ref.read(healthConnectionServiceProvider);
      await service.openHealthPermissionSettings();
      return service.loadStatus();
    });
  }

  /// Open Android app permission settings.
  Future<HealthConnectionStatus> openAppPermissionSettings() async {
    return _runStatusAction(() async {
      final service = ref.read(healthConnectionServiceProvider);
      await service.openAppPermissionSettings();
      return service.loadStatus();
    });
  }

  /// Disconnect.
  Future<HealthDisconnectResult> disconnect() async {
    final previousStatus = state.asData?.value;
    state = const AsyncLoading<HealthConnectionStatus>();

    try {
      final service = ref.read(healthConnectionServiceProvider);
      final result = await service.disconnect();
      if (!ref.mounted) {
        return result;
      }
      final nextStatus = await _loadStatusFallback(
        previousStatus: previousStatus,
      );
      if (ref.mounted) {
        state = AsyncData(nextStatus);
      }
      return result;
    } on Object catch (error, stackTrace) {
      final fallback = _buildFallbackStatus(
        previousStatus: previousStatus,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(fallback);
      }
      return HealthDisconnectResult.unsupported;
    }
  }

  Future<HealthConnectionStatus> _loadStatusFallback({
    required HealthConnectionStatus? previousStatus,
  }) async {
    try {
      final service = ref.read(healthConnectionServiceProvider);
      final status = await service.loadStatus();
      if (!ref.mounted) {
        return previousStatus ?? status;
      }
      return status;
    } on Object catch (error, stackTrace) {
      return _buildFallbackStatus(
        previousStatus: previousStatus,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<HealthConnectionStatus> _runStatusAction(
    Future<HealthConnectionStatus> Function() action,
  ) async {
    final runningStatusAction = _runningStatusAction;
    if (runningStatusAction != null) {
      return runningStatusAction;
    }

    late final Future<HealthConnectionStatus> nextStatusAction;
    nextStatusAction = _performStatusAction(action).whenComplete(() {
      if (identical(_runningStatusAction, nextStatusAction)) {
        _runningStatusAction = null;
      }
    });
    _runningStatusAction = nextStatusAction;
    return nextStatusAction;
  }

  Future<HealthConnectionStatus> _performStatusAction(
    Future<HealthConnectionStatus> Function() action,
  ) async {
    final previousStatus = state.asData?.value;
    state = const AsyncLoading<HealthConnectionStatus>();

    try {
      final nextStatus = await action();
      if (ref.mounted) {
        state = AsyncData(nextStatus);
      }
      return nextStatus;
    } on Object catch (error, stackTrace) {
      final fallback = _buildFallbackStatus(
        previousStatus: previousStatus,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(fallback);
      }
      return fallback;
    }
  }

  HealthConnectionStatus _buildFallbackStatus({
    required HealthConnectionStatus? previousStatus,
    required Object error,
    required StackTrace stackTrace,
  }) {
    log(
      'Health connection action failed.',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );

    return (previousStatus ?? const HealthConnectionStatus.unsupported())
        .copyWith(errorMessage: error.toString());
  }
}
