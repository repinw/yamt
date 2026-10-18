import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../../../helpers/fake_health_weight_sample_repository.dart';
import '../../calories/support/fake_calories_repositories.dart';

ManualHealthWeightEntry _manual(DateTime at, double kg) =>
    ManualHealthWeightEntry(day: at, weightKg: kg, recordedAt: at, id: '$at');

HealthWeightSample _health(DateTime at, double kg, {bool ignored = false}) =>
    HealthWeightSample(recordedAt: at, weightKg: kg, isIgnored: ignored);

Future<double?> _latest({
  List<ManualHealthWeightEntry> manual = const [],
  List<HealthWeightSample> health = const [],
}) async {
  final cloud = FakeHealthWeightSampleRepository(health);
  addTearDown(cloud.dispose);
  final container = ProviderContainer(
    overrides: [
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository([...manual]),
      ),
      healthWeightSampleRepositoryProvider.overrideWithValue(cloud),
    ],
  );
  addTearDown(container.dispose);
  // Auto-dispose: a listener keeps it alive while the sources load.
  final subscription = container.listen(latestWeighingKgProvider, (_, _) {});
  addTearDown(subscription.close);
  return await container.read(latestWeighingKgProvider.future);
}

void main() {
  test('is null without a weighing', () async {
    expect(await _latest(), isNull);
  });

  test('is the newest single weighing, not a daily median', () async {
    expect(
      await _latest(
        manual: [
          _manual(DateTime(2026, 10, 18, 7), 80.0),
          _manual(DateTime(2026, 10, 18, 21), 81.2),
          _manual(DateTime(2026, 10, 17, 22), 79.0),
        ],
      ),
      81.2,
    );
  });

  test('takes a Health weighing newer than the manual ones', () async {
    expect(
      await _latest(
        manual: [_manual(DateTime(2026, 10, 18, 7), 80.0)],
        health: [_health(DateTime(2026, 10, 18, 8), 80.6)],
      ),
      80.6,
    );
  });

  test('takes a manual weighing newer than the Health ones', () async {
    expect(
      await _latest(
        manual: [_manual(DateTime(2026, 10, 18, 9), 80.0)],
        health: [_health(DateTime(2026, 10, 18, 8), 80.6)],
      ),
      80.0,
    );
  });

  test('skips an ignored Health weighing', () async {
    expect(
      await _latest(
        manual: [_manual(DateTime(2026, 10, 17, 7), 80.0)],
        health: [_health(DateTime(2026, 10, 18, 8), 90, ignored: true)],
      ),
      80.0,
    );
    expect(
      await _latest(
        health: [_health(DateTime(2026, 10, 18, 8), 90, ignored: true)],
      ),
      isNull,
    );
  });
}
