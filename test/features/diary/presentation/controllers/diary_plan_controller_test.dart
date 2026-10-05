import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';

import '../../../calories/support/fake_planned_entry_repository.dart';

void main() {
  final plan = buildQuickCalorieEntry(
    id: 'plan',
    userId: 'user-1',
    name: 'Pasta',
    mealType: MealType.dinner,
    loggedAt: DateTime(2026, 10, 6, 19),
    now: DateTime(2026, 10, 5, 12),
    kcal: 700,
  );

  (ProviderContainer, List<AsyncValue<void>>) setUpContainer(
    FakePlannedEntryRepository repository,
  ) {
    final container = ProviderContainer(
      overrides: [plannedEntryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final states = <AsyncValue<void>>[];
    final subscription = container.listen(
      diaryPlanControllerProvider,
      (_, next) => states.add(next),
    );
    addTearDown(subscription.close);
    return (container, states);
  }

  test('deletes and restores a plan and reloads the diary', () async {
    final repository = FakePlannedEntryRepository(plans: [plan]);
    final (container, states) = setUpContainer(repository);
    final controller = container.read(diaryPlanControllerProvider.notifier);

    expect(await controller.delete(plan), isTrue);
    expect(repository.plans, isEmpty);
    expect(container.read(calorieOverviewRevisionProvider), 1);

    expect(await controller.restore(plan), isTrue);
    expect(repository.plans, [plan]);
    expect(container.read(calorieOverviewRevisionProvider), 2);
    expect(states.map((state) => state.isLoading), [true, false, true, false]);
  });

  test('reports a failed delete and keeps the diary as it is', () async {
    final repository = FakePlannedEntryRepository(plans: [plan])
      ..writeShouldFail = true;
    final (container, states) = setUpContainer(repository);

    final deleted = await container
        .read(diaryPlanControllerProvider.notifier)
        .delete(plan);

    expect(deleted, isFalse);
    expect(states.last.hasError, isTrue);
    expect(repository.plans, [plan]);
    expect(container.read(calorieOverviewRevisionProvider), 0);
  });
}
