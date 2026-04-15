import 'package:yamt/features/health/domain/health_connection_models.dart';

abstract interface class HealthConnectionService {
  Future<HealthConnectionStatus> loadStatus();

  Future<HealthConnectionStatus> requestAuthorization();

  Future<HealthConnectionStatus> requestHistoryAuthorization();

  Future<void> installHealthConnect();

  Future<HealthDisconnectResult> disconnect();
}
