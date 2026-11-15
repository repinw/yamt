import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_idea_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_idea_sheet.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/fake_ai_chef.dart';
import '../../../helpers/fake_ai_chef_exclusions_repository.dart';
import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';

const _openKey = ValueKey<String>('start-idea');

Future<({FakeAiChef chef, FakePreparedMealTemplateRepository templates})> _pump(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chef = FakeAiChef();
  final templates = FakePreparedMealTemplateRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 13)),
        aiChefRepositoryProvider.overrideWithValue(chef.repository),
        aiChefExclusionsRepositoryProvider.overrideWithValue(
          FakeAiChefExclusionsRepository(),
        ),
        aiChefImageGeneratorProvider.overrideWithValue(chef.imageGenerator),
        preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(const []),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              key: _openKey,
              onPressed: () => RecipeIdeaFlow.start(context),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    ),
  );
  return (chef: chef, templates: templates);
}

Future<void> _toWindow(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(AiChefSetupView.generateKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks first, then shows the idea as a recipe', (tester) async {
    final h = await _pump(tester);

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
    expect(find.byKey(AiChefSetupView.generateKey), findsOneWidget);
    expect(find.byType(RecipeIdeaSheet), findsNothing);

    await tester.tap(find.byKey(AiChefSetupView.generateKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsOneWidget);
    expect(find.text('Tomatenpasta'), findsOneWidget);
    expect(h.templates.templates, isEmpty);
  });

  testWidgets('saving shows the snack bar with undo and keeps the recipe', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _toWindow(tester);

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    final snackBar = find.byKey(RecipeIdeaFlow.savedSnackBarKey);
    expect(snackBar, findsOneWidget);
    expect(
      find.descendant(
        of: snackBar,
        matching: find.text('Saved to the cookbook.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: snackBar, matching: find.byType(TextButton)),
      findsOneWidget,
    );
    expect(h.templates.templates.single.name, 'Tomatenpasta');
    // The picture is put on the recipe after the save.
    expect(h.chef.uploads, [
      FakeAiChef.coverPath(h.templates.templates.single.id),
    ]);
  });

  testWidgets('a recipe that shows late still gets its picture', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _toWindow(tester);
    final show = h.templates.showHold = Completer();

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();
    expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsOneWidget);
    expect(h.chef.uploads, isEmpty);

    show.complete();
    await tester.pumpAndSettle();

    final id = h.templates.templates.single.id;
    expect(h.chef.uploads, [FakeAiChef.coverPath(id)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo before the recipe showed leaves no picture and no error', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _toWindow(tester);
    h.templates.showHold = Completer();
    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(RecipeIdeaFlow.savedSnackBarKey),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 31));

    expect(h.chef.uploads, isEmpty);
    expect(find.byKey(RecipeIdeaFlow.saveFailedSnackBarKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a recipe that never shows ends the wait with nothing on screen',
    (tester) async {
      final h = await _pump(tester);
      await _toWindow(tester);
      h.templates.showHold = Completer();
      await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();

      expect(h.chef.uploads, isEmpty);
      expect(find.byKey(RecipeIdeaFlow.saveFailedSnackBarKey), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('undo removes the recipe', (tester) async {
    final h = await _pump(tester);
    await _toWindow(tester);
    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await tester.pumpAndSettle();
    expect(h.templates.templates, hasLength(1));

    await tester.tap(
      find.descendant(
        of: find.byKey(RecipeIdeaFlow.savedSnackBarKey),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(h.templates.templates, isEmpty);
    expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsNothing);
  });

  testWidgets('closing the window without saving shows no snack bar', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _toWindow(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsNothing);
    expect(h.templates.templates, isEmpty);
    expect(h.chef.uploads, isEmpty);
  });

  testWidgets('closing the first sheet ends the flow', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(h.chef.templateCalls, 0);
  });

  testWidgets('a failed idea offers retry and does not open the window', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.chef.templateFails = true;
    await _toWindow(tester);

    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(find.byKey(AiChefSheet.retryKey), findsOneWidget);
    expect(h.templates.templates, isEmpty);
  });

  group('closing the window while it saves', () {
    final closers = <String, Future<void> Function(WidgetTester)>{
      'by dragging it down': (tester) => tester.fling(
        find.byKey(RecipeIdeaSheet.saveKey),
        const Offset(0, 600),
        2000,
      ),
      'by tapping the scrim': (tester) => tester.tapAt(const Offset(10, 10)),
      'with the system back': (tester) => tester.binding.handlePopRoute(),
    };

    for (final MapEntry(key: how, value: close) in closers.entries) {
      testWidgets('$how still says it is saved, with undo', (tester) async {
        final h = await _pump(tester);
        await _toWindow(tester);
        final hold = h.templates.writeHold = Completer();

        await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
        await tester.pump();
        await close(tester);
        await tester.pumpAndSettle();
        expect(find.byType(RecipeIdeaSheet), findsNothing);
        expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsNothing);

        hold.complete();
        await tester.pumpAndSettle();

        final snackBar = find.byKey(RecipeIdeaFlow.savedSnackBarKey);
        expect(snackBar, findsOneWidget);
        expect(
          find.descendant(of: snackBar, matching: find.byType(TextButton)),
          findsOneWidget,
        );
        expect(find.byKey(RecipeIdeaFlow.saveFailedSnackBarKey), findsNothing);
        expect(h.templates.templates, hasLength(1));
      });

      testWidgets('$how tells when the write fails', (tester) async {
        final h = await _pump(tester);
        await _toWindow(tester);
        final hold = h.templates.writeHold = Completer();
        h.templates.failWrites = true;

        await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
        await tester.pump();
        await close(tester);
        await tester.pumpAndSettle();
        expect(find.byType(RecipeIdeaSheet), findsNothing);

        hold.complete();
        await tester.pumpAndSettle();

        final snackBar = find.byKey(RecipeIdeaFlow.saveFailedSnackBarKey);
        expect(snackBar, findsOneWidget);
        expect(
          find.descendant(
            of: snackBar,
            matching: find.text(
              AppLocalizations.of(tester.element(find.byKey(_openKey)))!
                  .aiChefSaveError,
            ),
          ),
          findsOneWidget,
        );
        expect(find.byKey(RecipeIdeaFlow.savedSnackBarKey), findsNothing);
        expect(h.templates.templates, isEmpty);
      });
    }
  });
}
