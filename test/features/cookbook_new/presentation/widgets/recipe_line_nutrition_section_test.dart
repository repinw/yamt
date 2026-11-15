import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_nutrition_section.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/l10n/app_localizations.dart';

const List<({String food, RecipeLineNutrition nutrition})> _rows = [
  (
    food: 'Pasta',
    nutrition: RecipeLineNutrition(
      kcal: 1234.4,
      protein: 24.4,
      carbs: 140.6,
      fat: 4,
    ),
  ),
  (
    food: 'Tomaten',
    nutrition: RecipeLineNutrition(kcal: 20, protein: 1, carbs: 4, fat: 0.4),
  ),
];

Future<void> _pump(WidgetTester tester, {int portions = 2}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipeLineNutritionSection(rows: _rows, portions: portions),
        ),
      ),
    );

Color? _colorOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style?.color;

void main() {
  testWidgets('is folded at first: the title only, no table', (tester) async {
    await _pump(tester);

    expect(find.text('Nutrition per ingredient'), findsOneWidget);
    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsNothing);
    expect(find.text('Pasta'), findsNothing);
  });

  testWidgets('opens a table with one row per ingredient', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pump();

    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    expect(table, findsOneWidget);
    for (final food in ['Pasta', 'Tomaten']) {
      expect(
        find.descendant(of: table, matching: find.text(food)),
        findsOneWidget,
      );
    }
    // Whole numbers, with the thousands separator of the language.
    for (final number in ['1,234', '24', '141', '4', '20', '1']) {
      expect(
        find.descendant(of: table, matching: find.text(number)),
        findsWidgets,
        reason: number,
      );
    }
  });

  testWidgets('folds again on a second tap', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pump();
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pump();

    expect(find.byKey(RecipeLineNutritionSection.tableKey), findsNothing);
  });

  testWidgets('the macro numbers have the macro colours, kcal stays plain', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pump();
    final context = tester.element(
      find.byKey(RecipeLineNutritionSection.tableKey),
    );
    final macros = MacroGrams.textColors(context);
    final table = find.byKey(RecipeLineNutritionSection.tableKey);
    Finder inTable(String text) =>
        find.descendant(of: table, matching: find.text(text));

    expect(_colorOf(tester, inTable('24')), macros.protein);
    expect(_colorOf(tester, inTable('141')), macros.carbs);
    expect(_colorOf(tester, inTable('1,234')), isNot(macros.protein));
    expect(_colorOf(tester, inTable('1,234')), isNot(macros.carbs));
    expect(_colorOf(tester, inTable('1,234')), isNot(macros.fat));
    expect(<Color>{macros.protein, macros.carbs, macros.fat}, hasLength(3));
  });

  testWidgets('has the column headers over the numbers', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecipeLineNutritionSection)),
    )!;

    for (final header in [
      l10n.caloriesUnitKcal,
      l10n.caloriesProteinShortLetter,
      l10n.macroGramsCarbsShort,
      l10n.caloriesFatShortLetter,
    ]) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
  });

  group('the head row', () {
    for (final (portions, text) in [
      (1, 'For 1 portion'),
      (2, 'For 2 portions'),
      (6, 'For 6 portions'),
    ]) {
      testWidgets('says "$text" when open', (tester) async {
        await _pump(tester, portions: portions);
        expect(find.text(text), findsNothing);

        await tester.tap(find.byKey(RecipeLineNutritionSection.toggleKey));
        await tester.pump();

        final table = find.byKey(RecipeLineNutritionSection.tableKey);
        expect(
          find.descendant(of: table, matching: find.text(text)),
          findsOneWidget,
        );
      });
    }
  });
}
