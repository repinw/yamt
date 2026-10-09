import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/'
    'prepared_meal_mutation_service.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../calories/support/fake_calories_repositories.dart';
import '../../calories/support/fake_planned_entry_repository.dart';

/// Records the entries that the batch writes with their meal.
class _FakeCommitStore implements PreparedMealCalorieEntryCommitStore {
  final committed = <CalorieEntry>[];

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) async {
    committed.add(entry);
    return true;
  }

  @override
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  }) => throw UnimplementedError();
}

/// Records the pot weighings and returns the weighed meal, or throws for a
/// failed write.
class _FakeMealMutations implements PreparedMealMutationService {
  new({this.meal, this.fails = false});

  final PreparedMeal? meal;
  final bool fails;
  final weighed = <int>[];

  @override
  Future<PreparedMeal> weighPot({
    required String mealId,
    required int netWeight,
  }) async {
    weighed.add(netWeight);
    if (fails) {
      throw StateError('offline');
    }
    return meal!.copyWith(
      potWeighing: PreparedMealPotWeighing(
        netWeight: netWeight,
        weighedAt: DateTime(2026, 9, 19, 12),
        remainingPortions: meal!.remainingPortions,
      ),
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PreparedMeal _meal({required String id}) {
  return PreparedMeal(
    id: id,
    name: 'Lunch box',
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime(2026, 9, 2),
    updatedAt: DateTime(2026, 9, 2),
    components: const <PreparedMealComponent>[],
  );
}

InventoryQuickEatApplication _application({
  _FakeCommitStore? commitStore,
  _FakeMealMutations? mealMutations,
  FakePlannedEntryRepository? plans,
  ProviderContainer? container,
}) {
  final revisionContainer = container ?? ProviderContainer();
  if (container == null) {
    addTearDown(revisionContainer.dispose);
  }
  return InventoryQuickEatApplication(
    saveEntry: (entry, {scannedSourceRef, persistEntry}) async =>
        persistEntry != null && await persistEntry(entry),
    commitStore: commitStore ?? _FakeCommitStore(),
    mealMutations: mealMutations ?? _FakeMealMutations(),
    dayLog: CalorieDayLogService(
      plans: plans ?? FakePlannedEntryRepository(),
      closedDays: ClosedDayRepository(MemoryAppPreferences(), 'user-1'),
      overviewRevision: revisionContainer.read(
        calorieOverviewRevisionProvider.notifier,
      ),
      lastPlannedDay: revisionContainer.read(lastPlannedDayProvider.notifier),
      clock: () => DateTime(2026, 9, 19, 12),
    ),
    now: () => DateTime(2026, 9, 19, 12),
  );
}

void main() {
  test('a pot weighed on the eat page is stored before the eat', () async {
    final commitStore = _FakeCommitStore();
    final mealMutations = _FakeMealMutations(meal: _meal(id: 'soup'));
    final application = _application(
      commitStore: commitStore,
      mealMutations: mealMutations,
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'soup'),
      consumedPortions: 1,
      mealType: MealType.lunch,
      loggedDay: DateTime(2026, 9, 19, 12),
      potNetWeight: 990,
    );

    expect(mealMutations.weighed, [990]);
    expect(saved?.entry.bundleSourcePreparedMealId, 'soup');
    expect(commitStore.committed, hasLength(1));
  });

  test('a failed pot weighing logs nothing', () async {
    final commitStore = _FakeCommitStore();
    final application = _application(
      commitStore: commitStore,
      mealMutations: _FakeMealMutations(fails: true),
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'soup'),
      consumedPortions: 1,
      mealType: MealType.lunch,
      loggedDay: DateTime(2026, 9, 19, 12),
      potNetWeight: 990,
    );

    expect(saved, isNull);
    expect(commitStore.committed, isEmpty);
  });

  test('eating writes the entry with its meal in one batch', () async {
    final commitStore = _FakeCommitStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final application = _application(
      commitStore: commitStore,
      container: container,
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.lunch,
      loggedDay: DateTime(2026, 9, 19),
    );

    expect(saved?.isPlan, isFalse);
    expect(commitStore.committed.single.bundleSourcePreparedMealId, 'meal-1');
    expect(commitStore.committed.single.bundleConsumedPortions, 1);
  });

  test(
    'eating still saves after unused calorie providers were disposed',
    () async {
      final calorieLogRepository = FakeCalorieLogRepository();
      addTearDown(calorieLogRepository.dispose);
      final commitStore = _FakeCommitStore();
      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
          preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
            commitStore,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Nothing listens, so auto-dispose providers read while building the
      // application are gone before the save.
      final application = container.read(inventoryQuickEatApplicationProvider);
      await pumpEventQueue();

      final saved = await application.consumePreparedMeal(
        meal: _meal(id: 'meal-1'),
        consumedPortions: 1,
        mealType: MealType.breakfast,
        loggedDay: DateTime(2026, 9, 19),
      );

      expect(saved, isNotNull);
      expect(commitStore.committed, hasLength(1));
    },
  );

  test('a later day saves a plan and keeps the portions', () async {
    final commitStore = _FakeCommitStore();
    final plans = FakePlannedEntryRepository();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final application = _application(
      commitStore: commitStore,
      plans: plans,
      container: container,
    );

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 9, 20),
    );

    expect(saved?.isPlan, isTrue);
    expect(plans.plans.single.bundleSourcePreparedMealId, 'meal-1');
    expect(plans.plans.single.loggedAt.day, 20);
    expect(commitStore.committed, isEmpty);
    expect(container.read(calorieOverviewRevisionProvider), 1);
  });

  test('an explicit plan on today keeps the portions', () async {
    final commitStore = _FakeCommitStore();
    final plans = FakePlannedEntryRepository();
    final application = _application(commitStore: commitStore, plans: plans);

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 9, 19),
      asPlan: true,
    );

    expect(saved?.isPlan, isTrue);
    expect(plans.plans, hasLength(1));
    expect(commitStore.committed, isEmpty);
  });

  test('a share of a meal in the pot is planned, not eaten', () async {
    final inPot = _meal(id: 'meal-1').copyWith(inPot: true);
    final commitStore = _FakeCommitStore();
    final plans = FakePlannedEntryRepository();
    final application = _application(commitStore: commitStore, plans: plans);

    final eaten = await application.consumePreparedMeal(
      meal: inPot,
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 9, 19),
    );
    final planned = await application.consumePreparedMeal(
      meal: inPot,
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 9, 19),
      asPlan: true,
    );

    expect(eaten, isNull);
    expect(planned?.isPlan, isTrue);
    expect(plans.plans, hasLength(1));
    expect(commitStore.committed, isEmpty);
  });

  test('a failed plan saves nothing and keeps the portions', () async {
    final commitStore = _FakeCommitStore();
    final plans = FakePlannedEntryRepository()..writeShouldFail = true;
    final application = _application(commitStore: commitStore, plans: plans);

    final saved = await application.consumePreparedMeal(
      meal: _meal(id: 'meal-1'),
      consumedPortions: 1,
      mealType: MealType.dinner,
      loggedDay: DateTime(2026, 9, 20),
    );

    expect(saved, isNull);
    expect(plans.plans, isEmpty);
    expect(commitStore.committed, isEmpty);
  });
}
