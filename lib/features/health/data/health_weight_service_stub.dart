import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Create health weight service.
HealthWeightService createHealthWeightService() {
  return const _UnsupportedHealthWeightService();
}

class _UnsupportedHealthWeightService implements HealthWeightService {
  const _UnsupportedHealthWeightService();

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return const <HealthWeightSample>[];
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    return false;
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    return false;
  }
}
