import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/health/data/health_steps_service.dart';
import 'package:yamt/features/health/data/health_steps_service_stub.dart'
    if (dart.library.io) 'package:yamt/features/health/data/health_steps_service_mobile.dart'
    as implementation;

part 'health_steps_service_provider.g.dart';

/// Health steps service.
@Riverpod(keepAlive: true)
HealthStepsService healthStepsService(Ref ref) {
  return implementation.createHealthStepsService();
}
