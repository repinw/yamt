import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';

import '../support/fake_calories_repositories.dart';

({
  ProviderContainer container,
  FakeCalorieSettingsRepository repository,
  List<WeekBalanceMode?> modes,
})
_setUp() {
  final repository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 11, 16),
    ),
  );
  addTearDown(repository.dispose);
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  final modes = <WeekBalanceMode?>[];
  final subscription = container.listen(
    calorieGoalControllerProvider,
    (_, next) => modes.add(next.value?.weekBalanceMode),
  );
  addTearDown(subscription.close);
  return (container: container, repository: repository, modes: modes);
}

void main() {
  test('K5: setWeekBalanceMode stores the mode for the account', () async {
    final (:container, :repository, :modes) = _setUp();
    await container.read(calorieGoalControllerProvider.future);
    modes.clear();

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(WeekBalanceMode.carryover);

    expect(saved, isTrue);
    expect(
      (await repository.readSettings()).weekBalanceMode,
      WeekBalanceMode.carryover,
    );
    expect(modes, isNotEmpty);
    expect(modes.toSet(), {WeekBalanceMode.carryover});
    expect(
      container.read(calorieGoalControllerProvider).value?.weekBalanceMode,
      WeekBalanceMode.carryover,
    );
  });

  test('setWeekBalanceMode keeps the goal of the account', () async {
    final (:container, :repository, modes: _) = _setUp();
    await container.read(calorieGoalControllerProvider.future);

    await container
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(WeekBalanceMode.off);

    final stored = await repository.readSettings();
    expect(stored.weekBalanceMode, WeekBalanceMode.off);
    expect(stored.dailyKcalGoal, 2200);
    expect(stored.goalHistory, hasLength(1));
  });

  test('a failed save reports false and keeps the mode before', () async {
    final (:container, :repository, :modes) = _setUp();
    await container.read(calorieGoalControllerProvider.future);
    repository.saveShouldFail = true;
    modes.clear();

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(WeekBalanceMode.carryover);

    expect(saved, isFalse);
    // The optimistic mode, then back to the stored one.
    expect(modes, [WeekBalanceMode.carryover, WeekBalanceMode.show]);
    expect(
      (await repository.readSettings()).weekBalanceMode,
      WeekBalanceMode.show,
    );
  });

  test('setWeekBalanceMode reports false while the settings cannot '
      'load', () async {
    final (:container, :repository, modes: _) = _setUp();
    repository.readError = Exception('offline');

    final saved = await container
        .read(calorieGoalControllerProvider.notifier)
        .setWeekBalanceMode(WeekBalanceMode.carryover);

    expect(saved, isFalse);
  });
}
