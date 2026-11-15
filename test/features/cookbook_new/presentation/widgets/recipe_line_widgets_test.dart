import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_line_states.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_status_card.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ListView(children: [child])),
);

RecipeIngredientLine _line({bool ignored = false}) => RecipeIngredientLine(
  ingredient: '200 g Flour',
  isIgnored: ignored,
  row: const RecipeIngredientRow(
    text: '200 g Flour',
    requirement: TemplateIngredientRequirement(
      amount: 200,
      unit: TemplateIngredientUnit.gram,
      name: 'Flour',
    ),
  ),
);

IconData? _leadIcon(WidgetTester tester) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byKey(RecipeIngredientTile.tileKey(0)),
        matching: find.byType(Icon),
      ),
    )
    .icon;

Finder _inTile(String text) => find.descendant(
  of: find.byKey(RecipeIngredientTile.tileKey(0)),
  matching: find.text(text),
);

Future<void> _pumpTile(WidgetTester tester, RecipeLineState? state) =>
    tester.pumpWidget(
      _host(
        KeyedSubtree(
          key: RecipeIngredientTile.tileKey(0),
          child: RecipeIngredientTile(line: _line(), state: state),
        ),
      ),
    );

Future<void> _pumpCard(
  WidgetTester tester, {
  int ready = 0,
  int shopping = 0,
  int ignored = 0,
  int open = 0,
}) => tester.pumpWidget(
  _host(
    RecipeLineStatusCard(
      ready: ready,
      shopping: shopping,
      ignored: ignored,
      open: open,
    ),
  ),
);

String _cardTexts(WidgetTester tester) => find
    .descendant(
      of: find.byKey(RecipeLineStatusCard.cardKey),
      matching: find.byType(Text),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data)
    .join(' | ');

void main() {
  group('RecipeLineStatusCard', () {
    testWidgets('open lines come first in the title', (tester) async {
      await _pumpCard(tester, ready: 2, shopping: 1, ignored: 1, open: 3);

      expect(
        _cardTexts(tester),
        '3 still open | 2 ready · 1 on the shopping list · 1 left out · '
        '3 open',
      );
    });

    testWidgets('shopping lines come before ready in the title', (
      tester,
    ) async {
      await _pumpCard(tester, ready: 2, shopping: 2);

      expect(
        _cardTexts(tester),
        '2 on the shopping list | 2 ready · 2 on the shopping list',
      );
    });

    testWidgets('all lines ready says "All ready" and joins only counts', (
      tester,
    ) async {
      await _pumpCard(tester, ready: 3, ignored: 1);

      expect(_cardTexts(tester), 'All ready | 3 ready · 1 left out');
    });

    testWidgets('a count of 0 is left out of the line', (tester) async {
      await _pumpCard(tester, ready: 1, open: 1);

      expect(_cardTexts(tester), '1 still open | 1 ready · 1 open');
    });
  });

  group('RecipeIngredientTile', () {
    testWidgets('without a state it has no lead icon and no state text', (
      tester,
    ) async {
      await _pumpTile(tester, null);

      expect(find.byType(Icon), findsNothing);
      expect(_inTile('open'), findsNothing);
      expect(_inTile('200 g '), findsNothing);
      expect(find.textContaining('Flour', findRichText: true), findsOneWidget);
    });

    testWidgets('ready shows a check and what the stock holds', (tester) async {
      await _pumpTile(
        tester,
        const RecipeLineAssigned('200 g Flour', (
          amount: 750,
          unit: InventoryAmountUnit.gram,
        )),
      );

      expect(_leadIcon(tester), Icons.check_rounded);
      expect(find.textContaining('750'), findsOneWidget);
    });

    testWidgets('part in the Vorrat and the rest on the list: a cart and '
        '"da · im Einkauf"', (tester) async {
      await _pumpTile(
        tester,
        const RecipeLineAssigned(
          '500 g Flour',
          (amount: 300, unit: InventoryAmountUnit.gram),
          rest: (amount: 200, unit: InventoryAmountUnit.gram),
        ),
      );

      expect(_leadIcon(tester), Icons.shopping_cart_outlined);
      expect(find.textContaining('300'), findsOneWidget);
      expect(find.textContaining('200'), findsWidgets);
      expect(find.textContaining('shopping', findRichText: true), findsOne);
    });

    testWidgets('shopping shows a cart and "on the shopping list"', (
      tester,
    ) async {
      await _pumpTile(tester, const RecipeLineShopping('200 g Flour'));

      expect(_leadIcon(tester), Icons.shopping_cart_outlined);
      expect(_inTile('on the shopping list'), findsOneWidget);
    });

    testWidgets('left out shows a minus and "left out"', (tester) async {
      await _pumpTile(tester, const RecipeLineIgnored('200 g Flour'));

      expect(_leadIcon(tester), Icons.remove_rounded);
      expect(_inTile('left out'), findsOneWidget);
    });

    testWidgets('open shows a hollow dot and "open"', (tester) async {
      await _pumpTile(tester, const RecipeLineOpen('200 g Flour'));

      expect(_leadIcon(tester), Icons.circle_outlined);
      expect(_inTile('open'), findsOneWidget);
    });

    testWidgets("the cook's own amount replaces the recipe amount", (
      tester,
    ) async {
      await _pumpTile(
        tester,
        const RecipeLineShopping('200 g Flour', own: (amount: 300, unit: null)),
      );

      expect(find.textContaining('300 g', findRichText: true), findsOneWidget);
      expect(find.textContaining('200 g', findRichText: true), findsNothing);
    });

    testWidgets('an own amount of 0 shows 0', (tester) async {
      await _pumpTile(
        tester,
        const RecipeLineAssigned(
          '200 g Flour',
          null,
          own: (amount: 0, unit: null),
        ),
      );

      expect(find.textContaining('0 g', findRichText: true), findsOneWidget);
    });
  });

  testWidgets('the estimate shows the macros as three columns', (tester) async {
    await tester.pumpWidget(
      _host(
        const RecipeEstimateLine(
          portion: (
            values: (kcal: 400, protein: 20, carbs: 40, fat: 10),
            estimated: true,
          ),
        ),
      ),
    );

    expect(find.byType(MacroGrams), findsOneWidget);
    // Number and unit stay together with a no-break space.
    expect(find.text('20\u00A0g'), findsOneWidget);
    expect(find.text('40\u00A0g'), findsOneWidget);
    expect(find.text('10\u00A0g'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
  });

  testWidgets('a hero without a picture is not forced to the hero height', (
    tester,
  ) async {
    final recipe = preparedMealTestData(id: 'pan').copyWith(
      name: 'Pan',
      imageUrl: null,
      imageAssetId: null,
      components: const [],
    );
    await tester.pumpWidget(_host(RecipeHero(recipe: recipe, onRemove: () {})));

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(RecipeHero)).height,
      lessThan(AppGraphit.recipeHeroHeight),
    );
  });
}
