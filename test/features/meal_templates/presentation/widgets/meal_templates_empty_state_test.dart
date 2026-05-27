import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_templates_page/meal_templates_empty_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

class MockPreparedMealRecipeImporter extends Mock
    implements PreparedMealRecipeImporter {}

void main() {
  late MockPreparedMealRecipeImporter mockImporter;

  setUp(() {
    mockImporter = MockPreparedMealRecipeImporter();
  });

  Widget buildHarness({
    required GoRouter router,
  }) {
    final container = ProviderContainer(
      overrides: [
        preparedMealRecipeImporterProvider.overrideWithValue(mockImporter),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'Happy Path: click add recipe -> enter valid url -> import succeeds '
    '-> navigates to import review page',
    (tester) async {
      var navigated = false;
      MealTemplateImportReviewArgs? capturedArgs;

      final router = GoRouter(
        initialLocation: AppRoutes.root,
        routes: [
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) => const Scaffold(
              body: MealTemplatesEmptyState(),
            ),
          ),
          GoRoute(
            path: AppRoutes.homeInventoryTemplateImportReview,
            builder: (context, state) {
              navigated = true;
              capturedArgs = state.extra as MealTemplateImportReviewArgs?;
              return const Scaffold(body: Text('Import Review Page'));
            },
          ),
        ],
      );

      const mockImport = PreparedMealRecipeImport(
        recipeUrl: 'https://example.com/123',
        title: 'Mocked Recipe',
        servings: 2,
        ingredients: ['1 Ingredient'],
      );

      when(
        () => mockImporter.importRecipe(
          any(),
          localeName: any(named: 'localeName'),
        ),
      ).thenAnswer((_) async => mockImport);

      await tester.pumpWidget(buildHarness(router: router));
      await tester.pumpAndSettle();

      // Click "Add recipe template" button
      await tester.tap(find.text('Add recipe template'));
      await tester.pumpAndSettle();

      // Bottom Sheet is open. Fill in values.
      final urlFinder = find.ancestor(
        of: find.text('Recipe link'),
        matching: find.byType(TextField),
      );
      expect(urlFinder, findsOneWidget);
      await tester.enterText(urlFinder, 'https://example.com/123');

      final context = tester.element(find.byType(MealTemplatesEmptyState));
      final l10n = AppLocalizations.of(context)!;

      // Expand advanced options to reveal name and portions text fields
      await tester.tap(
        find.text(l10n.preparedMealTemplateAdvancedOptionsTitle),
      );
      await tester.pumpAndSettle();

      final nameFinder = find.ancestor(
        of: find.text('Template name'),
        matching: find.byType(TextField),
      );
      expect(nameFinder, findsOneWidget);
      await tester.enterText(nameFinder, 'Test Recipe');

      final portionsFinder = find.ancestor(
        of: find.text('Portions'),
        matching: find.byType(TextField),
      );
      expect(portionsFinder, findsOneWidget);
      await tester.enterText(portionsFinder, '2');

      // Click "Create from recipe" button
      await tester.tap(find.text('Create from recipe'));
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
      expect(capturedArgs, isNotNull);
      expect(
        capturedArgs!.importedRecipe.recipeUrl,
        'https://example.com/123',
      );
      expect(capturedArgs!.preferredName, 'Test Recipe');
      expect(capturedArgs!.preferredPortions, 2);
    },
  );

  testWidgets(
    'Edge Case (Cancel): click add recipe -> bottom sheet opens '
    '-> user cancels -> nothing happens, no crash, no navigation',
    (tester) async {
      var navigated = false;

      final router = GoRouter(
        initialLocation: AppRoutes.root,
        routes: [
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) => const Scaffold(
              body: MealTemplatesEmptyState(),
            ),
          ),
          GoRoute(
            path: AppRoutes.homeInventoryTemplateImportReview,
            builder: (context, state) {
              navigated = true;
              return const Scaffold(body: Text('Import Review Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(buildHarness(router: router));
      await tester.pumpAndSettle();

      // Click "Add recipe template" button
      await tester.tap(find.text('Add recipe template'));
      await tester.pumpAndSettle();

      // Click Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(navigated, isFalse);
    },
  );

  testWidgets(
    'Error Case: click add recipe -> enter valid url -> import returns null '
    '-> SnackBar shown, no navigation',
    (tester) async {
      var navigated = false;

      final router = GoRouter(
        initialLocation: AppRoutes.root,
        routes: [
          GoRoute(
            path: AppRoutes.root,
            builder: (context, state) => const Scaffold(
              body: MealTemplatesEmptyState(),
            ),
          ),
          GoRoute(
            path: AppRoutes.homeInventoryTemplateImportReview,
            builder: (context, state) {
              navigated = true;
              return const Scaffold(body: Text('Import Review Page'));
            },
          ),
        ],
      );

      when(
        () => mockImporter.importRecipe(
          any(),
          localeName: any(named: 'localeName'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(buildHarness(router: router));
      await tester.pumpAndSettle();

      // Click "Add recipe template" button
      await tester.tap(find.text('Add recipe template'));
      await tester.pumpAndSettle();

      // Fill URL
      final urlFinder = find.ancestor(
        of: find.text('Recipe link'),
        matching: find.byType(TextField),
      );
      await tester.enterText(urlFinder, 'https://example.com/123');

      // Click "Create from recipe" button
      await tester.tap(find.text('Create from recipe'));
      await tester.pumpAndSettle();

      expect(navigated, isFalse);
      expect(
        find.text('Recipe data could not be imported.'),
        findsOneWidget,
      );
    },
  );
}
