import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
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

  @override
  Future<void> refresh(String mealId) async {}

  @override
  Future<void> refreshRecipes(
    List<PreparedMeal> templates,
    List<InventoryItem> items,
  ) async {
    refreshes.add((templates, items));
    await gate?.future;
    if (fails) {
      throw StateError('The plans could not be read.');
    }
  }
}

void main() {
  late _RecordingReminderPlanService service;
  late ProviderContainer container;

  setUp(() {
    service = _RecordingReminderPlanService();
    container = ProviderContainer(
      overrides: [
        preparedMealReminderPlanServiceProvider.overrideWithValue(service),
        plannedEntryRepositoryProvider.overrideWith(
          (ref) => FakePlannedEntryRepository(),
        ),
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream.value(const <InventoryItem>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  RecipeReminderPlanController controller() {
    container.listen(recipeReminderPlanControllerProvider, (_, _) {});
    return container.read(recipeReminderPlanControllerProvider.notifier);
  }

  test('counts the reminders of the recipes with the Vorrat', () async {
    final recipe = preparedMealTestData();

    await controller().refresh([recipe]);

    expect(service.refreshes.single.$1, [recipe]);
    expect(service.refreshes.single.$2, isEmpty);
  });

  test('a failed refresh lets the next change try again', () async {
    final notifier = controller();
    service.fails = true;
    await notifier.refresh(const []);

    service.fails = false;
    await notifier.refresh(const []);

    expect(service.refreshes, hasLength(2));
  });

  test('changes during a refresh run once after it, with the latest '
      'recipes', () async {
    final notifier = controller();
    final first = preparedMealTestData(id: 'first');
    final second = preparedMealTestData(id: 'second');
    final latest = preparedMealTestData(id: 'latest');
    service.gate = Completer<void>();

    final running = notifier.refresh([first]);
    await notifier.refresh([second]);
    await notifier.refresh([latest]);
    service.gate!.complete();
    await running;

    expect(service.refreshes.map((it) => it.$1.single.id), ['first', 'latest']);
  });

  test('counts again once the plans can be read', () async {
    final notifier = controller();
    final recipe = preparedMealTestData();
    await notifier.refresh([recipe]);

    // The data key got ready, which gives a new plan repository.
    container.invalidate(plannedEntryRepositoryProvider);
    await pumpEventQueue();

    expect(service.refreshes.map((it) => it.$1), [
      [recipe],
      [recipe],
    ]);
  });
}
