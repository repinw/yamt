import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_done_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_estimates_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_line.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_lines.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _potA = 'pot-a';
const _potB = 'pot-b';

final InventoryItem _flour = stockItem('flour', 1000);
final InventoryItem _eggs = stockItem(
  'eggs',
  3000,
  unit: InventoryAmountUnit.piece,
  scale: 1000,
  servingQuantity: 60,
  servingQuantityUnit: 'g',
);
final InventoryItem _noNutrition = stockItem('plain', 500, nutrition: null);

CookPotChoice get _onePot =>
    CookPotsChosen(pots: const [cookPotA], inCans: false);

CookPotChoice get _twoPots =>
    CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: false);

CookRunLine _flourLine({String? potId}) => textLine(
  'l-flour',
  '200 g Mehl',
  settlement: assigned({'flour': 200}),
  potId: potId,
);

// The pot A weighed at 1200 g and named.
const _weighed = CookMealDraft(
  potId: _potA,
  name: 'Eintopf',
  count: 4,
  inPieces: false,
  grossWeight: 1200,
);

CookRun _run({
  List<CookRunLine>? lines,
  CookPotChoice? pots,
  List<CookMealDraft> meals = const [],
}) => buildCookRun(
  step: CookRunStep.portion,
  pots: pots ?? _onePot,
  steps: const [],
  meals: meals,
  lines: lines ?? [_flourLine()],
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    List<InventoryItem>? items,
  }) async {
    await harness.stock(tester, items ?? [_flour, _eggs, _noNutrition]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  Future<void> weighPot(WidgetTester tester, String potId, String grams) async {
    await tester.tap(find.byKey(KochmodusMealBox.weighKey(potId)));
    await harness.idle(tester);
    for (final digit in grams.split('')) {
      await tester.tap(
        find.byKey(KochmodusWeighSheet.digitKey(int.parse(digit))),
      );
      await tester.pump();
    }
    await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
    await harness.idle(tester);
  }

  String? blockText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(KochmodusPortionStep.blockKey)).data;

  Finder toStock() => find.byKey(KochmodusPortionStep.toStockKey);

  bool enabled(WidgetTester tester) =>
      tester.widget<FilledButton>(toStock()).onPressed != null;

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await harness.idle(tester);
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  group('Topfgewicht', () {
    testWidgets('is required: In Vorrat waits and says why', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      // The main button weighs the pot; it is no "In den Vorrat legen" yet.
      expect(
        find.descendant(
          of: toStock(),
          matching: find.text(l10n.kochmodusWeighPotsAction(1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsNothing,
      );
      expect(find.text(l10n.kochmodusPotGross('Topf')), findsOneWidget);
      expect(find.text(l10n.kochmodusPotWeighHint), findsOneWidget);
    });

    testWidgets('weighing the pot stores it and lets In Vorrat go', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusMealBox.weighKey(_potA)));
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusPotWeighSub(900)), findsOneWidget);
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(1)));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(2)));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(0)));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(0)));
      await tester.pump();
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(find.text(l10n.cookAmountGrams('1200')), findsWidgets);
      expect(find.text(l10n.cookNetWeight(300)), findsOneWidget);
      expect(enabled(tester), isTrue);
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
      final meal = (await harness.storedRun(tester, 'recipe-t1')).meals.single;
      expect(meal.potId, _potA);
      expect(meal.grossWeight, 1200);
      expect(meal.count, 4);
    });

    testWidgets('a weight at or below the empty pot is refused', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await weighPot(tester, _potA, '800');

      expect(find.text(l10n.cookWeightTooLow(900)), findsOneWidget);
      expect(find.text(l10n.cookNetWeight(300)), findsNothing);
      expect(
        find.descendant(
          of: toStock(),
          matching: find.text(l10n.kochmodusWeighPotsAction(1)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('every pot is weighed, the text counts them', (tester) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          lines: [
            _flourLine(potId: _potA),
            textLine(
              'l-eggs',
              'Eier',
              settlement: assigned({'eggs': 2000}),
              potId: _potB,
            ),
          ],
        ),
      );
      final l10n = harness.l10n(tester);
      expect(
        find.descendant(
          of: toStock(),
          matching: find.text(l10n.kochmodusWeighPotsAction(2)),
        ),
        findsOneWidget,
      );

      await weighPot(tester, _potA, '1200');
      expect(
        find.descendant(
          of: toStock(),
          matching: find.text(l10n.kochmodusWeighPotsAction(1)),
        ),
        findsOneWidget,
      );
      await weighPot(tester, _potB, '1000');

      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
      expect(enabled(tester), isTrue);
    });
  });

  group('the main button weighs the pot', () {
    String? buttonText(WidgetTester tester) => tester
        .widgetList<Text>(
          find.descendant(of: toStock(), matching: find.byType(Text)),
        )
        .single
        .data;

    testWidgets('says "Topf wiegen" and opens the weighing of that pot', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      expect(enabled(tester), isTrue);
      expect(buttonText(tester), l10n.kochmodusWeighPotsAction(1));
      expect(buttonText(tester), isNot(l10n.cookToStock));

      await tester.tap(toStock());
      await harness.idle(tester);

      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsOneWidget);
      expect(find.text(l10n.kochmodusPotWeighSub(900)), findsOneWidget);
    });

    testWidgets('after weighing it says "In den Vorrat legen"', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);
      for (final digit in [1, 2, 0, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(buttonText(tester), l10n.cookToStock);
      final meal = (await harness.storedRun(tester, 'recipe-t1')).meals.single;
      expect(meal.grossWeight, 1200);
    });

    testWidgets('with two pots the label counts them and the first one '
        'is weighed first', (tester) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          lines: [
            _flourLine(potId: _potA),
            textLine(
              'l-eggs',
              'Eier',
              settlement: assigned({'eggs': 2000}),
              potId: _potB,
            ),
          ],
        ),
      );
      final l10n = harness.l10n(tester);
      expect(buttonText(tester), l10n.kochmodusWeighPotsAction(2));

      await tester.tap(toStock());
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusPotWeighSub(900)), findsOneWidget);
      for (final digit in [1, 2, 0, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      // The second pot is next, with the label for one.
      expect(buttonText(tester), l10n.kochmodusWeighPotsAction(1));
      await tester.tap(toStock());
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusPotWeighSub(600)), findsOneWidget);
    });

    testWidgets('a pot weighed at or below its empty weight keeps "Topf '
        'wiegen"', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await weighPot(tester, _potA, '900');

      expect(buttonText(tester), l10n.kochmodusWeighPotsAction(1));
      expect(enabled(tester), isTrue);
    });

    testWidgets('is off while the view is busy', (tester) async {
      final run = _run();
      final view = buildKochmodusView(
        run: run,
        saved: true,
        ended: false,
        busy: true,
        reopened: false,
        finished: null,
        tab: null,
        items: [_flour],
        otherReservations: const {},
        utensils: const [],
        parser: const TemplateIngredientParser(),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(),
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: KochmodusPortionStep(
                target: KochmodusTarget.run(run.id),
                view: view,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(view.portion.potToWeigh, isNotNull);
      expect(enabled(tester), isFalse);
    });
  });

  group('Sperrgrund', () {
    // The reason is a readable line above the button, which keeps its label
    // and waits.
    void buttonWaits(WidgetTester tester, AppLocalizations l10n) {
      expect(enabled(tester), isFalse);
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
    }

    testWidgets('names the item that holds too little', (tester) async {
      final short = stockItem('short', 500);
      await open(
        tester,
        _run(
          lines: [
            textLine('l-flour', 'Mehl', settlement: assigned({'short': 600})),
          ],
        ),
        items: [short],
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);
      final left = kochmodusItemAmountText(
        l10n,
        500,
        InventoryAmountUnit.gram,
        short,
      );

      expect(enabled(tester), isFalse);
      expect(blockText(tester), l10n.kochmodusBlockShort('Mehl', left));
      expect(find.text(l10n.kochmodusOnlyAvailable(left)), findsOneWidget);
    });

    testWidgets('names an item that is gone', (tester) async {
      await open(
        tester,
        _run(
          lines: [
            textLine('l-flour', 'Mehl', settlement: assigned({'ghost': 100})),
          ],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(blockText(tester), l10n.kochmodusBlockEntryMissing('Mehl'));
      expect(find.text(l10n.kochmodusEntryMissing), findsOneWidget);
    });

    testWidgets('names an item without nutrition', (tester) async {
      await open(
        tester,
        _run(
          lines: [
            textLine('l-flour', 'Mehl', settlement: assigned({'plain': 100})),
          ],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(blockText(tester), l10n.kochmodusBlockNutritionMissing('Mehl'));
      expect(find.text(l10n.kochmodusNutritionMissing), findsOneWidget);
    });

    testWidgets('names a pot without ingredients', (tester) async {
      await open(
        tester,
        _run(
          lines: [textLine('l-salt', 'Salz', settlement: const LineIgnored())],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(blockText(tester), l10n.kochmodusBlockPotEmpty);
    });

    testWidgets('names the pot without ingredients when there are two', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          meals: const [_weighed],
          lines: [_flourLine(potId: _potA)],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(
        blockText(tester),
        l10n.kochmodusBlockPotEmptyNamed(l10n.kochmodusPotNumbered(2)),
      );
      expect(find.text(l10n.kochmodusBlockPotEmpty), findsNothing);
    });

    testWidgets('names a named pot by its name', (tester) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          meals: const [_weighed],
          lines: [_flourLine(potId: _potB)],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(blockText(tester), l10n.kochmodusBlockPotEmptyNamed('Topf'));
    });

    testWidgets('asks to settle the new lines first', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [_flourLine(), cookedLine('new-1', 'Reis')],
        ),
      );
      final l10n = harness.l10n(tester);
      buttonWaits(tester, l10n);

      expect(enabled(tester), isFalse);
      expect(blockText(tester), l10n.kochmodusBlockLinesOpen);
      expect(find.text(l10n.kochmodusLineNotAssigned), findsOneWidget);
    });
  });

  group('the reason why the meal waits', () {
    testWidgets('counting without a pot and no food says so', (tester) async {
      await open(
        tester,
        _run(
          pots: const CookCounted(),
          lines: [textLine('l-salt', 'Salz', settlement: const LineIgnored())],
        ),
      );
      final l10n = harness.l10n(tester);

      expect(blockText(tester), l10n.kochmodusBlockNoFood);
      expect(blockText(tester), isNot(l10n.kochmodusBlockPotEmpty));
      expect(enabled(tester), isFalse);
    });

    testWidgets('an unweighed pot keeps the active "Topf wiegen" and shows no '
        'reason line', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusPortionStep.blockKey), findsNothing);
      expect(enabled(tester), isTrue);
      expect(
        find.descendant(
          of: toStock(),
          matching: find.text(l10n.kochmodusWeighPotsAction(1)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('stands above the button, which keeps "In den Vorrat legen" '
        'and waits', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [_flourLine(), cookedLine('new-1', 'Reis')],
        ),
      );
      final l10n = harness.l10n(tester);

      expect(
        tester.getBottomLeft(find.byKey(KochmodusPortionStep.blockKey)).dy,
        lessThanOrEqualTo(tester.getTopLeft(toStock()).dy),
      );
      expect(blockText(tester), l10n.kochmodusBlockLinesOpen);
      expect(enabled(tester), isFalse);
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
    });
  });

  group('two pots with a renamed meal', () {
    testWidgets('the label shows the new name, not the default one', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          meals: const [
            _weighed,
            CookMealDraft(
              potId: _potB,
              name: 'Suppe',
              count: 2,
              inPieces: false,
              grossWeight: 1000,
            ),
          ],
          lines: [
            _flourLine(potId: _potA),
            textLine(
              'l-eggs',
              'Eier',
              settlement: assigned({'eggs': 2000}),
              potId: _potB,
            ),
          ],
        ),
      );

      // The title above each label is a Text; the name field holds the same
      // words, so only plain Texts are counted.
      Finder title(String name) =>
          find.byWidgetPredicate((w) => w is Text && w.data == name);
      expect(title('Suppe'), findsOneWidget);
    });
  });

  group('Topf mit Essen', () {
    testWidgets('is optional for a meal in pieces', (tester) async {
      await open(
        tester,
        _run(
          meals: const [
            CookMealDraft(
              potId: _potA,
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: null,
            ),
          ],
        ),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusPotGrossOptional('Topf')), findsOneWidget);
      expect(find.text(l10n.kochmodusPotGross('Topf')), findsNothing);
      // It never waits for the weight, so nothing says "Topf wiegen".
      expect(find.byKey(KochmodusPortionStep.blockKey), findsNothing);
      expect(enabled(tester), isTrue);
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
    });

    testWidgets('is required for a meal by weight', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusPotGross('Topf')), findsOneWidget);
      expect(find.text(l10n.kochmodusPotGrossOptional('Topf')), findsNothing);
    });
  });

  group('Topf-Chip', () {
    testWidgets('only shows with two pots and moves the line to the next', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          lines: [
            _flourLine(potId: _potA),
            textLine(
              'l-eggs',
              'Eier',
              settlement: assigned({'eggs': 2000}),
              potId: _potB,
            ),
          ],
        ),
      );
      final l10n = harness.l10n(tester);
      Finder chip(String lineId) =>
          find.byKey(KochmodusPortionLine.potKey(lineId));
      String chipText(String lineId) => tester
          .widget<Text>(
            find.descendant(of: chip(lineId), matching: find.byType(Text)),
          )
          .data!;

      expect(chipText('l-flour'), 'Topf');
      expect(chipText('l-eggs'), l10n.kochmodusPotNumbered(2));
      expect(
        find.text(l10n.kochmodusPortionLinesSwitch.toUpperCase()),
        findsOneWidget,
      );

      await tester.tap(chip('l-eggs'));
      await harness.idle(tester);

      expect(chipText('l-eggs'), 'Topf');
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-eggs')!.potId, _potA);
      expect(stored.lineOf('l-flour')!.potId, _potA);

      // The next tap goes round to the second pot again.
      await tester.tap(chip('l-eggs'));
      await harness.idle(tester);
      expect(chipText('l-eggs'), l10n.kochmodusPotNumbered(2));
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).lineOf('l-eggs')!.potId,
        _potB,
      );
    });

    testWidgets('one pot shows no chip', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusPortionLine.potKey('l-flour')), findsNothing);
      expect(find.text(l10n.cookIngredients.toUpperCase()), findsOneWidget);
    });
  });

  group('Mahlzeit', () {
    testWidgets('the name is stored when the cook is done typing', (
      tester,
    ) async {
      await open(tester, _run(meals: const [_weighed]));

      await tester.enterText(
        find.byKey(KochmodusMealBox.nameKey(_potA)),
        'Gulasch',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await harness.idle(tester);

      final meal = (await harness.storedRun(tester, 'recipe-t1')).meals.single;
      expect(meal.name, 'Gulasch');
      expect(meal.grossWeight, 1200);
    });

    testWidgets('+ adds a portion and Stück switches to pieces', (
      tester,
    ) async {
      await open(tester, _run(meals: const [_weighed]));

      await tester.tap(find.byKey(KochmodusMealBox.moreKey(_potA)));
      await harness.idle(tester);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).meals.single.count,
        5,
      );

      await tester.tap(find.byKey(KochmodusMealBox.piecesKey(_potA)));
      await harness.idle(tester);
      final meal = (await harness.storedRun(tester, 'recipe-t1')).meals.single;
      expect(meal.inPieces, isTrue);
      expect(meal.count, 5);
    });
  });

  group('Übernehmen', () {
    testWidgets('a new line can be ignored from the sheet', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [_flourLine(), cookedLine('new-1', 'Reis')],
        ),
      );
      final l10n = harness.l10n(tester);
      expect(find.text(l10n.kochmodusNewLines(1)), findsOneWidget);

      await tapVisible(tester, KochmodusPortionLines.takeNewKey);
      await tapVisible(
        tester,
        KochmodusChangeSheet.answerKey(KochmodusChange.ignore),
      );

      expect(find.text(l10n.kochmodusNewLines(1)), findsNothing);
      expect(enabled(tester), isTrue);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('new-1')!.settlement, isA<LineIgnored>());
    });

    testWidgets('backing out of the first sheet opens no second one', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [
            _flourLine(),
            cookedLine('new-1', 'Reis'),
            cookedLine('new-2', 'Salz'),
            cookedLine('new-3', 'Pfeffer'),
          ],
        ),
      );
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLines.takeNewKey);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsOne,
      );
      harness.router.routerDelegate.navigatorKey.currentState!.pop();
      await harness.idle(tester);

      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsNothing,
      );
      expect(find.text(l10n.kochmodusNewLines(3)), findsOneWidget);
    });

    testWidgets('settling one new line offers the next, each once', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [
            _flourLine(),
            cookedLine('new-1', 'Reis'),
            cookedLine('new-2', 'Salz'),
          ],
        ),
      );
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLines.takeNewKey);
      await tapVisible(
        tester,
        KochmodusChangeSheet.answerKey(KochmodusChange.ignore),
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsOne,
      );
      await tapVisible(
        tester,
        KochmodusChangeSheet.answerKey(KochmodusChange.ignore),
      );

      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsNothing,
      );
      expect(find.text(l10n.kochmodusNewLines(1)), findsNothing);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('new-1')!.settlement, isA<LineIgnored>());
      expect(stored.lineOf('new-2')!.settlement, isA<LineIgnored>());
    });

    testWidgets('a new line can take from the Vorrat', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [_flourLine(), cookedLine('new-1', 'Reis')],
        ),
        items: [
          _flour,
          stockItem('rice', 800).copyWith(name: 'Reis'),
        ],
      );
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLines.takeNewKey);
      await tapVisible(
        tester,
        KochmodusChangeSheet.answerKey(KochmodusChange.have),
      );
      // The Vorrat food of that name is taken once the cook taps its row.
      expect(find.text(l10n.kochmodusNewLines(1)), findsOneWidget);
      await tapVisible(tester, KochmodusItemPickerSheet.rowKey('rice'));

      expect(find.text(l10n.kochmodusNewLines(1)), findsNothing);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('new-1')!.settlement, isA<LineAssigned>());
      expect(enabled(tester), isTrue);
    });
  });

  group('the count question', () {
    testWidgets('asks for portions in a pot', (tester) async {
      await open(tester, _run(meals: const [_weighed]));
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusMealCountQuestion('portion')),
        findsOneWidget,
      );
      expect(find.text(l10n.cookPortionTitle), findsOneWidget);
    });

    testWidgets('asks for pieces when the meal is served in pieces', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          meals: const [
            CookMealDraft(
              potId: _potA,
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: 1200,
            ),
          ],
        ),
      );
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusMealCountQuestion('piece')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.kochmodusMealCountQuestion('portion')),
        findsNothing,
      );
    });

    testWidgets('asks for cans when the meals go into cans', (tester) async {
      await open(
        tester,
        _run(
          pots: CookPotsChosen(pots: const [cookPotA], inCans: true),
          meals: const [_weighed],
        ),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusMealCountQuestion('can')), findsOneWidget);
    });
  });

  group('Schätzungen prüfen', () {
    CookRun estimatedRun() => _run(
      meals: const [_weighed],
      lines: [
        _flourLine(),
        textLine('l-eggs', 'Eier', settlement: assigned({'eggs': 2000})),
      ],
    );

    testWidgets('counts the estimated lines and In Vorrat stays possible', (
      tester,
    ) async {
      await open(tester, estimatedRun());
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusEstimatedIngredients(1)), findsOneWidget);
      expect(find.text(l10n.kochmodusReview), findsOneWidget);
      expect(find.byKey(KochmodusPortionStep.reviewKey), findsOneWidget);
      expect(enabled(tester), isTrue);
    });

    testWidgets('no estimate, no Prüfen', (tester) async {
      await open(tester, _run(meals: const [_weighed]));

      expect(find.byKey(KochmodusPortionStep.reviewKey), findsNothing);
    });

    testWidgets('changing an estimate weighs it and the line leaves', (
      tester,
    ) async {
      await open(tester, estimatedRun());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusPortionStep.reviewKey));
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusEstimateRow(120)), findsOneWidget);
      expect(find.text(l10n.kochmodusEstimatesNote), findsOneWidget);

      await tester.tap(find.byKey(KochmodusEstimatesSheet.changeKey('l-eggs')));
      await harness.idle(tester);
      expect(
        find.text(l10n.kochmodusEstimateKicker.toUpperCase()),
        findsOneWidget,
      );
      await tester.tap(find.byKey(KochmodusWeighSheet.hintKey));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(5)));
      await tester.pump();
      expect(find.text(l10n.kochmodusEstimateConfirm(1205)), findsOneWidget);
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      // The last estimate is weighed: the sheet closes itself, the page
      // underneath stays.
      expect(find.byKey(KochmodusEstimatesSheet.doneKey), findsNothing);
      expect(
        find.byKey(KochmodusEstimatesSheet.changeKey('l-eggs')),
        findsNothing,
      );
      expect(find.byKey(KochmodusPortionStep.reviewKey), findsNothing);
      expect(find.byKey(KochmodusPortionStep.toStockKey), findsOneWidget);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-eggs')!.weighed, 1205);
    });

    testWidgets('weighing one of two estimates leaves the sheet open', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [
            _flourLine(),
            textLine('l-eggs', 'Eier', settlement: assigned({'eggs': 2000})),
            textLine('l-eggs2', 'Eier', settlement: assigned({'eggs': 2000})),
          ],
        ),
      );

      await tester.tap(find.byKey(KochmodusPortionStep.reviewKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusEstimatesSheet.changeKey('l-eggs')));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusWeighSheet.hintKey));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(5)));
      await tester.pump();
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusEstimatesSheet.doneKey), findsOneWidget);
      expect(
        find.byKey(KochmodusEstimatesSheet.changeKey('l-eggs')),
        findsNothing,
      );
      expect(
        find.byKey(KochmodusEstimatesSheet.changeKey('l-eggs2')),
        findsOneWidget,
      );
    });

    testWidgets('Passt so closes the sheet and keeps the estimate', (
      tester,
    ) async {
      await open(tester, estimatedRun());

      await tester.tap(find.byKey(KochmodusPortionStep.reviewKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusEstimatesSheet.doneKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusEstimatesSheet.doneKey), findsNothing);
      expect(find.byKey(KochmodusPortionStep.reviewKey), findsOneWidget);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-eggs')!.weighed, isNull);
    });
  });

  group('the estimates sheet of lines that take nothing', () {
    final carrot = stockItem('carrot', 500).copyWith(name: 'Möhre');

    // "1 Möhre" has no weight: it takes nothing until it is weighed.
    CookRunLine noWeight() =>
        textLine('l-carrot', '1 Möhre', settlement: assigned({'carrot': 0}));

    Future<void> review(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(KochmodusPortionStep.reviewKey));
      await tester.tap(find.byKey(KochmodusPortionStep.reviewKey));
      await harness.idle(tester);
    }

    testWidgets('only such lines: the row and the sheet read "Noch zu '
        'wiegen" and the note says they are still to weigh', (tester) async {
      await open(
        tester,
        _run(meals: const [_weighed], lines: [_flourLine(), noWeight()]),
        items: [_flour, carrot],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusToWeigh), findsOneWidget);
      expect(find.textContaining('Bei '), findsNothing);
      expect(find.text(l10n.kochmodusEstimatedIngredients(1)), findsNothing);

      await review(tester);

      expect(find.text(l10n.kochmodusToWeigh), findsNWidgets(2));
      expect(find.text(l10n.kochmodusToWeighNote), findsOneWidget);
      expect(find.text(l10n.kochmodusEstimatesMustWeigh), findsNothing);
      expect(find.text(l10n.kochmodusEstimatesNote), findsNothing);
    });

    testWidgets('with a real estimate beside it the count is the estimates '
        'only', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [
            _flourLine(),
            noWeight(),
            textLine('l-eggs', 'Eier', settlement: assigned({'eggs': 2000})),
          ],
        ),
        items: [_flour, _eggs, carrot],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusEstimatedIngredients(1)), findsOneWidget);
      expect(find.text(l10n.kochmodusToWeigh), findsNothing);

      await review(tester);

      expect(find.text(l10n.kochmodusEstimatesMustWeigh), findsOneWidget);
      expect(
        find.text(l10n.kochmodusEstimatedIngredients(1)),
        findsNWidgets(2),
      );
    });

    testWidgets('a line whose food left the Vorrat is no estimate and not in '
        'the sheet', (tester) async {
      await open(
        tester,
        _run(
          meals: const [_weighed],
          lines: [
            textLine('l-gone', 'Reis', settlement: assigned({'ghost': 100})),
          ],
        ),
      );

      expect(find.byKey(KochmodusPortionStep.reviewKey), findsNothing);
    });
  });

  group('Ins Kochbuch', () {
    testWidgets('a recipe has no such switch', (tester) async {
      await open(tester, _run(meals: const [_weighed]));

      expect(find.byKey(KochmodusPortionStep.cookbookKey), findsNothing);
    });

    testWidgets('free cooking can keep the meal as a recipe', (tester) async {
      await open(
        tester,
        freeRun([
          _flourLine(),
        ], pots: _onePot).copyWith(step: CookRunStep.portion),
      );

      await tester.ensureVisible(find.byKey(KochmodusPortionStep.cookbookKey));
      await harness.idle(tester);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(KochmodusPortionStep.cookbookKey),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(KochmodusPortionStep.cookbookKey));
      await harness.idle(tester);

      expect((await harness.storedRun(tester, 'recipe-t1')).toCookbook, isTrue);
    });
  });

  group('In Vorrat und Fertig', () {
    testWidgets('puts the meal into the Vorrat and shows Fertig', (
      tester,
    ) async {
      await open(tester, _run(meals: const [_weighed]));
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);

      expect(find.byType(KochmodusDoneView), findsOneWidget);
      expect(find.text(l10n.kochmodusDoneTitle), findsOneWidget);
      expect(
        find.text(l10n.kochmodusDonePortions(4, 'Eintopf')),
        findsOneWidget,
      );
      expect(toStock(), findsNothing);
      expect(await tester.runAsync(() => harness.cook.mealCount()), 1);
      expect(
        (await tester.runAsync(() => harness.cook.storedItem('flour')))!
            .currentAmount,
        800,
      );
      expect(
        await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
        isNull,
      );
    });

    testWidgets('Fertig says each meal in its own unit', (tester) async {
      await open(
        tester,
        _run(
          pots: _twoPots,
          lines: [
            _flourLine(potId: _potA),
            textLine(
              'l-flour-b',
              'Mehl',
              settlement: assigned({'flour': 100}),
              potId: _potB,
            ),
          ],
          meals: const [
            _weighed,
            CookMealDraft(
              potId: _potB,
              name: 'Kekse',
              count: 12,
              inPieces: true,
              grossWeight: 1500,
            ),
          ],
        ).copyWith(),
      );
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);

      expect(
        find.text(l10n.kochmodusDonePortions(4, 'Eintopf')),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusDonePieces(12, 'Kekse')), findsOneWidget);
    });

    testWidgets('Fertig counts cans when the meals go into cans', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          pots: CookPotsChosen(pots: const [cookPotA], inCans: true),
          meals: const [_weighed],
        ),
      );
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);

      expect(find.text(l10n.kochmodusDoneCans(4, 'Eintopf')), findsOneWidget);
      expect(find.text(l10n.kochmodusDonePortions(4, 'Eintopf')), findsNothing);
    });

    testWidgets('Jetzt essen opens the first meal in the Vorrat', (
      tester,
    ) async {
      await open(tester, _run(meals: const [_weighed]));
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);
      expect(find.text(l10n.kochmodusDoneEat), findsOneWidget);
      await tester.tap(find.byKey(KochmodusDoneView.eatKey));
      await harness.idle(tester);

      expect(find.byType(KochmodusDoneView), findsNothing);
      expect(find.byKey(inventoryKey), findsOneWidget);
      expect(harness.inventoryUri!.path, AppRoutes.homeInventory);
      final mealId = harness
          .inventoryUri!
          .queryParameters[AppRoutes.homeInventoryMealParam]!;
      expect(mealId, endsWith(_potA));
      expect(
        await tester.runAsync(() => harness.cook.storedMeal(mealId)),
        isNotNull,
      );
    });

    testWidgets('Zum Kochbuch leaves the page', (tester) async {
      await open(tester, _run(meals: const [_weighed]));

      await tester.tap(toStock());
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusDoneView.cookbookKey));
      await harness.idle(tester);

      expect(find.byType(KochmodusDoneView), findsNothing);
      expect(find.byKey(homeKey), findsOneWidget);
    });

    testWidgets('free cooking with Ins Kochbuch says so in Fertig', (
      tester,
    ) async {
      final run = freeRun([_flourLine()], pots: _onePot).copyWith(
        step: CookRunStep.portion,
        toCookbook: true,
        meals: [
          const CookMealDraft(
            potId: _potA,
            name: 'Mehlspeise',
            count: 2,
            inPieces: false,
            grossWeight: 1200,
          ),
        ],
      );
      await open(tester, run);
      final l10n = harness.l10n(tester);

      await tester.tap(toStock());
      await harness.idle(tester);

      expect(
        find.text(l10n.kochmodusDonePortions(2, 'Mehlspeise')),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusDoneInCookbook), findsOneWidget);
    });

    testWidgets('a counted meal goes in with its defaults', (tester) async {
      await open(tester, _run(pots: const CookCounted()));
      final l10n = harness.l10n(tester);

      // No pot to weigh, so nothing waits.
      expect(
        find.byKey(KochmodusMealBox.weighKey(countedMealPotId)),
        findsNothing,
      );
      expect(enabled(tester), isTrue);
      await tester.tap(toStock());
      await harness.idle(tester);

      expect(find.byType(KochmodusDoneView), findsOneWidget);
      expect(find.text(l10n.kochmodusDoneTitle), findsOneWidget);
      expect(await tester.runAsync(() => harness.cook.mealCount()), 1);
    });
  });
}
