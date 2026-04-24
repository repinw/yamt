import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';

part 'health_connection_controller.g.dart';

const _logName = 'HealthConnectionController';

/// Defines health connection controller.
@riverpod
class HealthConnectionController extends _$HealthConnectionController {
  @override
  FutureOr<HealthConnectionStatus> build() async {
    return _loadStatusFallback(previousStatus: null);
  }

  /// Connect.
  Future<HealthConnectionStatus> connect() async {
    final currentStatus = state.asData?.value;
    if (currentStatus?.needsHistoryOnly ?? false) {
      return requestHistoryAuthorization();
    }
    return requestAuthorization();
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

  /// Disconnect.
  Future<HealthDisconnectResult> disconnect() async {
    final previousStatus = state.asData?.value;
    state = const AsyncLoading<HealthConnectionStatus>();

    try {
      final service = ref.read(healthConnectionServiceProvider);
      final result = await service.disconnect();
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
      return await ref.read(healthConnectionServiceProvider).loadStatus();
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
    final previousStatus = state.asData?.value;
    state = const AsyncLoading<HealthConnectionStatus>();

    try {
      final nextStatus = await action();
      await _markActivityTrackingStartedIfReady(nextStatus);
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

  Future<void> _markActivityTrackingStartedIfReady(
    HealthConnectionStatus status,
  ) async {
    if (status.accessState != HealthDataAccessState.ready || !ref.mounted) {
      return;
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    final settings = await repository.readSettings();
    if (!ref.mounted || settings.activityTrackingStartDate != null) {
      return;
    }

    await repository.saveSettings(
      settings.markActivityTrackingStarted(DateTime.now()),
    );
  }
}
