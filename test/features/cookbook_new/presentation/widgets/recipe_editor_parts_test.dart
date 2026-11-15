import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_line_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_lines.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_prepared_meal_template_repository.dart';

Widget _host(Widget child, {Widget? bottom}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child, bottomNavigationBar: bottom),
);

RecipeEditorActions _actions(RecipeEditorDraft draft) => RecipeEditorActions(
  draft: draft,
  isSaving: false,
  onScan: () {},
  onPaste: () {},
  onSave: () {},
);

const _flour = RecipeEditorLine(text: '200 g Flour');

String? _missing(WidgetTester tester) => tester
    .widgetList<Text>(find.byKey(RecipeEditorActions.missingKey))
    .singleOrNull
    ?.data;

void main() {
  group('RecipeEditorActions', () {
    testWidgets('names a missing name and ingredient', (tester) async {
      await tester.pumpWidget(_host(_actions(const RecipeEditorDraft())));

      expect(_missing(tester), 'Still needed: a name and an ingredient');
    });

    testWidgets('names a missing name', (tester) async {
      await tester.pumpWidget(
        _host(_actions(const RecipeEditorDraft(ingredients: [_flour]))),
      );

      expect(_missing(tester), 'Still needed: a name');
    });

    testWidgets('names a missing ingredient', (tester) async {
      await tester.pumpWidget(
        _host(_actions(const RecipeEditorDraft(name: 'Bread'))),
      );

      expect(_missing(tester), 'Still needed: an ingredient');
    });

    testWidgets('a blank name counts as missing', (tester) async {
      await tester.pumpWidget(
        _host(
          _actions(const RecipeEditorDraft(name: '  ', ingredients: [_flour])),
        ),
      );

      expect(_missing(tester), 'Still needed: a name');
    });

    testWidgets('is gone once name and ingredient are there', (tester) async {
      await tester.pumpWidget(
        _host(
          _actions(
            const RecipeEditorDraft(name: 'Bread', ingredients: [_flour]),
          ),
        ),
      );

      expect(find.byKey(RecipeEditorActions.missingKey), findsNothing);
      expect(find.byKey(RecipeEditorActions.saveKey), findsOneWidget);
    });
  });

  group('RecipeEditorLines', () {
    const section = RecipeEditorSection.ingredients;

    Future<ProviderContainer> pump(
      WidgetTester tester, {
      List<String> ingredients = const [],
      List<String> steps = const [],
      Widget? bottom,
    }) async {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12)),
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        recipeEditorControllerProvider('new', null),
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(recipeEditorControllerProvider('new', null).future);
      final controller = container.read(
        recipeEditorControllerProvider('new', null).notifier,
      );
      for (final line in ingredients) {
        controller.addLine(.ingredients, line);
      }
      for (final line in steps) {
        controller.addLine(.steps, line);
      }
      final adds = {
        for (final s in RecipeEditorSection.values) s: TextEditingController(),
      };
      addTearDown(() {
        for (final c in adds.values) {
          c.dispose();
        }
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _host(
            SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, _) => RecipeEditorLines(
                  editorId: 'new',
                  recipeId: null,
                  draft: ref
                      .watch(recipeEditorControllerProvider('new', null))
                      .requireValue!
                      .draft,
                  addControllers: adds,
                  onEditPendingChanged: (_) {},
                ),
              ),
            ),
            bottom: bottom,
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    List<String> texts(ProviderContainer container, RecipeEditorSection s) =>
        container
            .read(recipeEditorControllerProvider('new', null))
            .requireValue!
            .draft
            .linesOf(s)
            .map((line) => line.text)
            .toList();

    testWidgets('typing in the field of a tapped line changes that line', (
      tester,
    ) async {
      final container = await pump(
        tester,
        ingredients: ['200 g Flour', '1 Onion'],
      );

      await tester.tap(find.byKey(RecipeEditorLines.lineKey(section, 1)));
      await tester.pump();
      await tester.enterText(
        find.byKey(RecipeEditorLineRow.fieldKey),
        '2 Onions',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(texts(container, section), ['200 g Flour', '2 Onions']);
      expect(find.byKey(RecipeEditorLineRow.fieldKey), findsNothing);
    });

    testWidgets('the remove button removes the line and the snack bar '
        'brings it back where it stood', (tester) async {
      final container = await pump(
        tester,
        ingredients: ['200 g Flour', '1 Onion', 'Salt'],
      );

      await tester.tap(find.byKey(RecipeEditorLines.lineKey(section, 1)));
      await tester.pump();
      await tester.tap(find.byKey(RecipeEditorLineRow.removeKey));
      await tester.pumpAndSettle();

      expect(texts(container, section), ['200 g Flour', 'Salt']);
      expect(find.byKey(RecipeEditorLines.removedKey), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(texts(container, section), ['200 g Flour', '1 Onion', 'Salt']);
    });

    testWidgets('an emptied field removes the line', (tester) async {
      final container = await pump(tester, steps: ['Knead', 'Bake']);

      await tester.tap(
        find.byKey(RecipeEditorLines.lineKey(RecipeEditorSection.steps, 0)),
      );
      await tester.pump();
      await tester.enterText(find.byKey(RecipeEditorLineRow.fieldKey), '  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(texts(container, RecipeEditorSection.steps), ['Bake']);
    });

    testWidgets('the add field stays in view above the bottom bar after '
        'each added line', (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const barHeight = 120.0;
      final container = await pump(
        tester,
        ingredients: ['a', 'b', 'c', 'd', 'e'],
        bottom: const SizedBox(height: barHeight),
      );
      final field = find.byKey(RecipeEditorLines.addKey(section));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();

      for (final text in ['f', 'g', 'h']) {
        await tester.enterText(field, text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        final rect = tester.getRect(field);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(500 - barHeight));
      }
      expect(texts(container, section), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
      ]);
    });
  });
}
