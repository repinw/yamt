import 'package:yamt/features/health/domain/health_weight_sample.dart';

abstract interface class HealthWeightService {
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  });
}
