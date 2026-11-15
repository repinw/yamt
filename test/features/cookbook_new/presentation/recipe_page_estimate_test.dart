import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_nutrition_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_nutrition_section.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_cook_run_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';
import '../../../helpers/fake_recipe_estimate_client.dart';
import '../../../helpers/fake_signed_in_user.dart';
import '../../../support/prepared_meal_test_data.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';

const _lines = ['200 g Pasta', '100 g Tomaten'];

RecipeEstimate _estimate({List<RecipeLineNutrition>? lines}) => RecipeEstimate(
  kcal: 360,
  protein: 12,
  carbs: 72,
  fat: 2,
  portions: 2,
  linesKey: recipeLinesKey(_lines),
  createdAt: DateTime.utc(2026, 11, 13),
  lines: lines,
);

const _perLine = [
  RecipeLineNutrition(kcal: 700, protein: 24, carbs: 140, fat: 4),
  RecipeLineNutrition(kcal: 20, protein: 1, carbs: 4, fat: 1),
];

PreparedMeal _recipe({RecipeEstimate? estimate}) =>
    preparedMealTestData(id: 'pasta').copyWith(
      name: 'Tomatenpasta',
      totalPortions: 2,
      components: const [],
      recipeIngredients: _lines,
      recipeEstimate: estimate,
    );

class _Setup {
  new(PreparedMeal recipe, {FakeRecipeEstimateClient? client})
    : templates = FakePreparedMealTemplateRepository(templates: [recipe]),
      client = client ?? FakeRecipeEstimateClient();

  final FakePreparedMealTemplateRepository templates;
  final FakeRecipeEstimateClient client;

  Widget get app {
    final shopping = FakeShoppingListRepository();
    addTearDown(shopping.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.homeRecipePath('pasta'),
      routes: [
        GoRoute(
          path: AppRoutes.homeRecipe,
          builder: (context, state) =>
              RecipePage(recipeId: state.pathParameters['recipeId']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
        recipeEstimateTemplateClientProvider.overrideWithValue(client.request),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 13, 12)),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(FakeSignedInUser('uid-1')),
        ),
        cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
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
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

Future<void> _pump(WidgetTester tester, _Setup setup) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(setup.app);
}

/// Lets the page, the fake AI and the fake store run for [milliseconds].
Future<void> _run(WidgetTester tester, [int milliseconds = 200]) async {
  for (var i = 0; i < milliseconds ~/ 20; i += 1) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Pumps frames until the recipe's name is on screen: the first frame of
/// the page.
Future<void> _untilPage(WidgetTester tester) async {
  for (var i = 0; i < 50 && find.text('Tomatenpasta').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(find.text('Tomatenpasta'), findsWidgets);
}

void main() {
  final wait = find.byKey(RecipeEstimateLine.waitKey);
  final line = find.byKey(RecipeEstimateLine.lineKey);

  group('while the estimate is made', () {
    testWidgets('the place of the values shows from the first frame', (
      tester,
    ) async {
      final setup = _Setup(_recipe())..client.hold();
      await _pump(tester, setup);
      await _untilPage(tester);

      expect(wait, findsOneWidget);
      expect(line, findsNothing);
      await _run(tester);
      // The answer is still held back: the place stays.
      expect(wait, findsOneWidget);
      expect(setup.client.calls, 1);
      setup.client.release();
      await _run(tester);
    });

    testWidgets('it is as high as the values, so nothing jumps', (
      tester,
    ) async {
      final held = _Setup(_recipe())..client.hold();
      await _pump(tester, held);
      await _untilPage(tester);
      final waitHeight = tester.getSize(wait).height;
      held.client.release();
      await _run(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      await _pump(tester, _Setup(_recipe(estimate: _estimate())));
      await _run(tester);

      expect(line, findsOneWidget);
      expect(tester.getSize(line).height, waitHeight);
    });

    testWidgets('it goes away after a failure', (tester) async {
      final setup = _Setup(_recipe())
        ..client.failure = Exception('offline')
        ..client.hold();
      await _pump(tester, setup);
      await _untilPage(tester);
      expect(wait, findsOneWidget);

      setup.client.release();
      await _run(tester);

      expect(wait, findsNothing);
      expect(line, findsNothing);
      expect(setup.templates.templates.single.recipeEstimate, isNull);
    });

    testWidgets('the line replaces it when the estimate arrives', (
      tester,
    ) async {
      final setup = _Setup(_recipe())..client.hold();
      await _pump(tester, setup);
      await _untilPage(tester);
      expect(wait, findsOneWidget);

      setup.client.release();
      await _run(tester);

      expect(wait, findsNothing);
      expect(line, findsOneWidget);
      expect(setup.client.calls, 1);
      expect(setup.templates.templates.single.recipeEstimate, isNotNull);
    });

    testWidgets('a Vorlage never shows it', (tester) async {
      final vorlage = preparedMealTestData(id: 'pasta');
      final setup = _Setup(vorlage);
      await _pump(tester, setup);
      await _run(tester);

      expect(wait, findsNothing);
      expect(setup.client.calls, 0);
    });

    testWidgets('a recipe without lines never shows it', (tester) async {
      final setup = _Setup(
        _recipe().copyWith(recipeIngredients: const <String>[]),
      );
      await _pump(tester, setup);
      await _run(tester);

      expect(wait, findsNothing);
      expect(setup.client.calls, 0);
    });
  });

  group('the food label of one estimated portion', () {
    final label = find.byKey(RecipeNutritionSection.labelKey);

    testWidgets('stands above "Nährwerte je Zutat" with four rows', (
      tester,
    ) async {
      await _pump(
        tester,
        _Setup(_recipe(estimate: _estimate(lines: _perLine))),
      );
      await _run(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipePage)),
      )!;
      final toggle = find.byKey(RecipeLineNutritionSection.toggleKey);

      expect(label, findsOneWidget);
      expect(toggle, findsOneWidget);
      expect(
        tester.getTopLeft(label).dy,
        lessThan(tester.getTopLeft(toggle).dy),
      );
      final table = tester.widget<EatLabelTable>(label);
      expect(table.eatenHeader, l10n.recipeNutritionPortionEstimated);
      expect(table.per100Header, isNull);
      expect(table.rows, hasLength(4));
      expect(table.rows.first.eaten, allOf(contains('kJ'), contains('360')));
      expect(table.rows.map((row) => row.eaten).skip(1), [
        '2 g',
        '72 g',
        '12 g',
      ]);
    });

    testWidgets('shows the same values at other portions', (tester) async {
      await _pump(tester, _Setup(_recipe(estimate: _estimate())));
      await _run(tester);
      final before = [
        for (final row in tester.widget<EatLabelTable>(label).rows) row.eaten,
      ];

      await tester.tap(find.byKey(RecipePage.morePortionsKey));
      await _run(tester);

      expect(label, findsOneWidget);
      expect([
        for (final row in tester.widget<EatLabelTable>(label).rows) row.eaten,
      ], before);
    });

    testWidgets('is not there without an estimate', (tester) async {
      final setup = _Setup(_recipe())..client.failure = Exception('offline');
      await _pump(tester, setup);
      await _run(tester);

      expect(label, findsNothing);
    });

    testWidgets('is not there while the estimate is made, and comes with '
        'it', (tester) async {
      final setup = _Setup(_recipe())..client.hold();
      await _pump(tester, setup);
      await _untilPage(tester);

      expect(label, findsNothing);

      setup.client.release();
      await _run(tester);

      expect(label, findsOneWidget);
    });

    testWidgets('shows only the label when the estimate has no values per '
        'line', (tester) async {
      await _pump(tester, _Setup(_recipe(estimate: _estimate())));
      await _run(tester);

      expect(label, findsOneWidget);
      expect(find.byKey(RecipeLineNutritionSection.toggleKey), findsNothing);
    });
  });
}
