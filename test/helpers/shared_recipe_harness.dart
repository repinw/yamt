import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/data/'
    'ingredient_list_scan_repository.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'shared_recipe_listener.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'fake_cook_run_repository.dart';
import 'fake_prepared_meal_template_repository.dart';
import 'fake_signed_in_user.dart';
import 'inventory_item_whole_list_writes.dart';

/// The page that [SlowRecipeImporter] can read; any other link fails.
const readableRecipeLink = 'https://example.com/rezepte/suppe';

/// A page outside the home pages, where a shared text has to wait.
const sharedRecipeStartPath = '/start';

/// The app with [SharedRecipeListener] above a small router, and its fakes.
class SharedRecipeHarness {
  /// Creates the harness.
  const new({
    required this.app,
    required this.container,
    required this.router,
    required this.importer,
    required this.templates,
  });

  /// The widget to pump.
  final Widget app;

  /// The container of [app].
  final ProviderContainer container;

  /// The router of [app].
  final GoRouter router;

  /// Decides when a recipe page has been read.
  final SlowRecipeImporter importer;

  /// The saved recipes.
  final FakePreparedMealTemplateRepository templates;
}

/// Builds a [SharedRecipeHarness] that starts at [location].
SharedRecipeHarness buildSharedRecipeHarness({
  String location = sharedRecipeStartPath,
}) {
  final importer = SlowRecipeImporter();
  final templates = FakePreparedMealTemplateRepository();
  final navigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: location,
    routes: [
      GoRoute(
        path: sharedRecipeStartPath,
        builder: (context, state) => const Scaffold(body: Text('Start')),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const Scaffold(body: Text('Cookbook')),
      ),
      GoRoute(
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId']!),
      ),
      GoRoute(
        path: AppRoutes.homeRecipeNew,
        builder: (context, state) =>
            RecipeEditorPage(args: state.extra! as RecipeEditorRouteArgs),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplateImportReview,
        builder: (context, state) => MealTemplateImportReviewPage(
          args: state.extra! as MealTemplateImportReviewArgs,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(FakeSignedInUser('uid-1')),
      ),
      cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
      navigatorKeyProvider.overrideWithValue(navigatorKey),
      appRouterProvider.overrideWithValue(router),
      preparedMealRecipeImporterProvider.overrideWithValue(importer),
      ingredientListTemplateClientProvider.overrideWithValue(
        (inputs) async => null,
      ),
      // The AI is offline, so the rules read the shared text.
      recipeTextTemplateClientProvider.overrideWithValue((inputs) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw StateError('offline');
      }),
      recipeEstimateTemplateClientProvider.overrideWithValue((inputs) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return null;
      }),
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return SharedRecipeHarness(
    container: container,
    router: router,
    importer: importer,
    templates: templates,
    app: UncontrolledProviderScope(
      container: container,
      child: SharedRecipeListener(
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
}

/// Reads a page only once [finish] is called, after a real asynchronous gap.
class SlowRecipeImporter extends PreparedMealRecipeImporter {
  /// Creates the importer.
  new();

  /// The links asked for so far.
  final List<String> imported = [];
  final Completer<void> _gate = Completer<void>();

  /// Lets the reading end.
  void finish() => _gate.complete();

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    imported.add(recipeUrl);
    await _gate.future;
    if (recipeUrl != readableRecipeLink) {
      return null;
    }
    return const PreparedMealRecipeImport(
      recipeUrl: readableRecipeLink,
      title: 'Suppe',
      servings: 2,
      ingredients: ['200 g Mehl', '1 Zwiebel'],
      instructions: ['Kochen.'],
      instructionsPreview: ['Kochen.'],
    );
  }
}

class _FakeInventoryItemRepository with InventoryItemWholeListWrites {
  const new();

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async => const <InventoryItem>[];

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }
}
