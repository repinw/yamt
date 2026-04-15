import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_connection_service_stub.dart'
    if (dart.library.io) 'package:yamt/features/health/data/health_connection_service_mobile.dart'
    as implementation;

part 'health_connection_service_provider.g.dart';

@Riverpod(keepAlive: true)
HealthConnectionService healthConnectionService(Ref ref) {
  return implementation.createHealthConnectionService();
}
