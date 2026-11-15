import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_line_states.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_status_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ListView(children: [child])),
);

Future<void> _pumpTile(WidgetTester tester, RecipeLineState state) =>
    tester.pumpWidget(
      _host(
        KeyedSubtree(
          key: RecipeIngredientTile.tileKey(0),
          child: RecipeIngredientTile(
            line: const RecipeIngredientLine(
              ingredient: 'Salt',
              isIgnored: false,
              row: RecipeIngredientRow(text: 'Salt'),
            ),
            state: state,
          ),
        ),
      ),
    );

Color? _colorOf(WidgetTester tester, String text) => tester
    .widget<RichText>(find.textContaining(text, findRichText: true))
    .text
    .style
    ?.color;

void main() {
  group('RecipeIngredientTile', () {
    testWidgets('a line that does not count says so and stays plain', (
      tester,
    ) async {
      await _pumpTile(
        tester,
        const RecipeLineIgnored('Salt', notCounted: true),
      );

      expect(find.text("doesn't count"), findsOneWidget);
      expect(find.text('left out'), findsNothing);
    });

    testWidgets('a line the cook left out is muted, one that does not count '
        'is not', (tester) async {
      await _pumpTile(tester, const RecipeLineIgnored('Salt'));
      final leftOut = _colorOf(tester, 'Salt');
      await _pumpTile(
        tester,
        const RecipeLineIgnored('Salt', notCounted: true),
      );
      final notCounted = _colorOf(tester, 'Salt');

      expect(leftOut, isNotNull);
      expect(notCounted, isNotNull);
      expect(notCounted, isNot(leftOut));
    });
  });

  group('RecipeLineStatusCard', () {
    testWidgets('with every count 0 there is no counts line', (tester) async {
      await tester.pumpWidget(
        _host(
          const RecipeLineStatusCard(
            ready: 0,
            shopping: 0,
            ignored: 0,
            open: 0,
          ),
        ),
      );

      final texts = find.descendant(
        of: find.byKey(RecipeLineStatusCard.cardKey),
        matching: find.byType(Text),
      );
      expect(texts, findsOneWidget);
      expect(tester.widget<Text>(texts).data, 'All ready');
    });
  });
}
