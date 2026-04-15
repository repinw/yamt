import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

HealthConnectionService createHealthConnectionService() {
  return const _UnsupportedHealthConnectionService();
}

class _UnsupportedHealthConnectionService implements HealthConnectionService {
  const _UnsupportedHealthConnectionService();

  @override
  Future<HealthDisconnectResult> disconnect() async {
    return HealthDisconnectResult.unsupported;
  }

  @override
  Future<void> installHealthConnect() async {}

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    return const HealthConnectionStatus.unsupported();
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    return const HealthConnectionStatus.unsupported();
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    return const HealthConnectionStatus.unsupported();
  }
}
