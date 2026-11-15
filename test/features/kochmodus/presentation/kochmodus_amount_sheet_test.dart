import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_sheet.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_sheet_pump.dart';

// The view of [line] of a run of 4 portions with [items] in the Vorrat.
KochmodusLineView _view(
  CookRunLine line, {
  List<InventoryItem> items = const [],
}) {
  final run = buildCookRun(
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    lines: [line],
  );
  return buildKochmodusView(
    run: run,
    saved: true,
    ended: false,
    busy: false,
    reopened: false,
    finished: null,
    tab: null,
    items: items,
    otherReservations: const {},
    utensils: const [],
    parser: const TemplateIngredientParser(),
  ).lines.single;
}

void main() {
  // "300 g Reis", 500 g in the Vorrat: the recipe says 300, the item has 500.
  KochmodusLineView rice({int? amount, int stock = 500}) => _view(
    textLine(
      'a',
      '300 g Reis',
      amount: amount,
      settlement: assigned({'i1': 300}),
    ),
    items: [stockItem('i1', stock)],
  );

  Future<void> open(
    WidgetTester tester,
    KochmodusLineView line,
    List<KochmodusAmountChoice?> results, {
    double width = 800,
    double height = 1200,
    double keyboard = 0,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) => pumpSheet<KochmodusAmountChoice>(
    tester,
    (context) => KochmodusAmountSheet.show(context, line: line, portions: 4),
    results,
    width: width,
    height: height,
    keyboard: keyboard,
    textScale: textScale,
    locale: locale,
  );

  String field(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(KochmodusAmountSheet.fieldKey))
      .controller!
      .text;

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(KochmodusAmountSheet.fieldKey), text);
    await tester.pumpAndSettle();
  }

  VoidCallback? onPressed(WidgetTester tester, Key key) {
    final button = tester.widget(find.byKey(key));
    return switch (button) {
      FilledButton(:final onPressed) => onPressed,
      IconButton(:final onPressed) => onPressed,
      _ => throw StateError('no button'),
    };
  }

  String? suffix(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(KochmodusAmountSheet.fieldKey))
      .decoration!
      .suffixText;

  group('a line without an amount', () {
    final eggs = stockItem(
      'egg',
      6000,
      unit: InventoryAmountUnit.piece,
      scale: 1000,
    );
    KochmodusLineView plain(InventoryItem item, {String text = 'Eier'}) =>
        _view(
          textLine('a', text, settlement: assigned({item.id: 0})),
          items: [item],
        );

    testWidgets('on an item in pieces counts pieces', (tester) async {
      await open(tester, plain(eggs), []);

      expect(suffix(tester), isNull);
      expect(find.byKey(KochmodusAmountSheet.availableKey), findsOneWidget);
      expect(find.textContaining('6'), findsOneWidget);
    });

    testWidgets('"+" steps by one piece', (tester) async {
      await open(tester, plain(eggs), []);

      await tapKey(tester, KochmodusAmountSheet.moreKey);

      expect(field(tester), '1');
    });

    testWidgets('on an item in grams still counts grams', (tester) async {
      await open(tester, plain(stockItem('g', 500), text: 'Reis'), []);

      expect(suffix(tester), 'g');
    });

    testWidgets('on an item in ml counts ml', (tester) async {
      await open(
        tester,
        plain(
          stockItem('m', 500, unit: InventoryAmountUnit.milliliter),
          text: 'Milch',
        ),
        [],
      );

      expect(suffix(tester), 'ml');
    });
  });

  group('an amount with a part of a unit', () {
    KochmodusLineView half({int? amount, int? amountPortions}) => _view(
      textLine(
        'a',
        '1/2 Zitrone',
        amount: amount,
        amountPortions: amountPortions,
      ),
    );

    String? hint(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(KochmodusAmountSheet.fieldKey))
        .decoration!
        .hintText;

    testWidgets('the field says no rounded number, its hint says the part', (
      tester,
    ) async {
      await open(tester, half(), []);

      expect(field(tester), isEmpty);
      expect(hint(tester), '1/2');
      expect(
        find.text(sheetL10n(tester).kochmodusAmountRecipe('1/2', 4)),
        findsOne,
      );
    });

    testWidgets('a spoon says its part too', (tester) async {
      await open(tester, _view(textLine('a', '1,5 EL Öl')), []);

      expect(field(tester), isEmpty);
      expect(hint(tester), '1,5');
    });

    testWidgets('a whole amount still fills the field', (tester) async {
      await open(tester, _view(textLine('a', '2 Zitronen')), []);

      expect(field(tester), '2');
    });

    testWidgets('a whole count shows the whole number it takes', (
      tester,
    ) async {
      final pack = packItem('w', 5);
      await open(
        tester,
        _view(
          textLine('a', '1/2 Zitrone', settlement: assigned({'w': 1})),
          items: [pack],
        ),
        [],
      );

      expect(field(tester), '1');
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
    });

    testWidgets('taking the field untouched changes nothing', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, half(), results);

      expect(onPressed(tester, KochmodusAmountSheet.applyKey), isNotNull);
      await tapKey(tester, KochmodusAmountSheet.applyKey);

      expect(results, [null]);
    });

    testWidgets('an own part taken untouched stays as it is', (tester) async {
      final line = _view(
        textLine('a', '1/2 Zitrone', amount: 3, amountPortions: 8),
      );
      expect(line.text, '1,5 Zitrone');
      final results = <KochmodusAmountChoice?>[];
      await open(tester, line, results);

      expect(hint(tester), '1,5');
      await tapKey(tester, KochmodusAmountSheet.applyKey);

      expect(results, [null]);
    });

    testWidgets('typing the whole number it rounds to sets it', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, half(), results);

      await type(tester, '1');
      await tapKey(tester, KochmodusAmountSheet.applyKey);

      expect(results, [(own: 1)]);
    });

    testWidgets('− and + step from the part to the whole numbers around it', (
      tester,
    ) async {
      await open(tester, _view(textLine('a', '1,5 EL Öl')), []);

      await tapKey(tester, KochmodusAmountSheet.moreKey);
      expect(field(tester), '2');

      await type(tester, '');
      await tapKey(tester, KochmodusAmountSheet.fewerKey);
      expect(field(tester), '1');
    });

    testWidgets('"Rezept" goes back to the part and clears the own amount', (
      tester,
    ) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, half(amount: 3, amountPortions: 4), results);

      expect(field(tester), '3');
      expect(hint(tester), '0');
      await tapKey(tester, KochmodusAmountSheet.recipeKey);

      expect(field(tester), isEmpty);
      expect(hint(tester), '1/2');
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
      expect(results, isEmpty);

      await tapKey(tester, KochmodusAmountSheet.applyKey);
      expect(results, [(own: null)]);
    });

    testWidgets('"Rezept" only shows while it would change something', (
      tester,
    ) async {
      await open(tester, half(), []);

      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);

      await type(tester, '2');
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsOneWidget);
    });

    testWidgets('"Rezept" takes back what was typed', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, half(), results);

      await type(tester, '2');
      await tapKey(tester, KochmodusAmountSheet.recipeKey);

      expect(field(tester), isEmpty);
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);

      await tapKey(tester, KochmodusAmountSheet.applyKey);
      expect(results, [null]);
    });
  });

  group('the field', () {
    testWidgets('starts with the amount of the line and its unit', (
      tester,
    ) async {
      final line = rice();
      await open(tester, line, []);

      expect(field(tester), '${line.need!.amount}');
      expect(suffix(tester), 'g');
      final input = tester.widget<TextField>(
        find.byKey(KochmodusAmountSheet.fieldKey),
      );
      expect(input.keyboardType, TextInputType.number);
      expect(input.autofocus, isFalse);
      expect(input.focusNode?.hasFocus ?? false, isFalse);
    });

    testWidgets('does not open the keyboard by itself', (tester) async {
      await open(tester, rice(), []);

      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('typing changes what "Übernehmen" returns', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, rice(), results);

      await type(tester, '170');
      await tapKey(tester, KochmodusAmountSheet.applyKey);

      expect(results, [(own: 170)]);
    });

    testWidgets('non-digits are refused', (tester) async {
      await open(tester, rice(), []);

      await type(tester, '1a2.5-,x 3');

      expect(field(tester), '1253');
    });

    testWidgets('at most five digits fit', (tester) async {
      await open(tester, rice(), []);

      await type(tester, '1234567');

      expect(field(tester), '12345');
    });

    testWidgets('the unit shows as the suffix: ml, a measure, nothing', (
      tester,
    ) async {
      await open(
        tester,
        _view(
          textLine('a', '200 ml Milch', settlement: assigned({'i1': 200})),
          items: [stockItem('i1', 500, unit: InventoryAmountUnit.milliliter)],
        ),
        [],
      );
      expect(suffix(tester), 'ml');
    });

    testWidgets('bare pieces have no suffix', (tester) async {
      await open(tester, _view(textLine('a', '2 Eier')), []);

      expect(suffix(tester), isNull);
      expect(field(tester), '${_view(textLine('a', '2 Eier')).need!.amount}');
    });

    testWidgets('a line without amount starts empty and counts grams', (
      tester,
    ) async {
      await open(tester, _view(textLine('a', 'Salz')), []);

      expect(field(tester), isEmpty);
      expect(suffix(tester), 'g');
    });
  });

  group('− and +', () {
    testWidgets('step the field by 50', (tester) async {
      await open(tester, rice(amount: 170), []);

      await tapKey(tester, KochmodusAmountSheet.moreKey);
      expect(field(tester), '220');
      await tapKey(tester, KochmodusAmountSheet.fewerKey);
      await tapKey(tester, KochmodusAmountSheet.fewerKey);
      expect(field(tester), '120');
    });

    testWidgets('work on what was typed', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, rice(), results);

      await type(tester, '170');
      await tapKey(tester, KochmodusAmountSheet.moreKey);
      expect(field(tester), '220');
      await tapKey(tester, KochmodusAmountSheet.applyKey);

      expect(results, [(own: 220)]);
    });

    testWidgets('− stops at 0 and is off there', (tester) async {
      await open(tester, rice(amount: 70), []);

      await tapKey(tester, KochmodusAmountSheet.fewerKey);
      expect(field(tester), '20');
      await tapKey(tester, KochmodusAmountSheet.fewerKey);

      expect(field(tester), '0');
      expect(onPressed(tester, KochmodusAmountSheet.fewerKey), isNull);
    });

    testWidgets('+ from an empty field starts at one step', (tester) async {
      await open(tester, rice(), []);

      await type(tester, '');
      expect(onPressed(tester, KochmodusAmountSheet.fewerKey), isNull);
      await tapKey(tester, KochmodusAmountSheet.moreKey);

      expect(field(tester), '50');
    });

    testWidgets('+ never goes past the digits the field holds', (tester) async {
      await open(tester, rice(), []);

      await type(tester, '99990');
      await tapKey(tester, KochmodusAmountSheet.moreKey);

      expect(field(tester), '99999');
    });

    testWidgets('pieces step by one', (tester) async {
      await open(tester, _view(textLine('a', '2 Eier')), []);
      final start = int.parse(field(tester));

      await tapKey(tester, KochmodusAmountSheet.moreKey);

      expect(field(tester), '${start + 1}');
    });
  });

  group('"Übernehmen"', () {
    testWidgets('is off while the field is empty', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, rice(), results);
      expect(onPressed(tester, KochmodusAmountSheet.applyKey), isNotNull);

      await type(tester, '');
      expect(onPressed(tester, KochmodusAmountSheet.applyKey), isNull);

      await type(tester, '5');
      expect(onPressed(tester, KochmodusAmountSheet.applyKey), isNotNull);
      await tapKey(tester, KochmodusAmountSheet.applyKey);
      expect(results, [(own: 5)]);
    });

    testWidgets('closing the sheet returns nothing', (tester) async {
      final results = <KochmodusAmountChoice?>[];
      await open(tester, rice(), results);

      await type(tester, '170');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });

  group('the presets', () {
    testWidgets('"Vorhandenes" names everything the items still have', (
      tester,
    ) async {
      await open(tester, rice(), []);
      final l10n = sheetL10n(tester);

      expect(
        find.text(l10n.kochmodusAmountPresetAvailable('500 g')),
        findsOneWidget,
      );
      // The line already has the recipe amount, so "Rezept" would change
      // nothing.
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
    });

    testWidgets('each shows only while it would change the field', (
      tester,
    ) async {
      final line = rice(amount: 170);
      final recipe = line.parsed!.amount;
      await open(tester, line, []);

      expect(find.byKey(KochmodusAmountSheet.availableKey), findsOneWidget);
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsOneWidget);

      await type(tester, '500');
      expect(find.byKey(KochmodusAmountSheet.availableKey), findsNothing);
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsOneWidget);

      await type(tester, '$recipe');
      expect(find.byKey(KochmodusAmountSheet.availableKey), findsOneWidget);
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
    });

    testWidgets('a tap only fills the field, "Übernehmen" applies it', (
      tester,
    ) async {
      final line = rice(amount: 170);
      final results = <KochmodusAmountChoice?>[];
      await open(tester, line, results);

      await tapKey(tester, KochmodusAmountSheet.availableKey);

      expect(field(tester), '500');
      expect(results, isEmpty);
      expect(find.byKey(KochmodusAmountSheet.applyKey), findsOneWidget);

      await tapKey(tester, KochmodusAmountSheet.recipeKey);
      expect(field(tester), '${line.parsed!.amount}');
      expect(results, isEmpty);

      await tapKey(tester, KochmodusAmountSheet.applyKey);
      expect(results, [(own: null)]);
    });

    testWidgets('a preset fills an empty field and turns "Übernehmen" on', (
      tester,
    ) async {
      await open(tester, rice(), []);

      await type(tester, '');
      await tapKey(tester, KochmodusAmountSheet.availableKey);

      expect(field(tester), '500');
      expect(onPressed(tester, KochmodusAmountSheet.applyKey), isNotNull);
    });

    testWidgets('"Vorhandenes" is hidden when it equals the field', (
      tester,
    ) async {
      await open(tester, rice(stock: 300), []);

      expect(find.byKey(KochmodusAmountSheet.availableKey), findsNothing);
    });

    testWidgets('"Vorhandenes" is hidden when no item can supply the line', (
      tester,
    ) async {
      await open(tester, _view(textLine('a', '300 g Reis')), []);

      expect(find.byKey(KochmodusAmountSheet.availableKey), findsNothing);
      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
    });

    testWidgets('a line without amount has no "Rezept" and no recipe note', (
      tester,
    ) async {
      await open(
        tester,
        _view(
          textLine('a', 'Salz', settlement: assigned({'i1': 0})),
          items: [stockItem('i1', 80)],
        ),
        [],
      );

      expect(find.byKey(KochmodusAmountSheet.recipeKey), findsNothing);
      expect(find.byKey(KochmodusAmountSheet.availableKey), findsOneWidget);
      expect(
        find.textContaining(sheetL10n(tester).kochmodusAmountRecipe('', 4)),
        findsNothing,
      );
    });

    testWidgets('both presets name their amount in the unit of the line', (
      tester,
    ) async {
      final line = rice(amount: 170);
      await open(tester, line, []);
      final l10n = sheetL10n(tester);

      expect(
        find.text(l10n.kochmodusAmountPresetRecipe('${line.parsed!.amount} g')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.kochmodusAmountPresetAvailable('500 g')),
        findsOneWidget,
      );
    });
  });

  group('small phone, big text, open keyboard', () {
    for (final (name, locale) in [
      ('English', const Locale('en')),
      ('German', const Locale('de')),
    ]) {
      testWidgets('does not overflow at 320 px and text scale 1.3: $name', (
        tester,
      ) async {
        await open(
          tester,
          rice(amount: 170),
          [],
          width: 320,
          height: 640,
          textScale: 1.3,
          locale: locale,
        );
        await type(tester, '12345');

        expect(tester.takeException(), isNull);
      });

      testWidgets('keeps "Übernehmen" reachable with the keyboard: $name', (
        tester,
      ) async {
        final results = <KochmodusAmountChoice?>[];
        await open(
          tester,
          rice(amount: 170),
          results,
          width: 320,
          height: 568,
          keyboard: 300,
          textScale: 2,
          locale: locale,
        );
        await type(tester, '99999');

        await tester.ensureVisible(find.byKey(KochmodusAmountSheet.applyKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(KochmodusAmountSheet.applyKey));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(results, [(own: 99999)]);
      });
    }
  });

  testWidgets('the amount field carries the food of the line as its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, rice(), []);

    final node = tester.getSemantics(find.byKey(KochmodusAmountSheet.fieldKey));
    expect(node.label, 'Reis');
    expect(node.value, '300');
    expect(node.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });
}
