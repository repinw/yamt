import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_reminder_plan_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/recipe_reminder_plan_controller.dart';

import '../../../../support/prepared_meal_test_data.dart';
import '../../../calories/support/fake_planned_entry_repository.dart';

/// Records each refresh of the recipe reminders; [fails] makes it throw,
/// and [gate] holds each refresh until it completes.
class _RecordingReminderPlanService implements PreparedMealReminderPlanService {
  bool fails = false;
  Completer<void>? gate;
  final refreshes = <(List<PreparedMeal>, List<InventoryItem>)>[];
  final repicks = <Map<String, PreparedMeal>>[];

  @override
  Future<void> refresh(String mealId) async {}

  @override
  Future<void> refreshRecipes(
    List<PreparedMeal> templates,
    List<InventoryItem> items, {
    Map<String, PreparedMeal> repicked = const {},
  }) async {
    refreshes.add((templates, items));
    repicks.add(repicked);
    await gate?.future;
    if (fails) {
      throw StateError('The plans could not be read.');
    }
  }

  @override
  Future<void> replanRecipePlan(
    String planId,
    PreparedMeal template,
    List<InventoryItem> items,
  ) async {}
}

void main() {
  late _RecordingReminderPlanService service;
  late StreamController<List<PreparedMeal>> recipes;
  late ProviderContainer container;

  setUp(() {
    service = _RecordingReminderPlanService();
    recipes = StreamController<List<PreparedMeal>>();
    container = ProviderContainer(
      overrides: [
        preparedMealReminderPlanServiceProvider.overrideWithValue(service),
        planTemplatesProvider.overrideWith((ref) => recipes.stream),
        plannedEntryRepositoryProvider.overrideWith(
          (ref) => FakePlannedEntryRepository(),
        ),
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream.value(const <InventoryItem>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(recipes.close);
    // As the listener around the app does.
    container.listen(recipeReminderPlanControllerProvider, (_, _) {});
  });

  Future<void> change(List<PreparedMeal> templates) async {
    recipes.add(templates);
    await pumpEventQueue();
  }

  test('counts the reminders of the recipes with the Vorrat', () async {
    final recipe = preparedMealTestData();

    await change([recipe]);

    expect(service.refreshes.single.$1, [recipe]);
    expect(service.refreshes.single.$2, isEmpty);
  });

  test('a failed refresh lets the next change try again', () async {
    service.fails = true;
    await change([preparedMealTestData(id: 'failed')]);

    service.fails = false;
    await change([preparedMealTestData(id: 'next')]);

    expect(service.refreshes, hasLength(2));
  });

  test('changes during a refresh run once after it, with the latest '
      'recipes', () async {
    service.gate = Completer<void>();
    await change([preparedMealTestData(id: 'first')]);
    await change([preparedMealTestData(id: 'second')]);
    await change([preparedMealTestData(id: 'latest')]);

    service.gate!.complete();
    await pumpEventQueue();

    expect(service.refreshes.map((it) => it.$1.single.id), ['first', 'latest']);
  });

  test('counts again once the plans can be read', () async {
    final recipe = preparedMealTestData();
    await change([recipe]);

    // The data key got ready, which gives a new plan repository.
    container.invalidate(plannedEntryRepositoryProvider);
    await pumpEventQueue();

    expect(service.refreshes.map((it) => it.$1), [
      [recipe],
      [recipe],
    ]);
  });

  test('names the recipes whose saved Vorrat items changed', () async {
    final recipe = preparedMealTestData(id: 'stew');

    await change([recipe]);
    await change([
      recipe.copyWith(
        recipeIngredientAssignments: const {
          '200 g Reis': ['rice'],
        },
      ),
    ]);
    await change([
      recipe.copyWith(
        name: 'Eintopf',
        recipeIngredientAssignments: const {
          '200 g Reis': ['rice'],
        },
      ),
    ]);

    expect(
      [for (final repicked in service.repicks) repicked.keys.toSet()],
      [
        <String>{},
        {'stew'},
        <String>{},
      ],
    );
    // The recipe as it was before the change.
    expect(service.repicks[1]['stew'], recipe);
  });

  test('a failed refresh keeps the recipes with other items for the next '
      'change', () async {
    final recipe = preparedMealTestData(id: 'stew');
    final repicked = recipe.copyWith(
      recipeIngredientAssignments: const {
        '200 g Reis': ['rice'],
      },
    );
    await change([recipe]);

    service.fails = true;
    await change([repicked]);
    service.fails = false;
    await change([repicked.copyWith(name: 'Eintopf')]);

    expect(service.repicks.last, {'stew': recipe});
  });
}
