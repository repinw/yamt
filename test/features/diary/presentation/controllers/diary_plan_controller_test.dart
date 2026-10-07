import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
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

/// Saves the first plan, then fails, like a write that breaks partway.
class _FailingSecondSave extends FakePlannedEntryRepository {
  @override
  Future<void> savePlannedEntry(CalorieEntry entry) async {
    if (plans.isNotEmpty) {
      throw StateError('Plan write failed.');
    }
    await super.savePlannedEntry(entry);
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
    List<InventoryItem> items = const [],
    bool inventoryFails = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        plannedEntryRepositoryProvider.overrideWithValue(repository),
        inventoryPlanAcceptServiceProvider.overrideWithValue(
          acceptService ?? _FakeAcceptService(),
        ),
        inventoryQuickEatInventoryProvider.overrideWith(
          (ref) async => inventoryFails
              ? throw StateError('Vorrat failed to load.')
              : InventoryQuickEatInventoryData(items: items, meals: const []),
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

  test('saves a new plan and lets the diary open its day', () async {
    final repository = FakePlannedEntryRepository();
    final (container, _) = setUpContainer(repository);

    final saved = await container
        .read(diaryPlanControllerProvider.notifier)
        .plan(plan);

    expect(saved, isTrue);
    expect(repository.plans, [plan]);
    expect(container.read(lastPlannedDayProvider)?.day, plan.loggedAt);
  });

  test('a failed new plan leaves the diary on its day', () async {
    final repository = FakePlannedEntryRepository()..writeShouldFail = true;
    final (container, states) = setUpContainer(repository);

    final saved = await container
        .read(diaryPlanControllerProvider.notifier)
        .plan(plan);

    expect(saved, isFalse);
    expect(states.last.hasError, isTrue);
    expect(container.read(lastPlannedDayProvider), isNull);
  });

  test('copies a plan to more days and deletes the copies again', () async {
    final repository = FakePlannedEntryRepository(plans: [plan]);
    final (container, states) = setUpContainer(repository);
    final controller = container.read(diaryPlanControllerProvider.notifier);
    final days = [DateTime(2026, 10, 8), DateTime(2026, 10, 10)];

    final copies = await controller.copyToDays(
      plan,
      days: days,
      mealType: MealType.lunch,
    );

    expect(copies, hasLength(2));
    expect(copies!.map((copy) => copy.id).toSet(), hasLength(2));
    expect(copies.map((copy) => copy.id), isNot(contains(plan.id)));
    expect(copies.map((copy) => copy.loggedAt), [
      DateTime(2026, 10, 8, 19),
      DateTime(2026, 10, 10, 19),
    ]);
    expect(copies.map((copy) => copy.mealType), everyElement(MealType.lunch));
    expect(copies.map((copy) => copy.totalKcal), everyElement(plan.totalKcal));
    expect(repository.plans, [plan, ...copies]);
    expect(container.read(calorieOverviewRevisionProvider), 1);

    expect(await controller.deleteAll(copies), isTrue);
    expect(repository.plans, [plan]);
    expect(container.read(calorieOverviewRevisionProvider), 2);
    expect(states.map((state) => state.isLoading), [true, false, true, false]);
  });

  test('a copy that fails partway removes the copies saved before', () async {
    final repository = _FailingSecondSave();
    final (container, states) = setUpContainer(repository);

    final copies = await container
        .read(diaryPlanControllerProvider.notifier)
        .copyToDays(
          plan,
          days: [DateTime(2026, 10, 8), DateTime(2026, 10, 9)],
          mealType: MealType.dinner,
        );

    expect(copies, isNull);
    expect(states.last.hasError, isTrue);
    expect(repository.plans, isEmpty);
    expect(container.read(calorieOverviewRevisionProvider), 0);
  });

  group('withPlanStock', () {
    final previous = plan.copyWith(
      consumedAmount: 200,
      sourceInventoryItemId: 'pasta',
      sourceInventoryAmountToRestore: 200,
    );
    final changed = previous.copyWith(consumedAmount: 300);
    final pack = InventoryItem.create(
      id: 'pasta',
      name: 'Pasta',
      entryDate: DateTime(2026, 9),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );

    test('a pack that can tell the grams drops the saved stock', () async {
      final (container, _) = setUpContainer(
        FakePlannedEntryRepository(),
        items: [pack],
      );

      final result = await container
          .read(diaryPlanControllerProvider.notifier)
          .withPlanStock(previous, changed);

      expect(result.consumedAmount, 300);
      expect(result.sourceInventoryAmountToRestore, isNull);
    });

    test('a failed Vorrat load shows the error and scales the stock', () async {
      final (container, states) = setUpContainer(
        FakePlannedEntryRepository(),
        inventoryFails: true,
      );

      final result = await container
          .read(diaryPlanControllerProvider.notifier)
          .withPlanStock(previous, changed);

      expect(result.sourceInventoryAmountToRestore, 300);
      expect(states.last.hasError, isTrue);
    });

    test('an unchanged amount keeps the plan and loads nothing', () async {
      final (container, states) = setUpContainer(
        FakePlannedEntryRepository(),
        inventoryFails: true,
      );

      final result = await container
          .read(diaryPlanControllerProvider.notifier)
          .withPlanStock(previous, previous.copyWith(mealType: MealType.lunch));

      expect(result.sourceInventoryAmountToRestore, 200);
      expect(states, isEmpty);
    });
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

  test('accepts all open plans and skips eaten ones', () async {
    final service = _FakeAcceptService();
    final (container, _) = setUpContainer(
      FakePlannedEntryRepository(plans: [plan]),
      acceptService: service,
    );
    final controller = container.read(diaryPlanControllerProvider.notifier);
    final second = plan.copyWith(id: 'plan-2');
    await controller.accept(plan);

    final (:eaten, :failed) = await controller.acceptAll([plan, second]);

    expect(eaten.map((it) => it.plan.id), ['plan-2']);
    expect(failed, 0);
    expect(service.accepted.map((it) => it.id), ['plan', 'plan-2']);
  });

  test('counts the plans that fail while accepting all', () async {
    final service = _FakeAcceptService()..fails = true;
    final (container, _) = setUpContainer(
      FakePlannedEntryRepository(plans: [plan]),
      acceptService: service,
    );

    final (:eaten, :failed) = await container
        .read(diaryPlanControllerProvider.notifier)
        .acceptAll([plan, plan.copyWith(id: 'plan-2')]);

    expect(eaten, isEmpty);
    expect(failed, 2);
  });
}
