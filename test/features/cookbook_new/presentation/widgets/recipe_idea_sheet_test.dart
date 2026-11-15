import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_idea_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_line_nutrition_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_nutrition_section.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_ai_chef.dart';
import '../../../../helpers/fake_inventory_item_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 10);
const _openKey = ValueKey<String>('open-idea');

class _Harness {
  new({
    required this.chef,
    required this.templates,
    required this.idea,
    required this.app,
  });

  final FakeAiChef chef;
  final FakePreparedMealTemplateRepository templates;
  final AiChefRecipeIdea idea;
  final Widget app;

  /// What `onSaving` got, in order: the save, and `null` when it failed.
  final savings = <Future<PreparedMeal?>?>[];
  bool closed = false;
}

Future<_Harness> _harness(
  WidgetTester tester, {
  FakeAiChef? chef,
  List<InventoryItem> stock = const [],
  Locale locale = const Locale('de'),
  double textScale = 1,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = chef ?? FakeAiChef();
  final templates = FakePreparedMealTemplateRepository();
  final idea = await tester.runAsync(
    () => fake.repository.loadRecipeIdea(
      languageCode: locale.languageCode,
      seed: 'x',
      now: _now,
    ),
  );
  late final _Harness harness;
  final app = UncontrolledProviderScope(
    container: ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        aiChefRepositoryProvider.overrideWithValue(fake.repository),
        aiChefImageGeneratorProvider.overrideWithValue(fake.imageGenerator),
        preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(stock),
        ),
      ],
    ),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            key: _openKey,
            onPressed: () async {
              await RecipeIdeaSheet.show(
                context,
                idea: harness.idea,
                onSaving: harness.savings.add,
              );
              harness.closed = true;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  harness = _Harness(chef: fake, templates: templates, idea: idea!, app: app);
  await tester.pumpWidget(app);
  return harness;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Lets the real asynchronous fakes run, then draws the result.
Future<void> _real(WidgetTester tester, [int milliseconds = 60]) async {
  await tester.runAsync(
    () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
  );
  await tester.pumpAndSettle();
}

InventoryItem _pasta() => InventoryItem.create(
  id: 'pasta-1',
  name: 'Pasta',
  entryDate: DateTime.utc(2026, 11),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
);

/// Scrolls the window down until [finder] is built and on screen: the label
/// of the estimated portion pushes what is under it off screen.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byType(RecipeIdeaSheet),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
  // A little further, clear of the lower edge.
  await tester.drag(scrollable, const Offset(0, -120));
  await tester.pump();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(RecipeIdeaSheet)))!;

void main() {
  testWidgets(
    'shows the name, kcal and macros of one portion and the portions',
    (tester) async {
      await _harness(tester).then((h) => _open(tester));
      final l10n = _l10n(tester);

      expect(find.text('Tomatenpasta'), findsOneWidget);
      expect(find.text(l10n.recipeEstimateKcal(300)), findsOneWidget);
      expect(find.text('10\u00A0g'), findsWidgets);
      expect(find.text('40\u00A0g'), findsWidgets);
      expect(find.text('7\u00A0g'), findsWidgets);
      expect(find.text(l10n.cookPortionsLabel(2)), findsOneWidget);
    },
  );

  testWidgets('lists the ingredients, then the steps', (tester) async {
    await _harness(tester).then((h) => _open(tester));
    final l10n = _l10n(tester);

    expect(
      find.text(l10n.cookingIngredientsTitle.toUpperCase()),
      findsOneWidget,
    );
    expect(find.byKey(RecipeIngredientTile.tileKey(0)), findsOneWidget);
    expect(find.byKey(RecipeIngredientTile.tileKey(1)), findsOneWidget);
    expect(find.byKey(RecipeIngredientTile.tileKey(2)), findsNothing);
    // The label of the portion and the nutrition per ingredient come before
    // the steps.
    await _scrollTo(tester, find.text(l10n.recipeStepsTitle.toUpperCase()));
    expect(find.text(l10n.recipeStepsTitle.toUpperCase()), findsOneWidget);
    expect(find.text('Pasta kochen.'), findsOneWidget);
    expect(find.text('Sauce dazugeben.'), findsOneWidget);
  });

  testWidgets('marks the ingredient that the Vorrat holds', (tester) async {
    final h = await _harness(tester, stock: [_pasta()]);
    await _open(tester);
    await _real(tester);

    RecipeIngredientTile tile(int index) => tester.widget<RecipeIngredientTile>(
      find.byKey(RecipeIngredientTile.tileKey(index)),
    );
    expect(tile(0).inStock, isTrue);
    expect(tile(1).inStock, isFalse);
    expect(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(0)),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(1)),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
    expect(h.closed, isFalse);
  });

  group('the ingredient column', () {
    double textLeft(WidgetTester tester, int index) => tester
        .getTopLeft(
          find.descendant(
            of: find.byKey(RecipeIngredientTile.tileKey(index)),
            matching: find.byType(Text),
          ),
        )
        .dx;

    testWidgets('starts at the text edge while the Vorrat holds none', (
      tester,
    ) async {
      await _harness(tester);
      await _open(tester);
      await _real(tester);

      for (final index in [0, 1]) {
        expect(
          tester
              .widget<RecipeIngredientTile>(
                find.byKey(RecipeIngredientTile.tileKey(index)),
              )
              .inStock,
          isNull,
        );
      }
      expect(
        textLeft(tester, 0),
        tester.getTopLeft(find.text('Tomatenpasta')).dx,
      );
      expect(textLeft(tester, 1), textLeft(tester, 0));
    });

    testWidgets('has the check column for every row once a line is in stock', (
      tester,
    ) async {
      await _harness(tester, stock: [_pasta()]);
      await _open(tester);
      await _real(tester);

      expect(
        textLeft(tester, 0),
        greaterThan(tester.getTopLeft(find.text('Tomatenpasta')).dx),
      );
      expect(textLeft(tester, 1), textLeft(tester, 0));
    });
  });

  testWidgets('shows the food label of one estimated portion above the '
      'nutrition per ingredient', (tester) async {
    await _harness(tester).then((h) => _open(tester));
    final l10n = _l10n(tester);
    final toggle = find.byKey(RecipeLineNutritionSection.toggleKey);

    await _scrollTo(tester, toggle);

    final label = find.byKey(RecipeNutritionSection.labelKey);
    expect(label, findsOneWidget);
    expect(tester.getTopLeft(label).dy, lessThan(tester.getTopLeft(toggle).dy));
    final table = tester.widget<EatLabelTable>(label);
    expect(table.eatenHeader, l10n.recipeNutritionPortionEstimated);
    expect(table.per100Header, isNull);
    // Energy, fat, carbohydrates and protein of the idea's estimate.
    expect(table.rows, hasLength(4));
    expect(table.rows.first.eaten, allOf(contains('kJ'), contains('300')));
    expect(table.rows.map((row) => row.eaten).skip(1), ['7 g', '40 g', '10 g']);
  });

  testWidgets('has the nutrition per ingredient folded', (tester) async {
    await _harness(tester).then((h) => _open(tester));
    final toggle = find.byKey(RecipeLineNutritionSection.toggleKey);

    await _scrollTo(tester, toggle);
    expect(toggle, findsOneWidget);
    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsNothing);

    await tester.tap(toggle);
    await tester.pump();
    await _scrollTo(tester, find.byKey(RecipeLineNutritionSection.tableKey));

    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsOneWidget);
  });

  testWidgets('shows no steps heading when the idea has no steps', (
    tester,
  ) async {
    await _harness(
      tester,
      chef: FakeAiChef(answer: recipeIdeaAnswer(steps: const [])),
    ).then((h) => _open(tester));

    expect(
      find.text(_l10n(tester).recipeStepsTitle.toUpperCase()),
      findsNothing,
    );
  });

  testWidgets('shows at once with a plain place while the picture is made', (
    tester,
  ) async {
    final hold = Completer<void>();
    final h = await _harness(tester, chef: FakeAiChef()..pictureHold = hold);
    await _open(tester);

    expect(find.text('Tomatenpasta'), findsOneWidget);
    expect(find.byKey(RecipeIdeaSheet.saveKey), findsOneWidget);
    expect(find.byKey(RecipeIdeaSheet.pictureKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(RecipeIdeaSheet.pictureKey),
        matching: find.byType(ClipRRect),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(h.chef.pictureCalls, 1);

    hold.complete();
    await _real(tester, 150);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Tomatenpasta'), findsOneWidget);
  });

  testWidgets('without a picture the place stays and nothing moves', (
    tester,
  ) async {
    final hold = Completer<void>();
    final h = await _harness(
      tester,
      chef: FakeAiChef()
        ..pictureFails = true
        ..pictureHold = hold,
    );
    await _open(tester);
    final pictureSize = tester.getSize(find.byKey(RecipeIdeaSheet.pictureKey));
    final tileTop = tester
        .getTopLeft(find.byKey(RecipeIngredientTile.tileKey(0)))
        .dy;
    expect(h.chef.pictureCalls, 1);

    hold.complete();
    await _real(tester);

    expect(find.text('Tomatenpasta'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(RecipeIdeaSheet.saveKey), findsOneWidget);
    final place = find.byKey(RecipeIdeaSheet.pictureKey);
    expect(place, findsOneWidget);
    expect(tester.getSize(place), pictureSize);
    expect(pictureSize.height, closeTo(pictureSize.width * 9 / 16, 0.5));
    expect(
      tester.getTopLeft(find.byKey(RecipeIngredientTile.tileKey(0))).dy,
      tileTop,
    );
  });

  testWidgets('has one save button on one line', (tester) async {
    await _harness(tester).then((h) => _open(tester));
    final l10n = _l10n(tester);

    final button = find.byKey(RecipeIdeaSheet.saveKey);
    expect(button, findsOneWidget);
    final label = find.descendant(
      of: button,
      matching: find.text(l10n.aiChefSaveAction),
    );
    expect(label, findsOneWidget);
    final style =
        tester.widget<Text>(label).style ??
        DefaultTextStyle.of(tester.element(label)).style;
    final line = (style.fontSize ?? 14) * (style.height ?? 1.4);
    expect(tester.getSize(label).height, lessThan(line * 1.5));
    expect(
      find.descendant(
        of: find.byType(RecipeIdeaSheet),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('saving closes the window and hands out the saved recipe', (
    tester,
  ) async {
    final h = await _harness(tester);
    await _open(tester);

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await _real(tester);

    expect(h.closed, isTrue);
    expect(find.byType(RecipeIdeaSheet), findsNothing);
    expect(h.savings, hasLength(1));
    final saved = await tester.runAsync(() => h.savings.single!);
    expect(saved, isNotNull);
    expect(h.templates.templates.map((meal) => meal.id), [saved!.id]);
  });

  testWidgets('a failed save shows the error and the button works again', (
    tester,
  ) async {
    final h = await _harness(tester);
    h.templates.failWrites = true;
    await _open(tester);

    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await _real(tester);

    expect(find.text(_l10n(tester).aiChefSaveError), findsOneWidget);
    expect(h.closed, isFalse);
    expect(h.savings.last, isNull);
    expect(
      tester
          .widget<FilledButton>(find.byKey(RecipeIdeaSheet.saveKey))
          .onPressed,
      isNotNull,
    );

    h.templates.failWrites = false;
    await tester.tap(find.byKey(RecipeIdeaSheet.saveKey));
    await _real(tester);

    expect(h.closed, isTrue);
    final saved = await tester.runAsync(() => h.savings.last!);
    expect(saved, isNotNull);
    expect(h.templates.templates, hasLength(1));
  });

  testWidgets('closing the window without saving drops the idea', (
    tester,
  ) async {
    final h = await _harness(tester);
    await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await _real(tester);

    expect(h.closed, isTrue);
    expect(h.savings, isEmpty);
    expect(h.templates.templates, isEmpty);
    expect(h.chef.uploads, isEmpty);
  });
}
