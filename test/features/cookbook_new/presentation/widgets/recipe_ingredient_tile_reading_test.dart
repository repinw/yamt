import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

RecipeView _view(List<String> lines) => buildRecipeView(
  recipeId: 'r1',
  templates: AsyncData([
    preparedMealTestData(
      id: 'r1',
      name: 'Test',
      totalPortions: 2,
    ).copyWith(components: const [], recipeIngredients: lines),
  ]),
  items: const AsyncData([]),
  parser: const TemplateIngredientParser(),
  localeCode: 'de',
  portions: null,
).requireValue!;

Future<void> _pump(WidgetTester tester, RecipeView view) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        children: [
          for (final (index, line) in view.lines.indexed)
            KeyedSubtree(
              key: RecipeIngredientTile.tileKey(index),
              child: RecipeIngredientTile(line: line),
            ),
        ],
      ),
    ),
  ),
);

String _shown(WidgetTester tester, int index) => tester
    .widget<RichText>(
      find
          .descendant(
            of: find.byKey(RecipeIngredientTile.tileKey(index)),
            matching: find.byType(RichText),
          )
          .first,
    )
    .text
    .toPlainText();

void main() {
  group('the recipe page reads a line like the Kochmodus', () {
    const lines = [
      '½ Zitrone',
      'eine halbe Zitrone',
      'zwei Zwiebeln',
      '1,250 kg Mehl',
      '0,1 g Safran',
    ];

    test('gives the amount and the food of each line', () {
      final rows = _view(lines).lines.map((line) => line.row).toList();

      for (final index in [0, 1]) {
        expect(rows[index].requirement?.exactQuantity, 0.5);
        expect(rows[index].requirement?.unit, TemplateIngredientUnit.piece);
        expect(rows[index].foodName, 'Zitrone');
      }
      expect(rows[2].requirement?.amount, 2);
      expect(rows[2].requirement?.unit, TemplateIngredientUnit.piece);
      expect(rows[2].foodName, 'Zwiebeln');
      expect(rows[3].requirement?.amount, 1250);
      expect(rows[3].requirement?.unit, TemplateIngredientUnit.gram);
      expect(rows[3].foodName, 'Mehl');
    });

    test('keeps the text of the lines as they were written', () {
      expect(_view(lines).lines.map((line) => line.ingredient), lines);
    });

    testWidgets('shows the amount and the food on the tile', (tester) async {
      final view = _view(lines);
      await _pump(tester, view);

      expect(_shown(tester, 0), '1/2 Zitrone');
      expect(_shown(tester, 1), '1/2 Zitrone');
      expect(_shown(tester, 2), '2 Zwiebeln');
      expect(_shown(tester, 3), '1250 g Mehl');
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps a line with a fraction of a gram whole', (tester) async {
      final view = _view(['0,1 g Safran']);
      await _pump(tester, view);

      expect(view.lines.single.row.requirement, isNull);
      expect(_shown(tester, 0), '0,1 g Safran');
    });
  });
}
