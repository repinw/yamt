import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_stub.dart'
    if (dart.library.io) 'package:yamt/features/health/data/health_weight_service_mobile.dart'
    as implementation;

part 'health_weight_service_provider.g.dart';

/// Health weight service.
@Riverpod(keepAlive: true)
HealthWeightService healthWeightService(Ref ref) {
  return implementation.createHealthWeightService();
}
