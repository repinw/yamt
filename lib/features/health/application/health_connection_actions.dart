import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'health_connection_actions.g.dart';

/// Exposes Health connection state to consuming application layers.
@riverpod
Future<HealthConnectionStatus> healthConnectionStatus(Ref ref) {
  return ref.watch(healthConnectionServiceProvider).loadStatus();
}

/// Exposes Health connection actions without exposing its controller.
@Riverpod(keepAlive: true)
HealthConnectionActions healthConnectionActions(Ref ref) {
  return _HealthConnectionActions(ref);
}

/// Health connection actions for feature integrations.
abstract interface class HealthConnectionActions {
  /// Connects or requests the required Health permissions.
  Future<HealthConnectionStatus> connect();

  /// Installs Health Connect and reloads its status.
  Future<HealthConnectionStatus> installHealthConnect();

  /// Opens Health Connect permission settings.
  Future<HealthConnectionStatus> openHealthPermissionSettings();

  /// Opens Android app permission settings.
  Future<HealthConnectionStatus> openAppPermissionSettings();
}

class _HealthConnectionActions implements HealthConnectionActions {
  const _HealthConnectionActions(this._ref);

  final Ref _ref;

  HealthConnectionService get _service {
    return _ref.read(healthConnectionServiceProvider);
  }

  @override
  Future<HealthConnectionStatus> connect() {
    return _run(() async {
      final currentStatus = await _service.loadStatus();
      if (currentStatus.needsHistoryOnly) {
        return _service.requestHistoryAuthorization();
      }
      return _service.requestAuthorization();
    });
  }

  @override
  Future<HealthConnectionStatus> installHealthConnect() {
    return _run(() async {
      await _service.installHealthConnect();
      return _service.loadStatus();
    });
  }

  @override
  Future<HealthConnectionStatus> openHealthPermissionSettings() {
    return _run(() async {
      await _service.openHealthPermissionSettings();
      return _service.loadStatus();
    });
  }

  @override
  Future<HealthConnectionStatus> openAppPermissionSettings() {
    return _run(() async {
      await _service.openAppPermissionSettings();
      return _service.loadStatus();
    });
  }

  Future<HealthConnectionStatus> _run(
    Future<HealthConnectionStatus> Function() action,
  ) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      log(
        'Health connection action failed.',
        name: 'HealthConnectionActions',
        error: error,
        stackTrace: stackTrace,
      );
      return (const HealthConnectionStatus.unsupported()).copyWith(
        errorMessage: error.toString(),
      );
    }
  }
}
