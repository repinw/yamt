import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

const _lines = ['500 g Beans'];

RecipeEstimate _estimate({List<String> lines = _lines}) => RecipeEstimate(
  kcal: 412.4,
  protein: 23.6,
  carbs: 40,
  fat: 10,
  portions: 3,
  linesKey: recipeLinesKey(lines),
  createdAt: DateTime.utc(2026, 11, 7),
);

PreparedMeal _chili({RecipeEstimate? estimate}) => preparedMealTestData(
  id: 'chili',
).copyWith(name: 'Chili', recipeIngredients: _lines, recipeEstimate: estimate);

Widget _card(
  PreparedMeal meal, {
  VoidCallback? onOpen,
  bool isEstimating = false,
}) => UncontrolledProviderScope(
  // Before cooking the portion is the recipe's estimate.
  container: ProviderContainer.test(
    overrides: [
      recipePortionProvider(
        meal.id,
      ).overrideWithValue(switch (meal.fittingRecipeEstimate) {
        final estimate? => (values: estimateValues(estimate), estimated: true),
        null => null,
      }),
    ],
  ),
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: CookbookRecipeCard(
          entry: CookbookEntry(meal: meal, inStock: const [true]),
          onOpen: onOpen ?? () {},
          onRemove: () {},
          onPlan: () {},
          isEstimating: isEstimating,
        ),
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  PreparedMeal meal, {
  VoidCallback? onOpen,
}) async {
  await tester.pumpWidget(_card(meal, onOpen: onOpen));
  await tester.pumpAndSettle();
}

void main() {
  Finder lines(String id) => find.descendant(
    of: find.byKey(CookbookRecipeCard.estimateKey(id)),
    matching: find.byType(Text),
  );

  testWidgets('shows kcal and macros of a fitting estimate', (tester) async {
    await _pump(tester, _chili(estimate: _estimate()));

    final texts = tester.widgetList<Text>(lines('chili')).toList();
    expect(texts, hasLength(2));
    expect(texts.first.data, '≈ 412 kcal');
    expect(
      texts.last.textSpan!.toPlainText(),
      'P\u00A024 · C\u00A040 · F\u00A010',
    );
    expect(find.byType(MacroGrams), findsOneWidget);
  });

  testWidgets('shows empty lines for a stale estimate', (tester) async {
    await _pump(
      tester,
      _chili(estimate: _estimate(lines: const ['1 kg Other'])),
    );

    expect(tester.widgetList<Text>(lines('chili')).map((text) => text.data), [
      '',
      '',
    ]);
    expect(
      tester
          .getSize(find.byKey(CookbookRecipeCard.estimateKey('chili')))
          .height,
      greaterThan(0),
    );
  });

  testWidgets('shows empty lines without an estimate and keeps the height of '
      'the card when it arrives', (tester) async {
    await _pump(tester, _chili());
    final without = tester.getSize(find.byType(CookbookRecipeCard)).height;

    expect(tester.widgetList<Text>(lines('chili')).map((text) => text.data), [
      '',
      '',
    ]);

    await _pump(tester, _chili(estimate: _estimate()));

    expect(tester.getSize(find.byType(CookbookRecipeCard)).height, without);
  });

  testWidgets('shows a spinner while the estimate is coming', (tester) async {
    // A running spinner never settles.
    await tester.pumpWidget(_card(_chili(), isEstimating: true));
    await tester.pump();

    expect(
      find.byKey(CookbookRecipeCard.estimatingKey('chili')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows no spinner when no estimate is coming', (tester) async {
    await _pump(tester, _chili());

    expect(find.byKey(CookbookRecipeCard.estimatingKey('chili')), findsNothing);
  });

  testWidgets('a fitting estimate shows instead of the spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(_chili(estimate: _estimate()), isEstimating: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CookbookRecipeCard.estimatingKey('chili')), findsNothing);
    expect(find.text('≈ 412 kcal'), findsOneWidget);
  });

  testWidgets('a stale estimate gives way to the spinner', (tester) async {
    await tester.pumpWidget(
      _card(
        _chili(estimate: _estimate(lines: const ['1 kg Other'])),
        isEstimating: true,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(CookbookRecipeCard.estimatingKey('chili')),
      findsOneWidget,
    );
  });

  testWidgets('a tap on the card opens the recipe', (tester) async {
    var opened = 0;
    await _pump(tester, _chili(), onOpen: () => opened++);

    await tester.tap(find.byType(CookbookRecipeCard));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
