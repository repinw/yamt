import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Defines health weight service.
abstract interface class HealthWeightService {
  /// Load weight samples.
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  /// Save weight sample.
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  });

  /// Delete a weight sample, only when the service can prove app ownership.
  Future<bool> deleteWeightSample(HealthWeightSample sample);
}
