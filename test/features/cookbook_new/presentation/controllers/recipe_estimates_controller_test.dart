import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_estimates_controller.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

import '../../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../../helpers/fake_recipe_estimate_client.dart';

final _now = DateTime.utc(2026, 11, 8, 12);

PreparedMeal _recipe(
  String id, {
  List<String> lines = const ['200 g Mehl'],
  RecipeEstimate? estimate,
}) => PreparedMeal(
  id: id,
  name: 'Brot',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 11),
  updatedAt: DateTime.utc(2026, 11),
  components: const [],
  recipeIngredients: lines,
  recipeEstimate: estimate,
);

/// Waits for what the real asynchronous fakes do next.
Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i += 1) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

/// Gives a wrong start the time to show.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

({
  ProviderContainer container,
  FakePreparedMealTemplateRepository templates,
  FakeRecipeEstimateClient client,
  List<Set<String>> states,
})
_setup(List<PreparedMeal> recipes) {
  final templates = FakePreparedMealTemplateRepository(templates: recipes);
  final client = FakeRecipeEstimateClient();
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      recipeEstimateTemplateClientProvider.overrideWithValue(client.request),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  final states = <Set<String>>[];
  container.listen(
    recipeEstimatesControllerProvider,
    (_, next) => states.add(next),
    fireImmediately: true,
  );
  return (
    container: container,
    templates: templates,
    client: client,
    states: states,
  );
}

void main() {
  test('estimates a recipe once across further saves of the Kochbuch, and '
      'its id is there while it runs', () async {
    final setup = _setup([_recipe('a')]);

    await _until(() => setup.templates.templates.single.recipeEstimate != null);
    await _until(() => setup.states.length == 3);

    expect(setup.states, [
      <String>{},
      {'a'},
      <String>{},
    ]);
    expect(setup.client.calls, 1);

    await setup.templates.save(
      setup.templates.templates.single.copyWith(name: 'Bauernbrot'),
    );
    await _settle();

    expect(setup.client.calls, 1);
    expect(setup.states, hasLength(3));
  });

  test('a failure leaves the recipe without an estimate and is not tried '
      'again when the Kochbuch changes', () async {
    final setup = _setup([_recipe('a')]);
    setup.client.failure = Exception('offline');

    await _until(() => setup.states.length == 3);

    expect(setup.states, [
      <String>{},
      {'a'},
      <String>{},
    ]);
    expect(setup.templates.templates.single.recipeEstimate, isNull);

    await setup.templates.save(_recipe('a').copyWith(name: 'Bauernbrot'));
    await _settle();

    expect(setup.client.calls, 1);
    expect(setup.states, hasLength(3));
  });

  test('a recipe saved later is estimated too', () async {
    final setup = _setup([_recipe('a')]);
    await _until(() => setup.states.length == 3);

    await setup.templates.save(_recipe('b'));
    await _until(() => setup.states.length == 5);

    expect(setup.states.sublist(3), [
      {'b'},
      <String>{},
    ]);
    expect(setup.client.calls, 2);
  });

  test(
    'a recipe whose estimate fits and one without lines never start',
    () async {
      final fitting = _recipe('fitting');
      final setup = _setup([
        fitting.copyWith(
          recipeEstimate: RecipeEstimate(
            kcal: 400,
            protein: 20,
            carbs: 50,
            fat: 10,
            portions: fitting.totalPortions,
            linesKey: recipeLinesKey(fitting.recipeIngredients),
            createdAt: _now,
          ),
        ),
        _recipe('vorlage', lines: const []),
      ]);

      await _settle();

      expect(setup.client.calls, 0);
      expect(setup.states, [<String>{}]);
    },
  );

  test(
    'runs at most three at once, and the waiting ones show as coming too',
    () async {
      const ids = {'a', 'b', 'c', 'd', 'e'};
      final setup = _setup([for (final id in ids) _recipe(id)]);
      setup.client.hold();

      await _until(() => setup.client.calls == 3);
      await _settle();

      expect(setup.client.calls, 3);
      expect(setup.states.last, ids);

      setup.client.release();
      await _until(() => setup.states.last.isEmpty);

      expect(setup.client.calls, 5);
      expect(setup.client.mostRunning, 3);
      for (final saved in setup.templates.templates) {
        expect(saved.recipeEstimate, isNotNull);
      }
    },
  );

  test('a failing estimate makes way for the waiting ones', () async {
    final setup = _setup([
      for (final id in ['a', 'b', 'c', 'd']) _recipe(id),
    ]);
    setup.client
      ..hold()
      ..failure = Exception('offline');

    await _until(() => setup.client.calls == 3);
    setup.client.release();
    await _until(() => setup.states.last.isEmpty);

    expect(setup.client.calls, 4);
  });

  test('disposed in the middle, the running estimate ends quietly and the '
      'waiting ones never start', () async {
    final setup = _setup([
      for (final id in ['a', 'b', 'c', 'd']) _recipe(id),
    ]);
    setup.client.hold();
    await _until(() => setup.client.calls == 3);
    final statesBefore = setup.states.length;

    setup.container.dispose();
    setup.client.release();
    await _settle();

    expect(setup.client.calls, 3);
    expect(setup.states, hasLength(statesBefore));
    expect(
      setup.templates.templates.where((t) => t.recipeEstimate != null),
      hasLength(3),
    );
  });
}
