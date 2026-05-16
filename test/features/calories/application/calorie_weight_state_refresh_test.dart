import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('dirties weekly snapshots that include changed day', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithTrustedSnapshot(),
    );
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(calorieWeightStateRefreshProvider)(
      day: DateTime(2026, 3, 4),
    );

    final settings = await repository.readSettings();
    final snapshot = settings.goalHistory.single.weeklyCheckInSnapshot;
    expect(snapshot?.inputHash, isNull);
    expect(snapshot?.invalidatedAt, isNotNull);
  });

  test('keeps trusted snapshot when changed day is outside window', () async {
    final repository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithTrustedSnapshot(),
    );
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(calorieWeightStateRefreshProvider)(
      day: DateTime(2026, 3, 9),
    );

    final settings = await repository.readSettings();
    final snapshot = settings.goalHistory.single.weeklyCheckInSnapshot;
    expect(snapshot?.inputHash, 'v1:trusted');
    expect(snapshot?.invalidatedAt, isNull);
  });

  test('still invalidates providers when dirtying snapshots throws', () async {
    final repository = _ReadThrowingCalorieSettingsRepository(
      initialSettings: _settingsWithTrustedSnapshot(),
    );
    addTearDown(repository.dispose);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(calorieWeightStateRefreshProvider)(
      day: DateTime(2026, 3, 4),
    );

    final settings = await repository.readStoredSettings();
    final snapshot = settings.goalHistory.single.weeklyCheckInSnapshot;
    expect(snapshot?.inputHash, 'v1:trusted');
    expect(snapshot?.invalidatedAt, isNull);
  });
}

CalorieGoalSettings _settingsWithTrustedSnapshot() {
  return const CalorieGoalSettings.empty().applyGoalChange(
    changedAt: DateTime(2026, 3, 8),
    dailyKcalGoal: 2300,
    calculatorProfile: null,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: DateTime(2026, 3),
      windowEndDate: DateTime(2026, 3, 7),
      trendWeightChangePerDay: 0,
      calculatedTrueTdeeKcal: 2300,
      averageActiveKcal: 0,
      lowConfidence: false,
      inputHash: 'v1:trusted',
    ),
  );
}

class _ReadThrowingCalorieSettingsRepository
    extends FakeCalorieSettingsRepository {
  _ReadThrowingCalorieSettingsRepository({
    super.initialSettings,
  });

  @override
  Future<CalorieGoalSettings> readSettings() async {
    throw StateError('read failed');
  }

  Future<CalorieGoalSettings> readStoredSettings() {
    return super.readSettings();
  }
}

ProviderContainer _buildContainer(FakeCalorieSettingsRepository repository) {
  return ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(repository),
    ],
  );
}
