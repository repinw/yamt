import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

import '../../calories/support/fake_calories_repositories.dart';

class _RecordingSampleRepository extends Fake
    implements HealthWeightSampleRepository {
  final deleted = <HealthWeightSample>[];

  @override
  Future<void> deleteSample(HealthWeightSample sample) async {
    deleted.add(sample);
  }
}

void main() {
  test('deleting an app-owned Health weight also deletes its cloud copy', () {
    final healthWeightService = FakeHealthWeightService(const []);
    final sampleRepository = _RecordingSampleRepository();
    final container = ProviderContainer(
      overrides: [
        healthWeightServiceProvider.overrideWithValue(healthWeightService),
        healthWeightSampleRepositoryProvider.overrideWithValue(
          sampleRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    final sample = HealthWeightSample(
      recordedAt: DateTime(2026, 4, 2, 12),
      weightKg: 80,
      isFromThisApp: true,
    );

    return container
        .read(diaryWeightActionsProvider)
        .deleteAppOwnedHealthWeight(sample)
        .then((deleted) {
          expect(deleted, isTrue);
          expect(healthWeightService.deletedSamples, [sample]);
          expect(sampleRepository.deleted, [sample]);
        });
  });
}
