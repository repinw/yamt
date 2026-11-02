import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'health_connection_actions.g.dart';

/// Exposes Health connection state to consuming application layers.
@riverpod
Future<HealthConnectionStatus> healthConnectionStatus(Ref ref) {
  return ref.watch(healthConnectionServiceProvider).loadStatus();
}
