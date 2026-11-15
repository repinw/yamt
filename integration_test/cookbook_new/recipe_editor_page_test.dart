import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/data/'
    'ingredient_list_scan_repository.dart';
import 'package:yamt/features/cookbook_new/data/recipe_estimate_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_page.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_line_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_ingredient_tile.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_cook_run_repository.dart';
import '../../test/helpers/fake_prepared_meal_repository.dart';
import '../../test/helpers/fake_prepared_meal_template_repository.dart';
import '../../test/helpers/fake_recipe_estimate_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('writes a recipe in the editor, saves it onto its page, and '
      'changes a line from the page', (tester) async {
    final templates = FakePreparedMealTemplateRepository();
    // A slow AI, so all who ask for the estimate ask while it runs.
    final estimates = FakeRecipeEstimateClient()..hold();
    await tester.pumpWidget(_app(templates: templates, estimates: estimates));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeEditorPage), findsOneWidget);
    // Nothing to save yet, and the editor says what is missing.
    expect(_saveButton(tester).onPressed, isNull);
    expect(_hint(tester), contains('name'));
    expect(_hint(tester), contains('ingredient'));
    // An empty list has no line to edit.
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(RecipeEditorHeader.nameKey),
      'Zwiebelsuppe',
    );
    await tester.pumpAndSettle();
    expect(_hint(tester), contains('ingredient'));
    expect(_hint(tester), isNot(contains('name')));
    await _addLine(tester, RecipeEditorSection.ingredients, '200 g Mehl');
    // A name and an ingredient are enough.
    expect(_saveButton(tester).onPressed, isNotNull);
    expect(find.byKey(RecipeEditorActions.missingKey), findsNothing);
    await _addLine(tester, RecipeEditorSection.ingredients, '1 Zwiebel');
    await _addLine(tester, RecipeEditorSection.steps, 'Zwiebel anbraten');
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    // The editor makes way for the saved recipe's page.
    expect(find.byType(RecipeEditorPage), findsNothing);
    expect(find.byType(RecipePage), findsOneWidget);
    final saved = templates.templates.single;
    expect(saved.name, 'Zwiebelsuppe');
    expect(saved.recipeIngredients, ['200 g Mehl', '1 Zwiebel']);
    expect(saved.recipeInstructions, ['Zwiebel anbraten']);
    expect(saved.totalPortions, 2);
    expect(find.byKey(RecipeIngredientTile.tileKey(0)), findsOneWidget);
    expect(find.byKey(RecipeIngredientTile.tileKey(1)), findsOneWidget);
    // The save and the Kochbuch below share one AI call.
    expect(estimates.calls, 1);
    // The header keeps the place of the values while the AI works.
    expect(find.byKey(RecipeEstimateLine.waitKey), findsOneWidget);
    estimates.release();
    // The AI's estimate arrives in the background and shows on the page.
    await _waitForEstimate(tester);
    expect(find.byKey(RecipeEstimateLine.lineKey), findsOneWidget);
    expect(templates.templates.single.recipeEstimate, isNotNull);
    expect(estimates.calls, 1);

    // "Bearbeiten": rename the first line where it stands.
    await tester.tap(find.byKey(RecipePage.editKey));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
    );
    await tester.pumpAndSettle();
    // The text turns into a field in the same place: no sheet opens.
    expect(find.byKey(RecipeEditorLineRow.fieldKey), findsOneWidget);
    await tester.enterText(
      find.byKey(RecipeEditorLineRow.fieldKey),
      '250 g Mehl',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(RecipeEditorLineRow.fieldKey), findsNothing);
    estimates.hold();
    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    // Saving goes back to the recipe page, which shows the new line.
    expect(find.byType(RecipeEditorPage), findsNothing);
    expect(find.byType(RecipePage), findsOneWidget);
    expect(templates.templates.single.recipeIngredients, [
      '250 g Mehl',
      '1 Zwiebel',
    ]);
    expect(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(0)),
        matching: find.textContaining('250', findRichText: true),
      ),
      findsOneWidget,
    );
    // The estimate was made for the old line, so one new AI call follows,
    // and the header waits for it again.
    expect(estimates.calls, 2);
    expect(find.byKey(RecipeEstimateLine.waitKey), findsOneWidget);
    estimates.release();
    await _waitForEstimate(tester);
    expect(find.byKey(RecipeEstimateLine.waitKey), findsNothing);
    expect(find.byKey(RecipeEstimateLine.lineKey), findsOneWidget);
    expect(
      templates.templates.single.recipeEstimate?.isFor(
        templates.templates.single.recipeIngredients,
        2,
      ),
      isTrue,
    );
    expect(estimates.calls, 2);
  });

  testWidgets('a scan fills the editor and its lines can be saved', (
    tester,
  ) async {
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(
      _app(
        templates: templates,
        scans: _FakeScanRepository(
          const ScannedIngredientList(
            title: 'Brot',
            servings: 6,
            ingredients: ['500 g Mehl', 'Salz'],
            steps: ['Kneten', 'Backen'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.scan)));
    await tester.pumpAndSettle();

    expect(_text(tester, RecipeEditorHeader.nameKey), 'Brot');
    expect(
      tester.widget<Text>(find.byKey(RecipeEditorHeader.portionsKey)).data,
      '6',
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    final saved = templates.templates.single;
    expect(saved.name, 'Brot');
    expect(saved.totalPortions, 6);
    expect(saved.recipeIngredients, ['500 g Mehl', 'Salz']);
    expect(saved.recipeInstructions, ['Kneten', 'Backen']);
    expect(find.byType(RecipePage), findsOneWidget);
  });

  testWidgets('a pasted text is read by the AI and fills the editor', (
    tester,
  ) async {
    _mockClipboard(tester, 'Brot\n\n500 g Mehl\nSalz\n\nKneten');
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(
      _app(
        templates: templates,
        scans: _FakeScanRepository(
          null,
          textAnswer: const ScannedIngredientList(
            title: 'Roggenbrot',
            servings: 5,
            ingredients: ['500 g Roggenmehl', 'Salz'],
            steps: ['Kneten', 'Backen'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.paste)),
    );
    await tester.pumpAndSettle();

    expect(_text(tester, RecipeEditorHeader.nameKey), 'Roggenbrot');
    expect(
      tester.widget<Text>(find.byKey(RecipeEditorHeader.portionsKey)).data,
      '5',
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    final saved = templates.templates.single;
    expect(saved.name, 'Roggenbrot');
    expect(saved.recipeIngredients, ['500 g Roggenmehl', 'Salz']);
    expect(saved.recipeInstructions, ['Kneten', 'Backen']);
  });

  testWidgets('a failing scan keeps what was typed and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        templates: FakePreparedMealTemplateRepository(),
        scans: _FakeScanRepository(null),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

    await tester.tap(find.byKey(RecipeEditorActions.scanKey));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsNothing,
    );
  });

  testWidgets('a scan that shows no line keeps what was typed and says so', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        templates: FakePreparedMealTemplateRepository(),
        scans: _FakeScanRepository(
          const ScannedIngredientList(
            title: 'Keine Seite',
            servings: 8,
            ingredients: [],
            steps: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');

    await tester.tap(find.byKey(RecipeEditorActions.scanKey));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(_text(tester, RecipeEditorHeader.nameKey), 'Brot');
    expect(
      tester.widget<Text>(find.byKey(RecipeEditorHeader.portionsKey)).data,
      '2',
    );
  });

  testWidgets('a failed save stays in the editor and says so', (tester) async {
    final templates = FakePreparedMealTemplateRepository()..failWrites = true;
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
    await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(find.byType(RecipePage), findsNothing);
    expect(templates.templates, isEmpty);
    // The typed line is still there, so the cook can save again.
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a line is removed where it stands and comes back where it '
      'stood', (tester) async {
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
    for (final text in ['200 g Mehl', '1 Zwiebel', 'Salz']) {
      await _addLine(tester, RecipeEditorSection.ingredients, text);
    }
    Finder line(int index) => find.byKey(
      RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, index),
    );

    await tester.tap(line(1));
    await tester.pumpAndSettle();
    expect(find.byKey(RecipeEditorLineRow.removeKey), findsOneWidget);
    await tester.tap(find.byKey(RecipeEditorLineRow.removeKey));
    await tester.pumpAndSettle();

    expect(line(2), findsNothing);
    expect(find.byKey(RecipeEditorLines.removedKey), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(line(2), findsOneWidget);
    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();
    expect(templates.templates.single.recipeIngredients, [
      '200 g Mehl',
      '1 Zwiebel',
      'Salz',
    ]);
  });

  testWidgets('two new recipe editors keep separate drafts', (tester) async {
    final templates = FakePreparedMealTemplateRepository();
    await tester.pumpWidget(_app(templates: templates));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CookbookPage.newRecipeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewRecipeSheet.entryKey(NewRecipeChoice.type)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Alpha');
    await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

    // A second editor on top of the first starts empty.
    unawaited(
      GoRouter.of(tester.element(find.byType(RecipeEditorPage)))
          .push(AppRoutes.homeRecipeNew, extra: const RecipeEditorRouteArgs()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(_text(tester, RecipeEditorHeader.nameKey), isEmpty);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsNothing,
    );
    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Beta');
    await _addLine(tester, RecipeEditorSection.ingredients, 'Mehl');
    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    // The top editor made way for its recipe's page.
    expect(templates.templates.single.name, 'Beta');
    expect(find.byType(RecipePage), findsOneWidget);

    // Back under it, the first editor still holds its own draft.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(_text(tester, RecipeEditorHeader.nameKey), 'Alpha');
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(RecipeEditorActions.saveKey));
    await tester.pumpAndSettle();

    expect(
      templates.templates.map((template) => template.name),
      containsAll(['Alpha', 'Beta']),
    );
    expect(templates.templates, hasLength(2));
  });

  testWidgets('a recipe that is gone says so', (tester) async {
    await tester.pumpWidget(
      _app(
        templates: FakePreparedMealTemplateRepository(),
        location: AppRoutes.homeRecipeEditPath('gone'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(RecipeEditorPage.notFoundKey), findsOneWidget);
  });

  testWidgets('a load failure offers a retry that opens the form', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        templates: _ReadFailsOnce(templates: [_savedRecipe]),
        location: AppRoutes.homeRecipeEditPath(_savedRecipe.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(RecipeEditorHeader.nameKey), findsNothing);

    await tester.tap(find.byKey(RecipeEditorPage.retryKey));
    await tester.pumpAndSettle();

    expect(find.byKey(RecipeEditorPage.retryKey), findsNothing);
    expect(_text(tester, RecipeEditorHeader.nameKey), _savedRecipe.name);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
  });

  group('a line still in its field', () {
    testWidgets('saves as the only ingredient', (tester) async {
      final templates = FakePreparedMealTemplateRepository();
      await _openNewEditor(tester, templates: templates);
      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
      await _typeLine(tester, RecipeEditorSection.ingredients, 'Salz');

      expect(_saveButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(RecipeEditorActions.saveKey));
      await tester.pumpAndSettle();

      expect(templates.templates.single.recipeIngredients, ['Salz']);
      expect(find.byType(RecipePage), findsOneWidget);
    });

    testWidgets('saves after the lines there are, in both lists', (
      tester,
    ) async {
      final templates = FakePreparedMealTemplateRepository();
      await _openNewEditor(tester, templates: templates);
      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
      await _addLine(tester, RecipeEditorSection.ingredients, 'Mehl');
      await _typeLine(tester, RecipeEditorSection.ingredients, 'Salz');
      await _typeLine(tester, RecipeEditorSection.steps, 'Kochen');

      await tester.tap(find.byKey(RecipeEditorActions.saveKey));
      await tester.pumpAndSettle();

      final saved = templates.templates.single;
      expect(saved.recipeIngredients, ['Mehl', 'Salz']);
      expect(saved.recipeInstructions, ['Kochen']);
    });
  });

  group('the paste tool on an open editor', () {
    testWidgets('keeps the typed name and adds the lines after the typed one', (
      tester,
    ) async {
      _mockClipboard(tester, 'Roggenbrot\n\n500 g Roggenmehl\n\nKneten');
      final templates = FakePreparedMealTemplateRepository();
      await _openNewEditor(
        tester,
        templates: templates,
        scans: _FakeScanRepository(
          null,
          textAnswer: const ScannedIngredientList(
            title: 'Roggenbrot',
            servings: null,
            ingredients: ['500 g Roggenmehl'],
            steps: ['Kneten'],
          ),
        ),
      );
      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
      await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

      await tester.tap(find.byKey(RecipeEditorActions.pasteKey));
      await tester.pumpAndSettle();

      expect(_text(tester, RecipeEditorHeader.nameKey), 'Brot');
      await tester.tap(find.byKey(RecipeEditorActions.saveKey));
      await tester.pumpAndSettle();
      final saved = templates.templates.single;
      expect(saved.name, 'Brot');
      expect(saved.recipeIngredients, ['Salz', '500 g Roggenmehl']);
      expect(saved.recipeInstructions, ['Kneten']);
    });

    testWidgets('says so when the clipboard holds no text', (tester) async {
      _mockClipboard(tester, null);
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );
      await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

      await tester.tap(find.byKey(RecipeEditorActions.pasteKey));
      await tester.pumpAndSettle();

      // The snackbar has no key.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipeEditorPage)),
      )!;
      expect(find.text(l10n.recipeEditorPasteEmpty), findsOneWidget);
      expect(
        find.byKey(
          RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1),
        ),
        findsNothing,
      );
    });

    testWidgets('says so when the clipboard holds too long a text', (
      tester,
    ) async {
      _mockClipboard(tester, _tooLongText);
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );
      await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

      await tester.tap(find.byKey(RecipeEditorActions.pasteKey));
      await tester.pumpAndSettle();

      // The snackbar has no key.
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipeEditorPage)),
      )!;
      expect(find.text(l10n.recipeEditorPasteTooLong), findsOneWidget);
      expect(find.text(l10n.recipeEditorPasteEmpty), findsNothing);
      // Neither the AI nor the rules got the text.
      expect(
        find.byKey(
          RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('too long a shared text opens an empty editor and says so', (
    tester,
  ) async {
    await _openNewEditor(
      tester,
      templates: FakePreparedMealTemplateRepository(),
      args: RecipeEditorRouteArgs(sharedText: _tooLongText),
    );

    // The snackbar has no key.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecipeEditorPage)),
    )!;
    expect(find.text(l10n.recipeEditorPasteTooLong), findsOneWidget);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsNothing,
    );
  });

  group('closing the editor', () {
    final closeButton = find.byKey(RecipeEditorPage.closeKey);
    final discardButton = find.byKey(cookingDiscardKey);

    testWidgets('an untouched editor closes at once', (tester) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsNothing);
      expect(find.byType(CookbookPage), findsOneWidget);
    });

    testWidgets('an untouched editor leaves on system back too', (
      tester,
    ) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsNothing);
    });

    testWidgets('X asks with a typed name; canceling keeps the draft', (
      tester,
    ) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );
      await tester.enterText(find.byKey(RecipeEditorHeader.nameKey), 'Brot');
      await tester.pumpAndSettle();

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RecipeEditorPage)),
      )!;
      expect(find.text(l10n.recipeEditorDiscardTitle), findsOneWidget);
      expect(find.text(l10n.cookingDiscardTitle), findsNothing);

      await _cancelDialog(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(RecipeEditorPage), findsOneWidget);
      expect(_text(tester, RecipeEditorHeader.nameKey), 'Brot');

      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      await tester.tap(discardButton);
      await tester.pumpAndSettle();

      expect(find.byType(RecipeEditorPage), findsNothing);
      expect(find.byType(CookbookPage), findsOneWidget);
    });

    testWidgets('system back asks with added lines', (tester) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );
      await _addLine(tester, RecipeEditorSection.ingredients, 'Salz');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(RecipeEditorPage), findsOneWidget);
      await tester.tap(discardButton);
      await tester.pumpAndSettle();

      expect(find.byType(RecipeEditorPage), findsNothing);
      expect(find.byType(CookbookPage), findsOneWidget);
    });

    testWidgets('text still typed in an add field asks, spaces do not', (
      tester,
    ) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
      );

      await _typeLine(tester, RecipeEditorSection.steps, 'Kochen');
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(discardButton, findsOneWidget);
      await _cancelDialog(tester);

      await _typeLine(tester, RecipeEditorSection.steps, '   ');
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsNothing);
    });

    testWidgets('a saved recipe closes at once until it is changed', (
      tester,
    ) async {
      final templates = FakePreparedMealTemplateRepository(
        templates: [_savedRecipe],
      );
      await tester.pumpWidget(
        _app(
          templates: templates,
          location: AppRoutes.homeRecipePath(_savedRecipe.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(RecipePage.editKey), 100);

      await tester.tap(find.byKey(RecipePage.editKey));
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsNothing);

      await tester.tap(find.byKey(RecipePage.editKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(RecipeEditorHeader.nameKey),
        'Bauernbrot',
      );
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      await tester.tap(discardButton);
      await tester.pumpAndSettle();

      // The saved recipe stays as it was.
      expect(find.byType(RecipePage), findsOneWidget);
      expect(templates.templates.single.name, _savedRecipe.name);
    });

    testWidgets('a failed-link editor nobody typed in closes at once', (
      tester,
    ) async {
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
        args: const RecipeEditorRouteArgs(
          recipeUrl: 'https://example.com/brot',
        ),
      );

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsNothing);
    });

    testWidgets('a busy editor stays locked until it is done', (tester) async {
      _mockClipboard(tester, 'Mehl');
      final scans = _FakeScanRepository(
        null,
        textAnswer: const ScannedIngredientList(
          title: null,
          servings: null,
          ingredients: ['Mehl'],
          steps: [],
        ),
      )..textHold = Completer<void>();
      await _openNewEditor(
        tester,
        templates: FakePreparedMealTemplateRepository(),
        scans: scans,
      );

      await tester.tap(find.byKey(RecipeEditorActions.pasteKey));
      // The progress bar keeps running, so no settling here.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<IconButton>(closeButton).onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 100));
      expect(discardButton, findsNothing);
      expect(find.byType(RecipeEditorPage), findsOneWidget);

      scans.textHold!.complete();
      await tester.pumpAndSettle();

      // The read lines are something to lose now.
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(discardButton, findsOneWidget);
    });
  });
}

/// A text over the limit that the rules would make many lines of.
final String _tooLongText = 'Mehl\n' * (recipeTextCharacterLimit ~/ 5 + 1);

/// A saved recipe to open in the editor.
final PreparedMeal _savedRecipe = PreparedMeal(
  id: 'recipe-1',
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
  recipeIngredients: const ['200 g Mehl', 'Salz'],
  recipeInstructions: const ['Kneten'],
);

/// Opens the editor of a new recipe from the Kochbuch.
Future<void> _openNewEditor(
  WidgetTester tester, {
  required FakePreparedMealTemplateRepository templates,
  _FakeScanRepository? scans,
  RecipeEditorRouteArgs args = const RecipeEditorRouteArgs(),
}) async {
  await tester.pumpWidget(_app(templates: templates, scans: scans));
  await tester.pumpAndSettle();
  unawaited(
    GoRouter.of(tester.element(find.byType(CookbookPage)))
        .push(AppRoutes.homeRecipeNew, extra: args),
  );
  await tester.pumpAndSettle();
}

/// Taps "Cancel" in the open dialog; the button has no key.
Future<void> _cancelDialog(WidgetTester tester) async {
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
}

/// Lets the clipboard hold [text], or nothing when it is `null`.
void _mockClipboard(WidgetTester tester, String? text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => call.method == 'Clipboard.getData' && text != null
        ? <String, Object?>{'text': text}
        : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

/// Lets the estimate that a save starts in the background finish.
Future<void> _waitForEstimate(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

/// Types [text] into the field that adds a line to [section] and submits it,
/// so the field keeps the keyboard for the next line.
Future<void> _addLine(
  WidgetTester tester,
  RecipeEditorSection section,
  String text,
) async {
  final field = find.byKey(RecipeEditorLines.addKey(section));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

/// Types [text] into the field that adds a line to [section] without
/// submitting it.
Future<void> _typeLine(
  WidgetTester tester,
  RecipeEditorSection section,
  String text,
) async {
  final field = find.byKey(RecipeEditorLines.addKey(section));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(RecipeEditorActions.saveKey));

String _hint(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(RecipeEditorActions.missingKey)).data!;

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

Widget _app({
  required FakePreparedMealTemplateRepository templates,
  _FakeScanRepository? scans,
  FakeRecipeEstimateClient? estimates,
  String location = AppRoutes.homeInventoryTemplates,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const CookbookPage(),
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
        path: AppRoutes.homeRecipeEdit,
        builder: (context, state) =>
            RecipeEditorPage(recipeId: state.pathParameters['recipeId']),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
      preparedMealRepositoryProvider.overrideWithValue(
        FakePreparedMealRepository(),
      ),
      cookRunRepositoryProvider.overrideWithValue(FakeCookRunRepository()),
      inventoryItemRepositoryProvider.overrideWithValue(_EmptyVorrat()),
      shoppingListRepositoryProvider.overrideWithValue(_EmptyShoppingList()),
      ingredientListScanRepositoryProvider.overrideWithValue(
        scans ?? _FakeScanRepository(null),
      ),
      recipeEstimateTemplateClientProvider.overrideWithValue(
        (estimates ?? FakeRecipeEstimateClient()).request,
      ),
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

/// Returns [scanned] after a real asynchronous gap, or fails the reading
/// when [scanned] is `null`.
class _FakeScanRepository implements IngredientListScanRepository {
  new(this.scanned, {this.textAnswer});

  final ScannedIngredientList? scanned;

  /// What [loadRecipeText] answers; it fails when `null`.
  final ScannedIngredientList? textAnswer;

  /// When set, [loadRecipeText] waits for it.
  Completer<void>? textHold;

  @override
  Future<List<String>?> loadPagePhotos() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return ['page.jpg'];
  }

  @override
  Future<ScannedIngredientList> loadIngredientList(
    List<String> pagePaths,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return scanned ?? (throw const FormatException('Unreadable page'));
  }

  @override
  Future<ScannedIngredientList> loadRecipeText(String text) async {
    await textHold?.future;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return textAnswer ?? (throw const FormatException('Unreadable text'));
  }
}

/// Fails the first read of the templates, like a lost connection.
class _ReadFailsOnce extends FakePreparedMealTemplateRepository {
  new({super.templates});

  var _failed = false;

  @override
  Future<List<PreparedMeal>> readAll() {
    if (_failed) {
      return super.readAll();
    }
    _failed = true;
    return Future.error(StateError('The templates were not read.'));
  }
}

class _EmptyVorrat implements InventoryItemRepository {
  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyShoppingList implements ShoppingListRepository {
  @override
  Stream<List<ShoppingListItem>> watchAll() async* {
    yield const <ShoppingListItem>[];
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
