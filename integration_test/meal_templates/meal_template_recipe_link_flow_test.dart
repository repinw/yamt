import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_link_failed_card.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/data/prepared_meal_recipe_importer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_recipe_import_flow.dart';
import 'package:yamt/features/meal_templates/presentation/models/'
    'meal_template_import_review_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_prepared_meal_repository.dart';
import '../../test/helpers/fake_recipe_estimate_client.dart';
import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _recipeUrl =
    'https://www.chefkoch.de/rezepte/3128251466082453/'
    'French-Hotdog-mit-Merguez-und-Brioche-Broetchen.html';
const _unreadableUrl = 'https://example.com/not-a-recipe';
const _noLinesUrl = 'https://example.com/only-a-title';

class _RecipeLinkHarness {
  const new({
    required this.app,
    required this.importer,
    required this.templateRepository,
    required this.estimates,
  });

  final Widget app;
  final FakeRecipeEstimateClient estimates;
  final _FakeRecipeImporter importer;
  final _FakePreparedMealTemplateRepository templateRepository;
}

class _FakeRecipeImporter extends PreparedMealRecipeImporter {
  new();

  final List<String> importedUrls = <String>[];

  /// The links whose pages read, so a link can fail first and read later.
  final Set<String> readableUrls = <String>{_recipeUrl, _noLinesUrl};

  @override
  Future<PreparedMealRecipeImport?> importRecipe(
    String recipeUrl, {
    String? localeName,
  }) async {
    importedUrls.add(recipeUrl);
    if (!readableUrls.contains(recipeUrl)) {
      return null;
    }

    return PreparedMealRecipeImport(
      recipeUrl: recipeUrl,
      title: 'French Hotdog mit Merguez und Brioche-Broetchen',
      servings: 4,
      ingredients: recipeUrl == _noLinesUrl
          ? const <String>[]
          : const <String>[
              '4 Brioche-Broetchen',
              '4 Merguez',
              '2 rote Zwiebeln',
              '4 EL Mayonnaise',
            ],
      instructions: const <String>[
        'Zwiebeln schneiden.',
        'Merguez braten.',
        'Brioche-Broetchen fuellen.',
      ],
      instructionsPreview: const <String>[
        'Zwiebeln schneiden.',
        'Merguez braten.',
        'Brioche-Broetchen fuellen.',
      ],
    );
  }
}

/// Picks a one pixel photo from the files.
class _FakeImagePicker implements PreparedMealImagePicker {
  @override
  bool get supportsCamera => false;

  @override
  Future<Uint8List?> pickFromCamera() async => null;

  @override
  Future<Uint8List?> pickFromFile() async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNo'
    'aGj4DwAFhAKAjM1mJgAAAABJRU5ErkJggg==',
  );
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
  Future<bool> update(
    String id,
    PreparedMeal? Function(PreparedMeal current) change,
  ) async => false;

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
    return Stream.value(const <InventoryItem>[]);
  }
}

_RecipeLinkHarness _buildHarness() {
  final importer = _FakeRecipeImporter();
  final templateRepository = _FakePreparedMealTemplateRepository();
  addTearDown(templateRepository.dispose);
  // Without an answer the estimate after the import fails quietly, so the
  // page stays as the import left it.
  final estimates = FakeRecipeEstimateClient(noAnswer: true);

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
        path: AppRoutes.homeRecipe,
        builder: (context, state) =>
            RecipePage(recipeId: state.pathParameters['recipeId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.homeRecipeNew,
        builder: (context, state) =>
            RecipeEditorPage(args: state.extra! as RecipeEditorRouteArgs),
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
      // Signed out, so no provider asks for a Firebase app, which tests lack.
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(null)),
      preparedMealRecipeImporterProvider.overrideWithValue(importer),
      preparedMealImagePickerProvider.overrideWithValue(_FakeImagePicker()),
      recipeEstimateTemplateClientProvider.overrideWithValue(estimates.request),
      preparedMealTemplateRepositoryProvider.overrideWithValue(
        templateRepository,
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        const _FakeInventoryItemRepository(),
      ),
      preparedMealRepositoryProvider.overrideWithValue(
        FakePreparedMealRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  return _RecipeLinkHarness(
    importer: importer,
    templateRepository: templateRepository,
    estimates: estimates,
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

/// Opens the link sheet of the Kochbuch, types [link] and, when given, the
/// [name] and [portions] under its further options, and sends it off.
Future<void> _submitLink(
  WidgetTester tester,
  String link, {
  String? name,
  String? portions,
}) async {
  await tester.tap(find.byKey(CookbookPage.newRecipeKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.link)));
  await tester.pump();
  await _pumpUntilFound(
    tester,
    find.byType(BottomSheet),
    description: 'recipe link sheet',
  );
  await tester.pumpAndSettle();

  await tester.enterText(_textFieldWithLabel('Recipe link'), link);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  if (name != null && portions != null) {
    await tester.tap(find.text('More Options (Optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(_textFieldWithLabel('Template name'), name);
    await tester.enterText(_textFieldWithLabel('Portions'), portions);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }
  await _tapBottomSheetButton(tester, 'Create from recipe');
}

/// Lets the page at [_unreadableUrl] fail and waits for the editor it opens.
Future<void> _openFailedEditor(
  WidgetTester tester,
  _RecipeLinkHarness harness, {
  String? name,
  String? portions,
}) async {
  await tester.pumpWidget(harness.app);
  await tester.pumpAndSettle();
  await _submitLink(tester, _unreadableUrl, name: name, portions: portions);
  await _pumpUntilFound(
    tester,
    find.byType(RecipeEditorPage),
    description: 'the recipe editor',
  );
  await tester.pumpAndSettle();
}

/// Types [text] into the field that adds an ingredient and submits it.
Future<void> _addIngredient(WidgetTester tester, String text) async {
  final field = find.byKey(
    RecipeEditorLines.addKey(RecipeEditorSection.ingredients),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// Saves the editor and waits for the recipe page.
Future<void> _saveEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(RecipeEditorActions.saveKey));
  await tester.pumpAndSettle();
  await _pumpUntilFound(
    tester,
    find.byType(RecipePage),
    description: 'the recipe page',
  );
}

/// Taps "Try again" on a page that now reads and waits for its review.
Future<void> _retryIntoReview(WidgetTester tester) async {
  await tester.tap(find.byKey(RecipeLinkFailedCard.retryKey));
  await tester.pump();
  await _pumpUntilFound(
    tester,
    find.byType(MealTemplateImportReviewPage),
    description: 'the recipe review',
  );
  await tester.pumpAndSettle();
}

/// Saves the review and waits for the recipe page.
Future<void> _saveReview(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key('meal_template_import_review_save_button')),
  );
  await tester.pumpAndSettle();
  await _pumpUntilFound(
    tester,
    find.byType(RecipePage),
    description: 'the recipe page',
  );
  await tester.pumpAndSettle();
}

/// Taps the stepper's "more" in the editor.
Future<void> _stepPortionsUp(WidgetTester tester) async {
  await tester.tap(find.byKey(RecipeEditorHeader.morePortionsKey));
  await tester.pump();
}

String _editorName(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(RecipeEditorHeader.nameKey))
    .controller!
    .text;

String? _editorPortions(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(RecipeEditorHeader.portionsKey)).data;

VoidCallback? _retryAction(WidgetTester tester) => tester
    .widget<FilledButton>(find.byKey(RecipeLinkFailedCard.retryKey))
    .onPressed;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates recipe template from Chefkoch link in cookbook', (
    tester,
  ) async {
    final harness = _buildHarness();
    // A slow AI, so all who ask for the estimate ask while it runs.
    harness.estimates.hold();

    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Cookbook').first, findsOneWidget);
    expect(
      find.text(
        'No recipes yet. Take a photo of one, paste it, type it, or use a '
        'link.',
      ),
      findsOneWidget,
    );

    await _submitLink(tester, _recipeUrl);

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

    // A saved link lands on the recipe page.
    await _pumpUntilFound(
      tester,
      find.byType(RecipePage),
      description: 'the recipe page',
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

    // The link flow, the page, and the Kochbuch below share one AI call.
    expect(harness.estimates.calls, 1);
    harness.estimates.release();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(harness.estimates.calls, 1);
  });

  group('a link that cannot be read', () {
    testWidgets('opens the editor with a retry card, and a recipe typed there '
        'keeps the link as its source', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness);

      expect(harness.importer.importedUrls, <String>[_unreadableUrl]);
      expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);
      expect(harness.templateRepository.savedTemplates, isEmpty);

      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
      await _addIngredient(tester, '500 g Mehl');
      await _saveEditor(tester);

      final saved = harness.templateRepository.savedTemplates.single;
      expect(saved.recipeUrl, _unreadableUrl);
      expect(saved.name, 'Brot');
      expect(saved.recipeIngredients, <String>['500 g Mehl']);
    });

    testWidgets('brings the name and portions typed in the sheet to the '
        'editor', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(
        tester,
        harness,
        name: 'Omas Suppe',
        portions: '6',
      );

      expect(_editorName(tester), 'Omas Suppe');
      expect(_editorPortions(tester), '6');
      // Both are typed, and the card stays, since reading again keeps them.
      expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);

      await _addIngredient(tester, '1 Zwiebel');
      await _saveEditor(tester);

      final saved = harness.templateRepository.savedTemplates.single;
      expect(saved.name, 'Omas Suppe');
      expect(saved.totalPortions, 6);
      expect(saved.recipeUrl, _unreadableUrl);
    });

    testWidgets('counts as such when its page has no ingredient lines', (
      tester,
    ) async {
      final harness = _buildHarness();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await _submitLink(tester, _noLinesUrl);
      await _pumpUntilFound(
        tester,
        find.byType(RecipeEditorPage),
        description: 'the recipe editor',
      );

      expect(harness.importer.importedUrls, <String>[_noLinesUrl]);
      expect(find.byType(MealTemplateImportReviewPage), findsNothing);
      expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);
      expect(harness.templateRepository.savedTemplates, isEmpty);
    });

    testWidgets('loses the retry card to a typed line or a photo, which '
        'reading again would drop, but not to a typed name', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness);
      final card = find.byKey(RecipeLinkFailedCard.cardKey);
      final field = find.byKey(
        RecipeEditorLines.addKey(RecipeEditorSection.ingredients),
      );

      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Suppe');
      await tester.pump();
      expect(card, findsOneWidget);

      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '1 Zwiebel');
      await tester.pump();
      expect(card, findsNothing);

      await tester.enterText(field, '   ');
      await tester.pump();
      expect(card, findsOneWidget);

      await tester.tap(find.byKey(RecipeEditorHeader.photoKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add image'));
      await tester.pumpAndSettle();
      expect(card, findsNothing);
    });
  });

  group('trying a link again', () {
    testWidgets('opens the review with the typed name and portions, and the '
        'saved recipe replaces the editor', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(
        tester,
        harness,
        name: 'Omas Suppe',
        portions: '6',
      );
      harness.importer.readableUrls.add(_unreadableUrl);

      await _retryIntoReview(tester);

      expect(find.text('Omas Suppe'), findsOneWidget);
      expect(find.text('6 portions'), findsOneWidget);

      await _saveReview(tester);

      expect(find.byType(RecipeEditorPage, skipOffstage: false), findsNothing);
      final saved = harness.templateRepository.savedTemplates.single;
      expect(saved.recipeUrl, _unreadableUrl);
      expect(saved.name, 'Omas Suppe');
      expect(saved.totalPortions, 6);
    });

    testWidgets('takes a name typed in the editor, and the page keeps its '
        'servings when no portions were typed in the sheet', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness);
      harness.importer.readableUrls.add(_unreadableUrl);
      await tester.enterText(
        find.byKey(RecipeEditorHeader.nameKey),
        'Eigener Name',
      );
      await tester.pump();

      await _retryIntoReview(tester);

      expect(find.text('Eigener Name'), findsOneWidget);
      // The page's servings, not the draft's default of two.
      expect(find.text('4 portions'), findsOneWidget);
    });

    testWidgets(
      "takes a count stepped in the editor over the page's servings",
      (tester) async {
        final harness = _buildHarness();
        await _openFailedEditor(tester, harness);
        harness.importer.readableUrls.add(_unreadableUrl);

        await _stepPortionsUp(tester);
        expect(_editorPortions(tester), '3');
        expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);

        await _retryIntoReview(tester);

        expect(find.text('3 portions'), findsOneWidget);

        await _saveReview(tester);

        expect(
          harness.templateRepository.savedTemplates.single.totalPortions,
          3,
        );
      },
    );

    testWidgets('takes a count stepped on from the one typed in the sheet', (
      tester,
    ) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness, name: 'Suppe', portions: '6');
      harness.importer.readableUrls.add(_unreadableUrl);

      await _stepPortionsUp(tester);
      expect(_editorPortions(tester), '7');

      await _retryIntoReview(tester);

      expect(find.text('7 portions'), findsOneWidget);

      await _saveReview(tester);

      expect(harness.templateRepository.savedTemplates.single.totalPortions, 7);
    });

    testWidgets('says so when the page still cannot be read, and leaves the '
        'editor', (tester) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipeEditorPage)),
      )!;

      await tester.tap(find.byKey(RecipeLinkFailedCard.retryKey));
      await tester.pumpAndSettle();

      expect(harness.importer.importedUrls, <String>[
        _unreadableUrl,
        _unreadableUrl,
      ]);
      // The snack bar has no key.
      expect(
        find.text(l10n.preparedMealTemplateRecipeImportFailedMessage),
        findsOneWidget,
      );
      expect(find.byKey(recipeLinkReadingKey), findsNothing);
      expect(find.byType(RecipeEditorPage), findsOneWidget);
      expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);
      expect(_retryAction(tester), isNotNull);
      expect(harness.templateRepository.savedTemplates, isEmpty);
    });

    testWidgets('leaves the editor as it was when the cook closes the review', (
      tester,
    ) async {
      final harness = _buildHarness();
      await _openFailedEditor(tester, harness, name: 'Suppe', portions: '6');
      harness.importer.readableUrls.add(_unreadableUrl);

      await _retryIntoReview(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(RecipeEditorPage), findsOneWidget);
      expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);
      expect(_retryAction(tester), isNotNull);
      expect(_editorName(tester), 'Suppe');
      expect(_editorPortions(tester), '6');
      expect(harness.templateRepository.savedTemplates, isEmpty);
    });
  });
}
