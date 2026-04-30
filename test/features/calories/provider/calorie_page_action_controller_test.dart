import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_page_action_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('printDebugDump returns success result', () async {
    final harness = _createHarness();
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      DateTime(2026, 2, 25, 12),
    );

    expect(
      result,
      isA<CalorieDebugDumpPrintSuccess>().having(
        (result) => result.rowCount,
        'rowCount',
        greaterThan(0),
      ),
    );
  });

  test('printDebugDump returns failure result after exception', () async {
    final harness = _createHarness(
      logRepository: FakeCalorieLogRepository()
        ..onReadEntriesInRange = (_, _) async {
          throw StateError('debug dump failed');
        },
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      DateTime(2026, 2, 25, 12),
    );

    expect(result, isA<CalorieDebugDumpPrintFailure>());
  });

  test('setSkippedIntakeDay returns true after successful save', () async {
    final harness = _createHarness();
    addTearDown(harness.dispose);

    final saved = await harness.controller.setSkippedIntakeDay(
      selectedDay: DateTime(2026, 2, 25),
      isSkipped: true,
    );

    expect(saved, isTrue);
  });

  test('setSkippedIntakeDay returns false after failed save', () async {
    final settingsRepository = FakeCalorieSettingsRepository()
      ..saveShouldFail = true;
    final harness = _createHarness(settingsRepository: settingsRepository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.setSkippedIntakeDay(
      selectedDay: DateTime(2026, 2, 25),
      isSkipped: true,
    );

    expect(saved, isFalse);
  });
}

_CaloriePageActionHarness _createHarness({
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
}) {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ?? FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      diaryHealthServiceProvider.overrideWithValue(FakeDiaryHealthService({})),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(
          const HealthConnectionStatus.unsupported(),
        ),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService([]),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository([]),
      ),
    ],
  );
  return _CaloriePageActionHarness(
    container: container,
    logRepository: resolvedLogRepository,
    settingsRepository: resolvedSettingsRepository,
  );
}

class _CaloriePageActionHarness {
  _CaloriePageActionHarness({
    required this.container,
    required this.logRepository,
    required this.settingsRepository,
  });

  final ProviderContainer container;
  final FakeCalorieLogRepository logRepository;
  final FakeCalorieSettingsRepository settingsRepository;

  CaloriePageActionController get controller {
    return container.read(caloriePageActionControllerProvider.notifier);
  }

  Future<void> dispose() async {
    await logRepository.dispose();
    await settingsRepository.dispose();
    container.dispose();
  }
}
