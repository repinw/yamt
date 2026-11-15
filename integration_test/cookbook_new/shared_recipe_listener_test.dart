import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/pending_shared_text.dart';
import 'package:yamt/core/device/pending_unreadable_share.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_editor_page.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_link_failed_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'shared_recipe_listener.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_import_review_page.dart';
import 'package:yamt/features/meal_templates/presentation/'
    'meal_template_recipe_import_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/shared_recipe_harness.dart';

const _unreadable = 'https://example.com/not-a-recipe';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a shared text waits until the app is at home, then opens the '
      'editor with the pasted lines', (tester) async {
    final harness = buildSharedRecipeHarness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put('200 g Mehl\n1 Zwiebel');
    await tester.pumpAndSettle();

    // Not at home: nothing is taken.
    expect(harness.container.read(pendingSharedTextProvider), isNotNull);
    expect(find.byType(RecipeEditorPage), findsNothing);

    harness.router.go(AppRoutes.homeInventoryTemplates);
    await tester.pumpAndSettle();

    expect(harness.container.read(pendingSharedTextProvider), isNull);
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsOneWidget,
    );
    // The kicker has no key yet.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecipeEditorPage)),
    )!;
    expect(
      find.text(l10n.recipeEditorSharedKicker.toUpperCase()),
      findsOneWidget,
    );
    expect(harness.importer.imported, isEmpty);
  });

  testWidgets('a shared link in brackets, behind a title that starts with a '
      'digit, is read without the marks', (tester) async {
    final harness = buildSharedRecipeHarness(
      location: AppRoutes.homeInventoryTemplates,
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put('5-Minuten-Suppe\n($readableRecipeLink).');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(recipeLinkReadingKey), findsOneWidget);
    harness.importer.finish();
    await tester.pumpAndSettle();

    expect(harness.importer.imported, [readableRecipeLink]);
    expect(find.byType(MealTemplateImportReviewPage), findsOneWidget);
    expect(find.byType(RecipeEditorPage), findsNothing);
  });

  testWidgets('a shared link at home is read and lands on the saved recipe', (
    tester,
  ) async {
    final harness = buildSharedRecipeHarness(
      location: AppRoutes.homeInventoryTemplates,
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put('Suppe\n$readableRecipeLink');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The busy dialog shows while the page is read.
    expect(find.byKey(recipeLinkReadingKey), findsOneWidget);
    harness.importer.finish();
    await tester.pumpAndSettle();

    expect(harness.importer.imported, [readableRecipeLink]);
    expect(find.byType(MealTemplateImportReviewPage), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('meal_template_import_review_save_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipePage), findsOneWidget);
    expect(harness.templates.templates.single.recipeUrl, readableRecipeLink);
  });

  testWidgets('a shared link that cannot be read opens the editor with the '
      'retry card', (tester) async {
    final harness = buildSharedRecipeHarness(
      location: AppRoutes.homeInventoryTemplates,
    );
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container.read(pendingSharedTextProvider.notifier).put(_unreadable);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(recipeLinkReadingKey), findsOneWidget);
    harness.importer.finish();
    await tester.pumpAndSettle();

    expect(harness.importer.imported, [_unreadable]);
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(find.byKey(RecipeLinkFailedCard.cardKey), findsOneWidget);
    expect(harness.templates.templates, isEmpty);
  });

  testWidgets('a text shared while a link is read keeps its editor, and the '
      'busy dialog goes when the reading ends', (tester) async {
    final harness = buildSharedRecipeHarness(
      location: AppRoutes.homeInventoryTemplates,
    );
    final dialog = find.byKey(recipeLinkReadingKey, skipOffstage: false);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put(readableRecipeLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(dialog, findsOneWidget);

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put('200 g Mehl\n1 Zwiebel');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The editor lies above the dialog that still shows the reading.
    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(dialog, findsOneWidget);

    harness.importer.finish();
    await tester.pumpAndSettle();

    // The link's review opens above the editor, and only the dialog is gone.
    expect(find.byType(MealTemplateImportReviewPage), findsOneWidget);
    expect(dialog, findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeEditorPage), findsOneWidget);
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 0)),
      findsOneWidget,
    );
    expect(
      find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.ingredients, 1)),
      findsOneWidget,
    );
    expect(dialog, findsNothing);
  });

  testWidgets('a shared link that waited for home keeps its busy dialog and '
      'lands on the saved recipe', (tester) async {
    final harness = buildSharedRecipeHarness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container
        .read(pendingSharedTextProvider.notifier)
        .put(readableRecipeLink);
    await tester.pumpAndSettle();
    expect(harness.importer.imported, isEmpty);

    harness.router.go(AppRoutes.homeInventoryTemplates);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The dialog sits on the home page, not on the page that went away.
    expect(find.byKey(recipeLinkReadingKey), findsOneWidget);
    harness.importer.finish();
    await tester.pumpAndSettle();

    expect(find.byType(MealTemplateImportReviewPage), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('meal_template_import_review_save_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipePage), findsOneWidget);
    expect(harness.templates.templates.single.recipeUrl, readableRecipeLink);
  });

  testWidgets('a share we could not read waits until the app is at home, then '
      'says so', (tester) async {
    final harness = buildSharedRecipeHarness();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    harness.container.read(pendingUnreadableShareProvider.notifier).raise();
    await tester.pumpAndSettle();

    // Not at home: the message waits.
    expect(harness.container.read(pendingUnreadableShareProvider), isTrue);
    expect(find.byKey(SharedRecipeListener.unreadableKey), findsNothing);

    harness.router.go(AppRoutes.homeInventoryTemplates);
    await tester.pumpAndSettle();

    expect(harness.container.read(pendingUnreadableShareProvider), isFalse);
    expect(find.byKey(SharedRecipeListener.unreadableKey), findsOneWidget);
    expect(find.byType(RecipeEditorPage), findsNothing);

    await tester.pump(AppDurations.snackBar);
    await tester.pumpAndSettle();
    expect(find.byKey(SharedRecipeListener.unreadableKey), findsNothing);
  });
}
