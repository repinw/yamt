import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/health/application/manual_health_weight_entries_controller.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

import '../../calories/support/fake_calories_repositories.dart';

final _now = DateTime(2026, 9, 27, 9);

ProviderContainer _createContainer({
  required List<ManualHealthWeightEntry> manualEntries,
  List<HealthWeightSample> samples = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      manualHealthWeightRepositoryProvider.overrideWith(
        (ref) => FakeManualHealthWeightRepository(manualEntries),
      ),
      healthConnectionServiceProvider.overrideWith(
        (ref) => FakeHealthConnectionService(
          const HealthConnectionStatus.unsupported(),
        ),
      ),
      healthWeightSamplesProvider.overrideWith((ref) => Stream.value(samples)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(ProviderContainer container) async {
  final subscription = container.listen(recentWeightTrendProvider(), (_, _) {});
  addTearDown(subscription.close);
  await pumpEventQueue();
}

void main() {
  test('uses manual weigh-ins without Health samples', () async {
    final container = _createContainer(
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 25), weightKg: 81),
      ],
    );
    await _settle(container);

    final trend = container.read(recentWeightTrendProvider()).requireValue;

    expect(trend.latestWeighInKg, 81);
    expect(trend.latestWeighInDay, DateTime(2026, 9, 25));
  });

  test('counts manual weights and the Health samples of all devices '
      'together', () async {
    final container = _createContainer(
      manualEntries: [
        ManualHealthWeightEntry(day: DateTime(2026, 9, 25), weightKg: 81),
      ],
      samples: [
        HealthWeightSample(recordedAt: DateTime(2026, 9, 25, 7), weightKg: 85),
        HealthWeightSample(
          recordedAt: DateTime(2026, 9, 26, 7),
          weightKg: 80.6,
        ),
      ],
    );
    await _settle(container);

    final trend = container.read(recentWeightTrendProvider()).requireValue;

    expect(trend.latestWeighInKg, 80.6);
    // The median of the manual entry and the Health sample of that day.
    expect(trend.days[trend.days.length - 3].weightKg, 83);
  });

  test('refreshes after a weigh-in is saved', () async {
    final container = _createContainer(manualEntries: []);
    await _settle(container);
    expect(
      container.read(recentWeightTrendProvider()).requireValue.latestWeighInKg,
      isNull,
    );

    final saved = await container
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: _now, weightKg: 79.8);
    await pumpEventQueue();

    expect(saved, isTrue);
    expect(
      container.read(recentWeightTrendProvider()).requireValue.latestWeighInKg,
      79.8,
    );
  });
}
