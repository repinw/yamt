import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_plan_controller.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_plan_accept_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../calories/support/fake_planned_entry_repository.dart';

/// Eats plans in memory; [fails] makes every call throw.
class _FakeAcceptService implements InventoryPlanAcceptService {
  bool fails = false;
  final accepted = <CalorieEntry>[];
  final undone = <CalorieEntry>[];

  @override
  Future<InventoryPlanAcceptResult> accept(
    CalorieEntry plan, {
    required List<InventoryItem> items,
    required List<PreparedMeal> meals,
  }) async {
    if (fails) {
      throw const InventoryPlanAcceptException('Accept failed.');
    }
    accepted.add(plan);
    return (entry: plan.copyWith(id: 'entry'), missedStock: false);
  }

  @override
  Future<void> undo(CalorieEntry entry, CalorieEntry plan) async {
    if (fails) {
      throw const InventoryPlanAcceptException('Undo failed.');
    }
    undone.add(plan);
  }
}

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
    FakePlannedEntryRepository repository, {
    _FakeAcceptService? acceptService,
  }) {
    final container = ProviderContainer(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(repository),
        inventoryPlanAcceptServiceProvider.overrideWithValue(
          acceptService ?? _FakeAcceptService(),
        ),
        inventoryQuickEatInventoryProvider.overrideWith(
          (ref) async =>
              const InventoryQuickEatInventoryData(items: [], meals: []),
        ),
      ],
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

  test('accepts a plan once until its undo', () async {
    final service = _FakeAcceptService();
    final (container, states) = setUpContainer(
      FakePlannedEntryRepository(plans: [plan]),
      acceptService: service,
    );
    final controller = container.read(diaryPlanControllerProvider.notifier);

    final result = await controller.accept(plan);

    expect(result?.entry.id, 'entry');
    expect(service.accepted, [plan]);
    expect(controller.isAccepted(plan), isTrue);
    expect(states.map((state) => state.isLoading), [true, false]);

    expect(await controller.undoAccept(result!.entry, plan), isTrue);
    expect(service.undone, [plan]);
    expect(controller.isAccepted(plan), isFalse);
  });

  test('a failed accept shows the error and frees the plan', () async {
    final service = _FakeAcceptService()..fails = true;
    final (container, states) = setUpContainer(
      FakePlannedEntryRepository(plans: [plan]),
      acceptService: service,
    );
    final controller = container.read(diaryPlanControllerProvider.notifier);

    expect(await controller.accept(plan), isNull);
    expect(states.last.hasError, isTrue);
    expect(controller.isAccepted(plan), isFalse);

    expect(await controller.undoAccept(plan, plan), isFalse);
    expect(states.last.hasError, isTrue);
  });
}
