import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_cook_actions.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _recipeUrl =
    'https://www.chefkoch.de/rezepte/3128251466082453/'
    'French-Hotdog-mit-Merguez-und-Brioche-Broetchen.html';

class _RecipeLinkHarness {
  const new({
    required this.app,
    required this.importer,
    required this.templateRepository,
  });

  final Widget app;
  final _FakeRecipeImporter importer;
  final _FakePreparedMealTemplateRepository templateRepository;
}

class _FakeRecipeImporter extends PreparedMealRecipeImporter {
  new();

  final List<String> importedUrls = <String>[];

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    importedUrls.add(recipeUrl);
    if (recipeUrl != _recipeUrl) {
      return null;
    }

    return const PreparedMealRecipeImport(
      recipeUrl: _recipeUrl,
      title: 'French Hotdog mit Merguez und Brioche-Broetchen',
      servings: 4,
      ingredients: <String>[
        '4 Brioche-Broetchen',
        '4 Merguez',
        '2 rote Zwiebeln',
        '4 EL Mayonnaise',
      ],
      instructions: <String>[
        'Zwiebeln schneiden.',
        'Merguez braten.',
        'Brioche-Broetchen fuellen.',
      ],
      instructionsPreview: <String>[
        'Zwiebeln schneiden.',
        'Merguez braten.',
        'Brioche-Broetchen fuellen.',
      ],
    );
  }
}

class _FakePreparedMealTemplateRepository
    implements PreparedMealTemplateRepository {
  final StreamController<List<PreparedMeal>> _controller =
      StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> _templates = const <PreparedMeal>[];

  List<PreparedMeal> get savedTemplates {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<List<PreparedMeal>> readAll() async {
    return List<PreparedMeal>.from(_templates);
  }

  @override
  Future<bool> save(PreparedMeal template) => _replaceAll([
    for (final stored in _templates)
      if (stored.id != template.id) stored,
    template,
  ]);

  @override
  Future<bool> delete(String templateId) => _replaceAll([
    for (final stored in _templates)
      if (stored.id != templateId) stored,
  ]);

  Future<bool> _replaceAll(List<PreparedMeal> templates) async {
    _templates = List<PreparedMeal>.from(templates);
    _controller.add(List<PreparedMeal>.from(_templates));
    return true;
  }

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add(List<PreparedMeal>.from(_templates));
      final subscription = _controller.stream.listen(controller.add);
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  Future<void> dispose() => _controller.close();
}

class _StaticInventoryItemsController extends InventoryItemsController {
  @override
  FutureOr<List<InventoryItem>> build() {
    return const <InventoryItem>[];
  }
}

class _FakeInventoryItemRepository with InventoryItemWholeListWrites {
  const new();

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
  }
}

class _NoopPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }
}

_RecipeLinkHarness _buildHarness() {
  final importer = _FakeRecipeImporter();
  final templateRepository = _FakePreparedMealTemplateRepository();
  addTearDown(templateRepository.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplates,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomePage(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeInventory,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Inventory'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeDiary,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Diary'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeInventoryTemplates,
                builder: (context, state) => const CookbookPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.homeSettings,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Settings'))),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplateImportReview,
        builder: (context, state) {
          final args = state.extra;
          if (args is! MealTemplateImportReviewArgs) {
            throw ArgumentError(
              'Meal template import review route requires args.',
            );
          }
          return MealTemplateImportReviewPage(args: args);
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      preparedMealRecipeImporterProvider.overrideWithValue(importer),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templateRepository,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(),
      ),
      inventoryItemsControllerProvider.overrideWith(
        _StaticInventoryItemsController.new,
      ),
      preparedMealsControllerProvider.overrideWith(
        _NoopPreparedMealsController.new,
      ),
      inventoryQuickEatItemsProvider.overrideWith(
        (ref) => Stream.value(const <InventoryItem>[]),
      ),
      inventoryQuickEatMealsProvider.overrideWith(
        (ref) => Stream.value(const <PreparedMeal>[]),
      ),
    ],
  );
  addTearDown(container.dispose);

  return _RecipeLinkHarness(
    importer: importer,
    templateRepository: templateRepository,
    app: UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate((widget) {
    return widget is TextField && widget.decoration?.labelText == label;
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required String description,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final end = tester.binding.clock.fromNowBy(timeout);
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $description.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tapBottomSheetButton(WidgetTester tester, String label) async {
  final button = find.ancestor(
    of: find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(label),
    ),
    matching: find.byType(FilledButton),
  );
  await _pumpUntilFound(tester, button, description: '$label button');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.drag(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(SingleChildScrollView),
    ),
    const Offset(0, -240),
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates recipe template from Chefkoch link in cookbook', (
    tester,
  ) async {
    final harness = _buildHarness();

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Cookbook').first, findsOneWidget);
    expect(
      find.text('No recipes yet. Add one from a link or get an AI idea.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookCookActionKeys.link));
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byType(BottomSheet),
      description: 'recipe link sheet',
    );
    await tester.pumpAndSettle();

    await tester.enterText(_textFieldWithLabel('Recipe link'), _recipeUrl);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await _tapBottomSheetButton(tester, 'Create from recipe');

    await _pumpUntilFound(
      tester,
      find.text('Review recipe'),
      description: 'recipe review page',
    );
    expect(harness.importer.importedUrls, <String>[_recipeUrl]);
    expect(
      find.text('French Hotdog mit Merguez und Brioche-Broetchen'),
      findsOneWidget,
    );
    expect(find.text('4 portions'), findsOneWidget);
    expect(find.text('• 4 Merguez'), findsOneWidget);

    final saveButton = find.byKey(
      const Key('meal_template_import_review_save_button'),
    );
    await _pumpUntilFound(tester, saveButton, description: 'save button');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    await _pumpUntilFound(
      tester,
      find.text('Template saved.'),
      description: 'template saved snackbar',
    );
    expect(harness.templateRepository.savedTemplates, hasLength(1));
    expect(
      harness.templateRepository.savedTemplates.single.recipeUrl,
      _recipeUrl,
    );
    expect(
      harness.templateRepository.savedTemplates.single.name,
      'French Hotdog mit Merguez und Brioche-Broetchen',
    );
    expect(
      harness.templateRepository.savedTemplates.single.recipeIngredients,
      contains('4 Merguez'),
    );
  });
}
