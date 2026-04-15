import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';

part 'health_connection_controller.g.dart';

@riverpod
class HealthConnectionController extends _$HealthConnectionController {
  @override
  FutureOr<HealthConnectionStatus> build() {
    return ref.watch(healthConnectionServiceProvider).loadStatus();
  }

  Future<HealthConnectionStatus> refresh() async {
    return _load(() => ref.read(healthConnectionServiceProvider).loadStatus());
  }

  Future<HealthConnectionStatus> requestAuthorization() async {
    return _load(
      () => ref.read(healthConnectionServiceProvider).requestAuthorization(),
    );
  }

  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    return _load(
      () => ref
          .read(healthConnectionServiceProvider)
          .requestHistoryAuthorization(),
    );
  }

  Future<HealthConnectionStatus> installHealthConnect() async {
    await ref.read(healthConnectionServiceProvider).installHealthConnect();
    return refresh();
  }

  Future<HealthDisconnectResult> disconnect() async {
    final result = await ref.read(healthConnectionServiceProvider).disconnect();
    await refresh();
    return result;
  }

  Future<HealthConnectionStatus> _load(
    Future<HealthConnectionStatus> Function() loader,
  ) async {
    state = const AsyncLoading<HealthConnectionStatus>();
    final next = await AsyncValue.guard(loader);
    if (!ref.mounted) {
      return next.value ?? const HealthConnectionStatus.unsupported();
    }
    state = next;
    if (next.hasError) {
      Error.throwWithStackTrace(next.error!, next.stackTrace!);
    }
    return next.requireValue;
  }
}
