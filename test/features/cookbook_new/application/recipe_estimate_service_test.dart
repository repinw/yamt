import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

import '../../../helpers/fake_prepared_meal_template_repository.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

RecipeLineWeight _ai(int grams) => RecipeLineWeight(
  amount: grams,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.ai,
);

RecipeLineWeight _typed(int grams) => RecipeLineWeight(
  amount: grams,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.user,
);

PreparedMeal _recipe({
  List<String> lines = const ['1 Zwiebel', '200 g Mehl'],
  int portions = 2,
  RecipeEstimate? estimate,
  Map<String, RecipeLineWeight> weights = const {},
}) => PreparedMeal(
  id: 'recipe-1',
  name: 'Brot',
  totalPortions: portions,
  remainingPortions: portions,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 11),
  updatedAt: DateTime.utc(2026, 11),
  components: const [],
  recipeIngredients: lines,
  recipeEstimate: estimate,
  recipeLineWeights: weights,
);

/// Answers like the AI does, after a real asynchronous gap, and lets a test
/// change the recipe while the answer is on its way.
class _FakeEstimates implements RecipeEstimateRepository {
  new({this.failure});

  FutureOr<void> Function()? onRequest;
  Exception? failure;
  final requests = <({String name, int portions, List<String> lines})>[];

  @override
  Future<RecipeEstimateAnswer> loadEstimate({
    required String name,
    required int portions,
    required List<String> lines,
    required DateTime now,
  }) async {
    requests.add((name: name, portions: portions, lines: lines));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await onRequest?.call();
    if (failure case final failure?) {
      throw failure;
    }
    return (
      estimate: RecipeEstimate(
        kcal: 400,
        protein: 20,
        carbs: 50,
        fat: 10,
        portions: portions,
        linesKey: recipeLinesKey(lines),
        createdAt: now,
      ),
      weights: [for (final (index, _) in lines.indexed) _ai(100 + index)],
    );
  }
}

({
  ProviderContainer container,
  RecipeEstimateService service,
  FakePreparedMealTemplateRepository templates,
  _FakeEstimates estimates,
})
_setup(PreparedMeal? recipe, {_FakeEstimates? estimates}) {
  final templates = FakePreparedMealTemplateRepository(templates: [?recipe]);
  final fake = estimates ?? _FakeEstimates();
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      recipeEstimateRepositoryProvider.overrideWithValue(fake),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);
  return (
    container: container,
    service: container.read(recipeEstimateServiceProvider),
    templates: templates,
    estimates: fake,
  );
}

void main() {
  group('RecipeEstimateService.estimate', () {
    test('estimates a recipe without an estimate and saves it with the '
        'weights', () async {
      final setup = _setup(_recipe());

      await setup.service.estimate('recipe-1');

      final saved = setup.templates.templates.single;
      expect(saved.recipeEstimate?.kcal, 400);
      expect(saved.recipeEstimate?.createdAt, _now);
      expect(saved.recipeEstimate?.isFor(saved.recipeIngredients, 2), isTrue);
      expect(saved.recipeLineWeights, {
        '1 Zwiebel': _ai(100),
        '200 g Mehl': _ai(101),
      });
      expect(setup.estimates.requests.single.name, 'Brot');
      expect(setup.estimates.requests.single.portions, 2);
      expect(setup.estimates.requests.single.lines, saved.recipeIngredients);
    });

    test('keeps the weights the cook typed', () async {
      final setup = _setup(_recipe(weights: {'1 Zwiebel': _typed(90)}));

      await setup.service.estimate('recipe-1');

      expect(setup.templates.templates.single.recipeLineWeights, {
        '1 Zwiebel': _typed(90),
        '200 g Mehl': _ai(101),
      });
    });

    test(
      'skips a recipe whose estimate still fits its lines and portions',
      () async {
        final recipe = _recipe();
        final estimate = RecipeEstimate(
          kcal: 1,
          protein: 1,
          carbs: 1,
          fat: 1,
          portions: 2,
          linesKey: recipeLinesKey(recipe.recipeIngredients),
          createdAt: _now,
        );
        final setup = _setup(recipe.copyWith(recipeEstimate: estimate));

        await setup.service.estimate('recipe-1');

        expect(setup.estimates.requests, isEmpty);
        expect(setup.templates.writeCount, 0);
      },
    );

    test(
      'estimates again when the portions changed since the estimate',
      () async {
        final recipe = _recipe(portions: 4);
        final stale = RecipeEstimate(
          kcal: 1,
          protein: 1,
          carbs: 1,
          fat: 1,
          portions: 2,
          linesKey: recipeLinesKey(recipe.recipeIngredients),
          createdAt: _now,
        );
        final setup = _setup(recipe.copyWith(recipeEstimate: stale));

        await setup.service.estimate('recipe-1');

        expect(setup.estimates.requests.single.portions, 4);
        expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
      },
    );

    test('skips a missing recipe and one without lines', () async {
      final missing = _setup(null);
      final empty = _setup(_recipe(lines: const []));

      await missing.service.estimate('recipe-1');
      await empty.service.estimate('recipe-1');

      expect(missing.estimates.requests, isEmpty);
      expect(empty.estimates.requests, isEmpty);
      expect(empty.templates.writeCount, 0);
    });

    test('drops the answer when the lines changed meanwhile', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.save(
          _recipe(lines: const ['1 Zwiebel', '300 g Mehl']),
        );
      };
      final writesBefore = setup.templates.writeCount;

      await setup.service.estimate('recipe-1');

      // Only the change itself was saved, not the answer.
      expect(setup.templates.writeCount, writesBefore + 1);
      expect(setup.templates.templates.single.recipeEstimate, isNull);
      expect(setup.templates.templates.single.recipeLineWeights, isEmpty);
    });

    test('drops the answer when the portions changed meanwhile', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.save(_recipe(portions: 4));
      };

      await setup.service.estimate('recipe-1');

      expect(setup.templates.templates.single.totalPortions, 4);
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    test('saves the answer onto the recipe as it is then', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        // Something else changed meanwhile, which the answer must keep.
        await setup.templates.save(_recipe().copyWith(name: 'Bauernbrot'));
      };

      await setup.service.estimate('recipe-1');

      final saved = setup.templates.templates.single;
      expect(saved.name, 'Bauernbrot');
      expect(saved.recipeEstimate?.kcal, 400);
    });

    test('drops the answer when the recipe is gone meanwhile', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.delete('recipe-1');
      };

      await setup.service.estimate('recipe-1');

      expect(setup.templates.templates, isEmpty);
    });

    test('keeps a fitting estimate that came before the answer', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      final first = RecipeEstimate(
        kcal: 1,
        protein: 1,
        carbs: 1,
        fat: 1,
        portions: 2,
        linesKey: recipeLinesKey(_recipe().recipeIngredients),
        createdAt: _now,
      );
      estimates.onRequest = () async {
        await setup.templates.save(_recipe(estimate: first));
      };

      await setup.service.estimate('recipe-1');

      expect(setup.templates.templates.single.recipeEstimate, first);
    });

    test('throws when the estimate fails', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: Exception('offline')),
      );

      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsA(isA<Exception>()),
      );
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    test('throws when the recipe is not saved', () async {
      final setup = _setup(_recipe());
      setup.templates.failWrites = true;

      await expectLater(setup.service.estimate('recipe-1'), throwsStateError);
    });
  });

  group('RecipeEstimateService.estimate says whether the recipe fits', () {
    RecipeEstimate fittingFor(PreparedMeal recipe) => RecipeEstimate(
      kcal: 1,
      protein: 1,
      carbs: 1,
      fat: 1,
      portions: recipe.totalPortions,
      linesKey: recipeLinesKey(recipe.recipeIngredients),
      createdAt: _now,
    );

    test('true for an estimate that was there already', () async {
      final recipe = _recipe();
      final setup = _setup(recipe.copyWith(recipeEstimate: fittingFor(recipe)));

      expect(await setup.service.estimate('recipe-1'), isTrue);
      expect(setup.estimates.requests, isEmpty);
    });

    test('true for an estimate saved now', () async {
      final setup = _setup(_recipe());

      expect(await setup.service.estimate('recipe-1'), isTrue);
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
    });

    test('true when another estimate for the same lines came first', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.save(_recipe(estimate: fittingFor(_recipe())));
      };

      expect(await setup.service.estimate('recipe-1'), isTrue);
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 1);
    });

    test('false for a recipe that is gone', () async {
      final setup = _setup(null);

      expect(await setup.service.estimate('recipe-1'), isFalse);
    });

    test(
      'false when the recipe is gone while the answer is on its way',
      () async {
        final estimates = _FakeEstimates();
        final setup = _setup(_recipe(), estimates: estimates);
        estimates.onRequest = () async {
          await setup.templates.delete('recipe-1');
        };

        expect(await setup.service.estimate('recipe-1'), isFalse);
      },
    );

    test('false when the lines changed meanwhile', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.save(
          _recipe(lines: const ['1 Zwiebel', '300 g Mehl']),
        );
      };

      expect(await setup.service.estimate('recipe-1'), isFalse);
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    test('false when the portions changed meanwhile', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        await setup.templates.save(_recipe(portions: 4));
      };

      expect(await setup.service.estimate('recipe-1'), isFalse);
    });

    test('false for lines whose answer could not be used before', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: const FormatException('Bad')),
      );
      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsFormatException,
      );

      expect(await setup.service.estimate('recipe-1'), isFalse);
      expect(setup.estimates.requests, hasLength(1));
    });

    test('the key names the recipe, its portions and its lines', () {
      final recipe = _recipe();

      expect(
        recipe.recipeEstimateKey,
        'recipe-1|2|${recipeLinesKey(recipe.recipeIngredients)}',
      );
      expect(
        _recipe(portions: 4).recipeEstimateKey,
        isNot(recipe.recipeEstimateKey),
      );
      expect(
        _recipe(lines: const ['1 Zwiebel']).recipeEstimateKey,
        isNot(recipe.recipeEstimateKey),
      );
    });
  });

  group('RecipeEstimateService running estimates', () {
    test('a second caller joins the running estimate, across service '
        'instances, for one request and one write', () async {
      final setup = _setup(_recipe());

      final first = setup.service.estimate('recipe-1');
      setup.container.invalidate(recipeEstimateServiceProvider);
      final other = setup.container.read(recipeEstimateServiceProvider);
      expect(other, isNot(same(setup.service)));
      final second = other.estimate('recipe-1');
      await Future.wait([first, second]);

      expect(setup.estimates.requests, hasLength(1));
      expect(setup.templates.writeCount, 1);
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
    });

    test('a caller that joined gets the failure too', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: Exception('offline')),
      );

      await Future.wait([
        expectLater(
          setup.service.estimate('recipe-1'),
          throwsA(isA<Exception>()),
        ),
        expectLater(
          setup.service.estimate('recipe-1'),
          throwsA(isA<Exception>()),
        ),
      ]);

      expect(setup.estimates.requests, hasLength(1));
    });

    test('a change of the lines during a running estimate makes a second '
        'request, and only its answer is saved', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      const lines = ['1 Zwiebel', '300 g Mehl'];
      estimates.onRequest = () async {
        estimates.onRequest = null;
        await setup.templates.save(_recipe(lines: lines));
        await setup.service.estimate('recipe-1');
      };

      await setup.service.estimate('recipe-1');

      expect(estimates.requests.map((request) => request.lines), [
        _recipe().recipeIngredients,
        lines,
      ]);
      final saved = setup.templates.templates.single;
      expect(saved.recipeEstimate?.isFor(lines, 2), isTrue);
      // The change itself and the second answer.
      expect(setup.templates.writeCount, 2);
    });

    test('a change of the portions during a running estimate makes a second '
        'request', () async {
      final estimates = _FakeEstimates();
      final setup = _setup(_recipe(), estimates: estimates);
      estimates.onRequest = () async {
        estimates.onRequest = null;
        await setup.templates.save(_recipe(portions: 4));
        await setup.service.estimate('recipe-1');
      };

      await setup.service.estimate('recipe-1');

      expect(estimates.requests.map((request) => request.portions), [2, 4]);
      expect(setup.templates.templates.single.recipeEstimate?.portions, 4);
    });

    test('a finished failure runs again', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: Exception('offline')),
      );

      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsA(isA<Exception>()),
      );
      setup.estimates.failure = null;
      await setup.service.estimate('recipe-1');

      expect(setup.estimates.requests, hasLength(2));
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
    });
  });

  group('RecipeEstimateService answers that cannot be used', () {
    test('are not asked for again in this app run', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(
          failure: const FormatException('No recipe estimate: not_a_recipe'),
        ),
      );

      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsFormatException,
      );
      await setup.service.estimate('recipe-1');
      setup.container.invalidate(recipeEstimateServiceProvider);
      await setup.container
          .read(recipeEstimateServiceProvider)
          .estimate('recipe-1');

      expect(setup.estimates.requests, hasLength(1));
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    test('are not asked for again when the answer has another shape', () async {
      var calls = 0;
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(templates: [_recipe()]),
          ),
          recipeEstimateTemplateClientProvider.overrideWithValue((_) async {
            calls += 1;
            return '{"status":"ok"}';
          }),
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(recipeEstimateServiceProvider);

      await expectLater(service.estimate('recipe-1'), throwsFormatException);
      await service.estimate('recipe-1');

      expect(calls, 1);
    });

    test('get a new try when a line or the portions change', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(
          failure: const FormatException('Recipe estimate lines do not match'),
        ),
      );
      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsFormatException,
      );

      await setup.templates.save(_recipe(portions: 4));
      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsFormatException,
      );
      expect(setup.estimates.requests, hasLength(2));

      setup.estimates.failure = null;
      await setup.templates.save(
        _recipe(portions: 4, lines: const ['1 Zwiebel', '300 g Mehl']),
      );
      await setup.service.estimate('recipe-1');
      expect(setup.estimates.requests, hasLength(3));
      expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
    });

    test('do not stop a recipe with the same lines elsewhere', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: const FormatException('Bad')),
      );
      await expectLater(
        setup.service.estimate('recipe-1'),
        throwsFormatException,
      );

      setup.estimates.failure = null;
      await setup.templates.save(_recipe().copyWith(id: 'recipe-2'));
      await setup.service.estimate('recipe-2');

      expect(setup.estimates.requests, hasLength(2));
    });
  });

  group('RecipeEstimateService.estimateInBackground', () {
    test('does not throw when the estimate fails', () async {
      final setup = _setup(
        _recipe(),
        estimates: _FakeEstimates(failure: Exception('offline')),
      );

      setup.service.estimateInBackground('recipe-1');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(setup.estimates.requests, hasLength(1));
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    test('saves the estimate without being awaited', () async {
      final setup = _setup(_recipe());

      setup.service.estimateInBackground('recipe-1');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(setup.templates.templates.single.recipeEstimate?.kcal, 400);
    });
  });
}
