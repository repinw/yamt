import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_line_states.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_status_card.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_cook_run_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../kochmodus/kochmodus_fixtures.dart';
import '../../kochmodus/presentation/kochmodus_cooking_harness.dart'
    show cookedLine;
import '../../recipes/cook_run_fixtures.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

const _runKey = ValueKey<String>('cook-run-page');
const _newKey = ValueKey<String>('new-cook-page');
const _cookbookKey = ValueKey<String>('cookbook-page');

final PreparedMeal _recipe = preparedMealTestData(id: 'pasta').copyWith(
  name: 'One-pan pasta',
  totalPortions: 4,
  recipeIngredients: const ['200 g Pasta'],
);

/// Cook runs that come when the test says so, as a listener that still
/// waits for its first answer or fails.
class _HeldCookRuns extends FakeCookRunRepository {
  final _held = StreamController<List<CookRun>>.broadcast();

  @override
  Stream<List<CookRun>> watchAll() => _held.stream;

  void emit(List<CookRun> runs) => _held.add(runs);

  void fail() => _held.addError(StateError('The listener failed.'));
}

Widget _app({required FakeCookRunRepository runs, PreparedMeal? recipe}) {
  final shopping = FakeShoppingListRepository();
  addTearDown(shopping.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.homeRecipePath('pasta'),
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const Scaffold(key: _cookbookKey),
      ),
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeCookRun,
        builder: (context, state) => Scaffold(
          key: _runKey,
          body: Text('run ${state.pathParameters['runId']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeCook,
        builder: (context, state) =>
            Scaffold(key: _newKey, body: Text('assign ${state.uri}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        FakePreparedMealTemplateRepository(templates: [recipe ?? _recipe]),
      ),
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(runs),
      inventoryItemRepositoryProvider.overrideWithValue(
        FakeInventoryItemRepository(const []),
      ),
      shoppingListRepositoryProvider.overrideWithValue(shopping),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

RecipeIngredientTile _tile(WidgetTester tester, int index) =>
    tester.widget(find.byKey(RecipeIngredientTile.tileKey(index)));

FilledButton _cookButton(WidgetTester tester) =>
    tester.widget(find.byKey(RecipePage.cookKey));

void main() {
  testWidgets('a run with lines to assign fixes the portions, Weiter assigns', (
    tester,
  ) async {
    final run = buildCookRun(id: 'run-1', recipeId: 'pasta', portions: 6);
    expect(run.needsAssigning, isTrue);
    await tester.pumpWidget(_app(runs: FakeCookRunRepository(runs: [run])));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(RecipePage)))!;

    expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '6');
    // The stepper of a running cooking is disabled.
    expect(
      tester
          .widget<IconButton>(find.byKey(RecipePage.morePortionsKey))
          .onPressed,
      isNull,
    );
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text(l10n.cookbookContinueAction),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();

    // "Zuweisen" opens, not the cooking page.
    expect(find.byKey(_newKey), findsOneWidget);
    expect(
      find.text('assign ${AppRoutes.homeCookPath('pasta', portions: 6)}'),
      findsOneWidget,
    );
    expect(find.byKey(_runKey), findsNothing);
  });

  group('the bottom button of a recipe with a cook run', () {
    final settled = [
      textLine('line-0', '200 g Pasta', settlement: const LineIgnored()),
    ];

    Future<void> pump(WidgetTester tester, CookRun run) async {
      await tester.pumpWidget(_app(runs: FakeCookRunRepository(runs: [run])));
      await tester.pumpAndSettle();
    }

    String label(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(RecipePage.cookKey),
            matching: find.byType(Text),
          ),
        )
        .data!;

    AppLocalizations l10nOf(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(RecipePage)))!;

    for (final step in [CookRunStep.assign, CookRunStep.pots]) {
      testWidgets('is "Kochen" on $step once nothing is left to assign', (
        tester,
      ) async {
        await pump(
          tester,
          buildCookRun(
            id: 'run-1',
            recipeId: 'pasta',
            step: step,
            lines: settled,
          ),
        );

        expect(label(tester), l10nOf(tester).cookingCookAction);
        expect(_cookButton(tester).onPressed, isNotNull);

        await tester.tap(find.byKey(RecipePage.cookKey));
        await tester.pumpAndSettle();

        expect(find.text('run run-1'), findsOneWidget);
        expect(find.byKey(_newKey), findsNothing);
      });
    }

    for (final step in [CookRunStep.cook, CookRunStep.portion]) {
      testWidgets('is "Weiter" on $step and opens the cooking page', (
        tester,
      ) async {
        await pump(
          tester,
          buildCookRun(
            id: 'run-1',
            recipeId: 'pasta',
            step: step,
            lines: settled,
          ),
        );

        expect(label(tester), l10nOf(tester).cookbookContinueAction);

        await tester.tap(find.byKey(RecipePage.cookKey));
        await tester.pumpAndSettle();

        expect(find.text('run run-1'), findsOneWidget);
        expect(find.byKey(_newKey), findsNothing);
      });
    }

    for (final step in CookRunStep.values) {
      testWidgets('is "Weiter" to "Zuweisen" on $step while a line is open', (
        tester,
      ) async {
        await pump(
          tester,
          buildCookRun(id: 'run-1', recipeId: 'pasta', step: step),
        );

        expect(label(tester), l10nOf(tester).cookbookContinueAction);

        await tester.tap(find.byKey(RecipePage.cookKey));
        await tester.pumpAndSettle();

        expect(find.byKey(_newKey), findsOneWidget);
        expect(find.byKey(_runKey), findsNothing);
      });
    }

    testWidgets('a line that waits for the shopping goes to "Zuweisen"', (
      tester,
    ) async {
      await pump(
        tester,
        buildCookRun(
          id: 'run-1',
          recipeId: 'pasta',
          step: CookRunStep.paused,
          lines: [
            textLine('line-0', '200 g Pasta', settlement: const LineShopping()),
          ],
        ),
      );

      expect(label(tester), l10nOf(tester).cookbookContinueAction);

      await tester.tap(find.byKey(RecipePage.cookKey));
      await tester.pumpAndSettle();

      expect(find.byKey(_newKey), findsOneWidget);
    });

    testWidgets('a line that came in while cooking does not send back', (
      tester,
    ) async {
      await pump(
        tester,
        buildCookRun(
          id: 'run-1',
          recipeId: 'pasta',
          step: CookRunStep.cook,
          lines: [...settled, cookedLine('line-1', '1 Ei')],
        ),
      );

      await tester.tap(find.byKey(RecipePage.cookKey));
      await tester.pumpAndSettle();

      expect(find.text('run run-1'), findsOneWidget);
    });
  });

  testWidgets(
    'without a run the portions can change and Vorbereiten is offered',
    (tester) async {
      await tester.pumpWidget(_app(runs: FakeCookRunRepository()));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipePage)),
      )!;

      expect(
        find.descendant(
          of: find.byKey(RecipePage.cookKey),
          matching: find.text(l10n.recipePrepareAction),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(RecipePage.morePortionsKey));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(RecipePage.portionsKey)).data, '5');
    },
  );

  testWidgets('a double tap opens the cooking page once', (tester) async {
    await tester.pumpWidget(_app(runs: FakeCookRunRepository()));
    await tester.pumpAndSettle();
    final tap = _cookButton(tester).onPressed!;

    tap();
    // The second tap comes while the cooking page slides over the button.
    await tester.pump();
    tap();
    await tester.pumpAndSettle();

    expect(find.byKey(_newKey, skipOffstage: false), findsOneWidget);
  });

  testWidgets('leaving the cooking page with a go leaves the recipe free', (
    tester,
  ) async {
    await tester.pumpWidget(_app(runs: FakeCookRunRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RecipePage.cookKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_newKey), findsOneWidget);

    // "Zum Kochbuch" on the last step of the cooking page.
    tester.element(find.byKey(_newKey)).go(AppRoutes.homeInventoryTemplates);
    await tester.pumpAndSettle();
    expect(find.byType(RecipePage), findsNothing);

    unawaited(
      tester
          .element(find.byKey(_cookbookKey))
          .push<void>(AppRoutes.homeRecipePath('pasta')),
    );
    await tester.pumpAndSettle();

    expect(_cookButton(tester).onPressed, isNotNull);
    expect(find.byKey(RecipePage.editKey), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(RecipeHero.removeKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets('"Bearbeiten" waits until the cook run is known', (tester) async {
    final runs = _HeldCookRuns();
    await tester.pumpWidget(_app(runs: runs));
    await tester.pumpAndSettle();

    expect(find.byKey(RecipePage.editKey), findsNothing);
    // The button stays on: a recipe target opens the stored run anyway.
    expect(_cookButton(tester).onPressed, isNotNull);

    runs.emit(const []);
    await tester.pumpAndSettle();

    expect(find.byKey(RecipePage.editKey), findsOneWidget);
  });

  testWidgets('a failing listener keeps the cook run the page knows', (
    tester,
  ) async {
    final runs = _HeldCookRuns();
    await tester.pumpWidget(_app(runs: runs));
    await tester.pumpAndSettle();
    runs.emit([buildCookRun(id: 'run-1', recipeId: 'pasta', portions: 6)]);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(RecipePage)))!;

    runs.fail();
    await tester.pumpAndSettle();

    expect(find.byKey(RecipePage.editKey), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(RecipePage.morePortionsKey))
          .onPressed,
      isNull,
    );
    expect(
      find.descendant(
        of: find.byKey(RecipePage.cookKey),
        matching: find.text(l10n.cookbookContinueAction),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a line state stands only beside the line it was taken from', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A second device removed "200 g Mehl" after the run took its lines.
    final edited = _recipe.copyWith(
      recipeIngredients: const ['2 Eier', 'Salz', 'Pfeffer'],
    );
    final run = buildCookRun(
      id: 'run-1',
      recipeId: 'pasta',
      lines: [
        textLine('line-0', '200 g Mehl', settlement: assigned({'gone': 200})),
        textLine('line-1', '2 Eier'),
        textLine('line-2', 'Pfeffer', settlement: const LineIgnored()),
      ],
    );
    await tester.pumpWidget(
      _app(
        runs: FakeCookRunRepository(runs: [run]),
        recipe: edited,
      ),
    );
    await tester.pumpAndSettle();

    // Nothing about the flour stands beside the eggs.
    expect(_tile(tester, 0).state, isNull);
    expect(_tile(tester, 1).state, isNull);
    expect(_tile(tester, 2).state, isA<RecipeLineIgnored>());
    // The run counts its own lines still.
    expect(find.byKey(RecipeLineStatusCard.cardKey), findsOneWidget);
    expect(find.byKey(RecipePage.openHintKey), findsOneWidget);
  });
}
