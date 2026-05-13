import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/provider/calorie_page_action_controller.dart';

import '../support/fake_calories_repositories.dart';

void main() {
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
  FakeCalorieSettingsRepository? settingsRepository,
}) {
  final resolvedSettingsRepository =
      settingsRepository ?? FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
    ],
  );
  return _CaloriePageActionHarness(
    container: container,
    settingsRepository: resolvedSettingsRepository,
  );
}

class _CaloriePageActionHarness {
  _CaloriePageActionHarness({
    required this.container,
    required this.settingsRepository,
  });

  final ProviderContainer container;
  final FakeCalorieSettingsRepository settingsRepository;

  CaloriePageActionController get controller {
    return container.read(caloriePageActionControllerProvider.notifier);
  }

  Future<void> dispose() async {
    await settingsRepository.dispose();
    container.dispose();
  }
}
