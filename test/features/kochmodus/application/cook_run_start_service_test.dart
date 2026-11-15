import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../../helpers/fake_signed_in_user.dart';
import '../../../helpers/memory_app_preferences.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../recipes/cook_run_fixtures.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

PreparedMeal _template() =>
    preparedMealTestData(
      id: 't1',
      name: 'Eintopf',
      totalPortions: 4,
      imageAssetId: 'photo',
    ).copyWith(
      imageUrl: 'https://example.test/a.jpg',
      recipeIngredients: ['200 g Reis', 'Salz', '2 Eier', '1 Zwiebel'],
      ignoredRecipeIngredients: ['Salz'],
      recipeIngredientAmountConversions: {
        '2 Eier': const RecipeIngredientAmountConversion(
          amountPerPiece: 60,
          unit: InventoryAmountUnit.gram,
        ),
      },
      recipeInstructions: ['Kochen', 'Essen'],
    );

void main() {
  late MemoryAppPreferences preferences;

  setUp(() => preferences = MemoryAppPreferences());

  ProviderContainer container(User? user) {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(FakeSignedInAuth(user)),
        appPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  CookRunStartService service({User? user}) => container(
    user ??
        FakeSignedInUser(
          'uid-1',
          displayName: 'Ada',
          email: 'ada@example.test',
        ),
  ).read(cookRunStartServiceProvider);

  group('recipeDraft', () {
    test('has the id of the recipe and a line per ingredient', () {
      final run = service().recipeDraft(_template());

      expect(run.id, 'recipe-t1');
      expect(run.kind, CookRunKind.recipe);
      expect(run.recipeId, 't1');
      // A recipe starts on "Zuweisen".
      expect(run.step, CookRunStep.assign);
      expect(run.pots, isNull);
      expect(run.lines.map((line) => line.id), [
        'line-0',
        'line-1',
        'line-2',
        'line-3',
      ]);
      expect(run.lines.map((line) => line.text), [
        '200 g Reis',
        'Salz',
        '2 Eier',
        '1 Zwiebel',
      ]);
      expect(
        run.lines.every((line) => line.origin == CookLineOrigin.recipe),
        isTrue,
      );
      expect(run.startedAt, _now);
    });

    test('the ignored ingredient starts ignored, the others open', () {
      final run = service().recipeDraft(_template());

      expect(run.lines.map((line) => line.settlement), [
        const LineOpen(),
        const LineIgnored(),
        const LineOpen(),
        const LineOpen(),
      ]);
    });

    test('a line that does not count starts ignored without a recipe mark, '
        'a line with kcal stays open', () {
      final run = service().recipeDraft(
        _template().copyWith(
          recipeIngredients: [
            '1 Prise Salz',
            'Pfeffer',
            '500 ml Wasser',
            'etwas Öl',
            '200 g Mehl',
          ],
          ignoredRecipeIngredients: const [],
          recipeIngredientAmountConversions: const {},
        ),
      );

      expect(run.lines.map((line) => line.settlement), [
        const LineIgnored(),
        const LineIgnored(),
        const LineIgnored(),
        const LineOpen(),
        const LineOpen(),
      ]);
    });

    test('copies the conversion onto its line, only there', () {
      final run = service().recipeDraft(_template());

      expect(
        run.lines[2].conversion,
        const CookLineConversion(
          amountPerPiece: 60,
          unit: TemplateIngredientUnit.gram,
        ),
      );
      expect(run.lines.where((line) => line.conversion != null), hasLength(1));
    });

    test('keeps the original index after an ignored line', () {
      final run = service().recipeDraft(_template());

      expect(run.lines.last.id, 'line-3');
      expect(run.lines.last.text, '1 Zwiebel');
    });

    group('rough weights', () {
      PreparedMeal weighed(Map<String, RecipeLineWeight> weights) =>
          _template().copyWith(
            recipeIngredients: [
              'Butter zum Braten',
              '200 g Reis',
              '3 Eier',
              'Salz',
            ],
            ignoredRecipeIngredients: const [],
            recipeIngredientAmountConversions: const {},
            recipeLineWeights: weights,
          );

      const butter = RecipeLineWeight(
        amount: 20,
        unit: RecipeLineWeightUnit.gram,
        source: RecipeLineWeightSource.user,
      );

      test('a line without an amount gets the rough weight of the recipe', () {
        final run = service().recipeDraft(
          weighed({'Butter zum Braten': butter}),
        );

        expect(
          run.lines[0].roughWeight,
          const CookRoughWeight(amount: 20, unit: TemplateIngredientUnit.gram),
        );
      });

      test('a milliliter weight stays in milliliters', () {
        final run = service().recipeDraft(
          weighed({
            'Butter zum Braten': const RecipeLineWeight(
              amount: 15,
              unit: RecipeLineWeightUnit.milliliter,
              source: RecipeLineWeightSource.user,
            ),
          }),
        );

        expect(
          run.lines[0].roughWeight?.unit,
          TemplateIngredientUnit.milliliter,
        );
      });

      test('a line that names an amount gets none', () {
        final run = service().recipeDraft(
          weighed({
            '200 g Reis': const RecipeLineWeight(
              amount: 200,
              unit: RecipeLineWeightUnit.gram,
              source: RecipeLineWeightSource.user,
            ),
            '3 Eier': const RecipeLineWeight(
              amount: 180,
              unit: RecipeLineWeightUnit.gram,
              source: RecipeLineWeightSource.user,
            ),
          }),
        );

        expect(run.lines[1].roughWeight, isNull);
        expect(run.lines[2].roughWeight, isNull);
      });

      test('without line weights no line gets one', () {
        final run = service().recipeDraft(weighed(const {}));

        expect(run.lines.every((line) => line.roughWeight == null), isTrue);
        expect(run.lines.every((line) => line.conversion == null), isTrue);
      });

      test(
        'pieces get their piece weight from the weight divided by count',
        () {
          final run = service().recipeDraft(
            weighed({
              '3 Eier': const RecipeLineWeight(
                amount: 180,
                unit: RecipeLineWeightUnit.gram,
                source: RecipeLineWeightSource.user,
              ),
            }),
          );

          expect(
            run.lines[2].conversion,
            const CookLineConversion(
              amountPerPiece: 60,
              unit: TemplateIngredientUnit.gram,
            ),
          );
        },
      );

      test("the recipe's own conversion wins over the derived one", () {
        final run = service().recipeDraft(
          weighed({
            '3 Eier': const RecipeLineWeight(
              amount: 180,
              unit: RecipeLineWeightUnit.gram,
              source: RecipeLineWeightSource.user,
            ),
          }).copyWith(
            recipeIngredientAmountConversions: {
              '3 Eier': const RecipeIngredientAmountConversion(
                amountPerPiece: 50,
                unit: InventoryAmountUnit.gram,
              ),
            },
          ),
        );

        expect(run.lines[2].conversion?.amountPerPiece, 50);
      });
    });

    test('takes name, image, portions and the instructions', () {
      final run = service().recipeDraft(_template());

      expect(run.name, 'Eintopf');
      expect(run.imageAssetId, 'photo');
      expect(run.imageUrl, 'https://example.test/a.jpg');
      expect(run.basePortions, 4);
      expect(run.portions, 4);
      expect(run.steps, ['Kochen', 'Essen']);
      expect(run.withGuide, isTrue);
      expect(run.guideStep, 0);
      expect(run.timers, isEmpty);
      expect(run.meals, isEmpty);
      expect(run.toCookbook, isFalse);
    });

    test('cooks for the portions asked, the base stays the recipe own', () {
      final run = service().recipeDraft(_template(), portions: 6);

      expect(run.portions, 6);
      expect(run.basePortions, 4);
    });

    test('without instructions the guide is off', () {
      final run = service().recipeDraft(
        _template().copyWith(recipeInstructions: const []),
      );

      expect(run.steps, isEmpty);
      expect(run.withGuide, isFalse);
    });
  });

  group('who started', () {
    test('is the signed-in member, named by the profile name', () {
      final run = service().recipeDraft(_template());

      expect(run.startedBy, 'uid-1');
      expect(run.startedByName, 'Ada');
    });

    test('falls back to the e-mail, then to an empty name', () {
      final byMail = service(
        user: FakeSignedInUser(
          'uid-1',
          displayName: '  ',
          email: 'ada@example.test',
        ),
      ).recipeDraft(_template());
      final anonymous = service(user: FakeSignedInUser('uid-1'))
          .recipeDraft(_template());

      expect(byMail.startedByName, 'ada@example.test');
      expect(anonymous.startedByName, '');
    });

    test('signed out, no draft is made', () {
      final signedOut = container(null).read(cookRunStartServiceProvider);

      expect(() => signedOut.recipeDraft(_template()), throwsStateError);
      expect(() => signedOut.freeDraft('free-1'), throwsStateError);
    });
  });

  test('freeDraft is empty, unnamed and for one portion', () {
    final run = service().freeDraft('free-1');

    expect(run.id, 'free-1');
    expect(run.kind, CookRunKind.free);
    expect(run.recipeId, isNull);
    expect(run.name, '');
    expect(run.basePortions, 1);
    expect(run.portions, 1);
    expect(run.lines, isEmpty);
    expect(run.steps, isEmpty);
    expect(run.withGuide, isFalse);
    expect(run.step, CookRunStep.pots);
  });

  group('deviceId', () {
    test('makes an id once and returns the same afterwards', () async {
      final start = service();

      final first = await start.deviceId();

      expect(first, isNotEmpty);
      expect(await start.deviceId(), first);
    });

    test('is the id the preferences already hold', () async {
      preferences = MemoryAppPreferences(
        initialStrings: {'app_install_id_v1': 'install-9'},
      );

      expect(await service().deviceId(), 'install-9');
    });
  });

  group('timer', () {
    test('carries the label, rings after the duration and has this '
        'device', () async {
      final start = service();

      final timer = await start.timer('Reis', const Duration(minutes: 9));

      expect(timer.label, 'Reis');
      expect(timer.endsAt, _now.add(const Duration(minutes: 9)));
      expect(timer.deviceId, await start.deviceId());
      expect(timer.id, isNotEmpty);
    });

    test('every timer has its own id', () async {
      final start = service();

      final first = await start.timer('A', const Duration(minutes: 1));
      final second = await start.timer('A', const Duration(minutes: 1));

      expect(first.id, isNot(second.id));
    });
  });

  test('cookRecipeRunId names the run of a recipe', () {
    expect(cookRecipeRunId('t1'), 'recipe-t1');
    expect(service().recipeDraft(_template()).id, cookRecipeRunId('t1'));
  });

  group('cookRunWithTimer', () {
    CookTimer timer(String id, String label, Duration after) => CookTimer(
      id: id,
      label: label,
      endsAt: _now.add(after),
      deviceId: 'd1',
    );

    final empty = buildCookRun();

    test('adds the timer to a run without one', () {
      final run = cookRunWithTimer(
        empty,
        timer('t1', 'Schritt 1', const Duration(minutes: 5)),
        now: _now,
      );

      expect(run.timers.map((t) => t.id), ['t1']);
    });

    test('keeps the run when a timer of that name still counts', () {
      final running = cookRunWithTimer(
        empty,
        timer('t1', 'Schritt 1', const Duration(minutes: 5)),
        now: _now,
      );

      final again = cookRunWithTimer(
        running,
        timer('t2', 'Schritt 1', const Duration(minutes: 5)),
        now: _now,
      );

      expect(again, running);
    });

    test('adds a timer of another name', () {
      final running = cookRunWithTimer(
        empty,
        timer('t1', 'Schritt 1', const Duration(minutes: 5)),
        now: _now,
      );

      final other = cookRunWithTimer(
        running,
        timer('t2', 'Schritt 2', const Duration(minutes: 5)),
        now: _now,
      );

      expect(other.timers.map((t) => t.id), ['t1', 't2']);
    });

    test('adds a timer once the one of that name has rung', () {
      final rung = cookRunWithTimer(
        empty,
        timer('t1', 'Schritt 1', const Duration(minutes: 5)),
        now: _now,
      );

      final later = cookRunWithTimer(
        rung,
        timer('t2', 'Schritt 1', const Duration(minutes: 5)),
        now: _now.add(const Duration(minutes: 5)),
      );

      expect(later.timers.map((t) => t.id), ['t1', 't2']);
    });
  });
}
