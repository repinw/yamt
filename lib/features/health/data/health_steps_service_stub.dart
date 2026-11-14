import 'package:yamt/features/health/data/health_steps_service.dart';

/// Create health steps service.
HealthStepsService createHealthStepsService() {
  return const _UnsupportedHealthStepsService();
}

class _UnsupportedHealthStepsService implements HealthStepsService {
  const new();

  @override
  Future<bool> requestAccess() async => false;

  @override
  Future<int?> loadSteps({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async => null;
}
