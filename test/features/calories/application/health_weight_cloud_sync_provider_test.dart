import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/application/health_weight_cloud_sync_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_sample_repository.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

import '../support/fake_calories_repositories.dart';

const _readyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _notReadyStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

class _RecordingSampleRepository implements HealthWeightSampleRepository {
  final added = <HealthWeightSample>[];

  @override
  Future<void> addSamples(List<HealthWeightSample> samples) async {
    added.addAll(samples);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final goalStart = DateTime(2026, 4, 8);
  final today = DateTime(2026, 4, 20, 9);
  final beforeGoal = HealthWeightSample(
    recordedAt: DateTime(2026, 4, 1, 7),
    weightKg: 82,
  );
  final scale = HealthWeightSample(
    recordedAt: DateTime(2026, 4, 10, 7),
    weightKg: 81.5,
  );
  final fromThisApp = HealthWeightSample(
    recordedAt: DateTime(2026, 4, 12, 7),
    weightKg: 81.2,
    isFromThisApp: true,
  );

  Future<_RecordingSampleRepository> sync(HealthConnectionStatus status) async {
    final repository = _RecordingSampleRepository();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: goalStart,
      ),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWith(
          (ref) =>
              () => today,
        ),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(status),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService([beforeGoal, scale, fromThisApp]),
        ),
        healthWeightSampleRepositoryProvider.overrideWithValue(repository),
        userDataCipherProvider.overrideWithValue((
          uid: 'user-1',
          cipher: PayloadCipher(await PayloadCipher.newDataKey()),
        )),
      ],
    );
    addTearDown(container.dispose);
    container.listen(healthWeightCloudSyncProvider, (_, _) {});
    await container.read(healthWeightCloudSyncProvider.future);
    return repository;
  }

  test('copies the Health weights from the first goal on', () async {
    final repository = await sync(_readyStatus);

    // With Health ready, manual weights are stored only in Health.
    expect(repository.added, [scale, fromThisApp]);
  });

  test('copies nothing while Health is not ready', () async {
    final repository = await sync(_notReadyStatus);

    expect(repository.added, isEmpty);
  });
}
