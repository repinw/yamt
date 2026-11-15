import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../support/prepared_meal_test_data.dart';
import '../../recipes/cook_run_fixtures.dart';

void main() {
  group('CookbookOverview.fromMeals', () {
    test('sorts templates without ingredients into Vorlagen', () {
      final template = preparedMealTestData(id: 'bowl');
      final recipe = preparedMealTestData(id: 'chili').copyWith(
        recipeIngredients: const ['500 g Beans', '1 Onion', '2 Peppers'],
        ignoredRecipeIngredients: const ['2 Peppers'],
      );

      final overview = CookbookOverview.fromMeals(
        runs: const [],
        userId: 'u1',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: [template, recipe],
        meals: const [],
        isInStock: (food) => food.contains('Rice'),
      );

      expect(overview.templates.single.meal.id, 'bowl');
      expect(overview.templates.single.inStock, [true]);
      expect(overview.recipes.single.meal.id, 'chili');
      // A recipe is never matched against the Vorrat.
      expect(overview.recipes.single.inStock, isEmpty);
    });

    group('recipe stock from the cook run', () {
      final recipe = preparedMealTestData(id: 't1').copyWith(
        recipeIngredients: const ['500 g Beans', '1 Onion', '2 Peppers'],
      );

      List<bool> stockOf(List<CookRun> runs) => CookbookOverview.fromMeals(
        runs: runs,
        userId: 'uid-1',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: [recipe],
        meals: const [],
        isInStock: (_) => true,
      ).recipes.single.inStock;

      test('is empty while the recipe has no run', () {
        expect(stockOf(const []), isEmpty);
        expect(stockOf([buildCookRun(id: 'o', recipeId: 'other')]), isEmpty);
      });

      test('is empty while the run has no assigned line', () {
        final run = buildCookRun(
          lines: [
            cookLine('line-0'),
            cookLine('line-1', settlement: const LineIgnored()),
          ],
        );

        expect(stockOf([run]), isEmpty);
      });

      test('lists each line that is not ignored, assigned or not', () {
        final run = buildCookRun(
          lines: [
            cookLine(
              'line-0',
              settlement: LineAssigned(const [
                ItemTake(itemId: 'a', amount: 100),
              ]),
            ),
            cookLine('line-1'),
            cookLine('line-2', settlement: const LineIgnored()),
            cookLine('added-1', origin: CookLineOrigin.added),
          ],
        );

        expect(stockOf([run]), [true, false]);
      });
    });

    test('lists meals with open rows and portions left, newest first', () {
      final older = preparedMealTestData(id: 'older').copyWith(
        pendingRecipeIngredients: const ['40 g Butter'],
        createdAt: DateTime.utc(2026, 9, 28),
      );
      final newer = preparedMealTestData(id: 'newer').copyWith(
        pendingRecipeIngredients: const ['200 g Rice'],
        createdAt: DateTime.utc(2026, 9, 29),
      );
      final complete = preparedMealTestData(id: 'complete');
      final eaten = preparedMealTestData(
        id: 'eaten',
        remainingPortions: 0,
      ).copyWith(pendingRecipeIngredients: const ['1 Egg']);

      final overview = CookbookOverview.fromMeals(
        runs: const [],
        userId: 'u1',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: const [],
        meals: [older, complete, eaten, newer],
        isInStock: (_) => true,
      );

      expect(overview.openMeals.map((meal) => meal.id), ['newer', 'older']);
    });

    test('lists meals still in the pot without open rows', () {
      final cooking = preparedMealTestData(id: 'cooking').copyWith(inPot: true);

      final overview = CookbookOverview.fromMeals(
        runs: const [],
        userId: 'u1',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: const [],
        meals: [
          cooking,
          preparedMealTestData(id: 'cooked'),
        ],
        isInStock: (_) => true,
      );

      expect(overview.openMeals.single.id, 'cooking');
    });

    test('lists the runs in order with who started them and the first '
        'timer', () {
      final early = CookTimer(
        id: 'a',
        label: 'Nudeln',
        endsAt: DateTime.utc(2026, 11, 7, 12, 10),
        deviceId: 'dev',
      );
      final late = CookTimer(
        id: 'b',
        label: 'Reis',
        endsAt: DateTime.utc(2026, 11, 7, 12, 40),
        deviceId: 'dev',
      );

      final overview = CookbookOverview.fromMeals(
        runs: [
          buildCookRun(id: 'mine', timers: [late, early]),
          buildCookRun(id: 'free'),
        ],
        userId: 'uid-2',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: const [],
        meals: const [],
        isInStock: (_) => true,
      );

      expect(overview.runs.map((row) => row.run.id), ['mine', 'free']);
      // The fixture's runs were started by uid-1.
      expect(overview.runs.map((row) => row.startedByMe), [false, false]);
      expect(overview.runs.first.nextTimer, early);
      expect(overview.runs.last.nextTimer, isNull);
    });

    test('a run started by the signed-in member is mine', () {
      final overview = CookbookOverview.fromMeals(
        runs: [buildCookRun()],
        userId: 'uid-1',
        now: DateTime.utc(2026, 11, 7, 12),
        savedTemplates: const [],
        meals: const [],
        isInStock: (_) => true,
      );

      expect(overview.runs.single.startedByMe, isTrue);
    });

    test('a timer that rang is not the next timer', () {
      final rang = CookTimer(
        id: 'a',
        label: 'Nudeln',
        endsAt: DateTime.utc(2026, 11, 7, 11, 55),
        deviceId: 'dev',
      );
      final running = CookTimer(
        id: 'b',
        label: 'Reis',
        endsAt: DateTime.utc(2026, 11, 7, 12, 20),
        deviceId: 'dev',
      );

      CookbookOverview overviewOf(List<CookTimer> timers) =>
          CookbookOverview.fromMeals(
            runs: [buildCookRun(timers: timers)],
            userId: 'uid-1',
            now: DateTime.utc(2026, 11, 7, 12),
            savedTemplates: const [],
            meals: const [],
            isInStock: (_) => true,
          );

      expect(overviewOf([rang, running]).runs.single.nextTimer, running);
      expect(overviewOf([rang]).runs.single.nextTimer, isNull);
    });
  });
}
