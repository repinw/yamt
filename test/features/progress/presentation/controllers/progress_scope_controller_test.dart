import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';

import '../../../../helpers/progress_source_overrides.dart';
import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  late FakeCalorieSettingsRepository settings;
  late ProviderContainer container;

  setUp(() async {
    settings = FakeCalorieSettingsRepository(
      initialSettings: progressTwoGoalSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);
    container = ProviderContainer(
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
      ),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      progressScopeControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final goals = container.listen(calorieGoalArchiveProvider, (_, _) {});
    addTearDown(goals.close);
    await container.read(calorieGoalArchiveProvider.future);
  });

  Future<void> changeGoals() async {
    await settings.saveSettings(progressSettings());
    await container.pump();
    while (container.read(calorieGoalArchiveProvider).value?.length != 1) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('a picked past goal goes back to the current goal when the goals '
      'change', () async {
    container.read(progressScopeControllerProvider.notifier).scope =
        const ProgressPastGoalScope(1);

    await changeGoals();

    expect(container.read(progressScopeControllerProvider), ProgressScope.goal);
  });

  test('all goals stay picked when the goals change', () async {
    container.read(progressScopeControllerProvider.notifier).scope =
        ProgressScope.all;

    await changeGoals();

    expect(container.read(progressScopeControllerProvider), ProgressScope.all);
  });
}
