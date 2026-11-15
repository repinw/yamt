import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_line.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _weighedPot = CookMealDraft(
  potId: 'pot-a',
  name: 'Gemüsepfanne',
  count: 2,
  inPieces: false,
  grossWeight: 1500,
);

CookRunLine _flour() =>
    textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200}));

// "1 Zwiebel" on an item kept in grams: without a weight it takes nothing.
CookRunLine _onion({int? weighed, int take = 0}) => textLine(
  'l-onion',
  '1 Zwiebel',
  settlement: assigned({'onion': take}),
  weighed: weighed,
);

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  step: CookRunStep.portion,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  meals: const [_weighedPot],
  lines: lines,
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
    double width = 800,
    double? textScale,
  }) async {
    await harness.stock(
      tester,
      items ?? [stockItem('flour', 1000), stockItem('onion', 1000)],
    );
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id, width: width, textScale: textScale);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await harness.idle(tester);
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  Future<CookRun> stored(WidgetTester tester) =>
      harness.storedRun(tester, 'recipe-t1');

  String? blockText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(KochmodusPortionStep.blockKey)).data;

  Finder toStock() => find.byKey(KochmodusPortionStep.toStockKey);

  Future<void> typeWeight(WidgetTester tester, String grams) async {
    for (final digit in grams.split('')) {
      await tapVisible(tester, KochmodusWeighSheet.digitKey(int.parse(digit)));
    }
  }

  group('layout', () {
    testWidgets('fits 360 px with two pots, long names and large text', (
      tester,
    ) async {
      const pressureCooker = CookPot(
        id: 'pot-b',
        name: 'Schnellkochtopf',
        emptyWeight: 900,
        imageStoragePath: null,
      );
      await open(
        tester,
        buildCookRun(
          step: CookRunStep.portion,
          pots: CookPotsChosen(
            pots: const [
              CookPot(
                id: 'pot-a',
                name: 'Schnellkochtopf',
                emptyWeight: 800,
                imageStoragePath: null,
              ),
              pressureCooker,
            ],
            inCans: false,
          ),
          steps: const [],
          meals: const [_weighedPot],
          lines: [
            textLine(
              'l-flour',
              '200 g Mehl',
              settlement: assigned({'flour': 200}),
              potId: 'pot-a',
            ),
          ],
        ),
        items: [
          stockItem(
            'flour',
            1000,
          ).copyWith(name: 'Weizenmehl Typ 405 aus der großen Vorratspackung'),
        ],
        width: 360,
        textScale: 1.3,
      );

      final chip = find.byKey(KochmodusPortionLine.potKey('l-flour'));
      final text = find.text('200 g Mehl');
      expect(
        tester.getTopLeft(chip).dy,
        greaterThan(tester.getTopLeft(text).dy),
      );
      expect(tester.getTopLeft(chip).dx, tester.getTopLeft(text).dx);
      expect(
        tester.getTopRight(chip).dx,
        lessThanOrEqualTo(
          tester
              .getTopLeft(find.byKey(KochmodusPortionLine.editKey('l-flour')))
              .dx,
        ),
      );
    });
  });

  group('row title and subtitle', () {
    Future<void> openRows(
      WidgetTester tester,
      List<CookRunLine> lines, {
      List<InventoryItem>? items,
    }) => open(tester, _run([_flour(), ...lines]), items: items);

    testWidgets('an assigned row names the amount and the ingredient, '
        'the food below', (tester) async {
      await open(
        tester,
        _run([
          textLine(
            'l-milk',
            '300 ml Milch',
            settlement: assigned({'milk': 300}),
          ),
        ]),
        items: [stockItem('milk', 800, unit: InventoryAmountUnit.milliliter)],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.cookAmountOf('300 ml', 'Milch')), findsOneWidget);
      expect(find.text(l10n.kochmodusAssignItems('Item milk', 0)), findsOne);
    });

    testWidgets('a count with its measure word keeps the word in the title', (
      tester,
    ) async {
      await openRows(
        tester,
        [
          textLine(
            'l-garlic',
            '5 Zehen Knoblauch',
            settlement: assigned({'garlic': 15}),
          ),
        ],
        items: [
          stockItem('flour', 1000),
          stockItem('garlic', 100).copyWith(name: 'Knoblauch'),
        ],
      );
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.cookAmountOf('5 Zehen', 'Knoblauch')),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusPortionLine.editKey('l-garlic')), findsOne);
      expect(find.byKey(KochmodusPortionLine.removeKey('l-garlic')), findsOne);
    });

    testWidgets('a food that bears the name of the line has no second line', (
      tester,
    ) async {
      await openRows(
        tester,
        [
          textLine(
            'l-courgette',
            '375 g Zucchini',
            settlement: assigned({'courgette': 375}),
          ),
          textLine(
            'l-garlic',
            '5 Zehen Knoblauch',
            settlement: assigned({'garlic': 15}),
          ),
        ],
        items: [
          stockItem('flour', 1000),
          stockItem('courgette', 1000).copyWith(name: 'Zucchini'),
          stockItem('garlic', 100).copyWith(name: ' knoblauch '),
        ],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.cookAmountOf('375 g', 'Zucchini')), findsOne);
      expect(find.text(l10n.kochmodusAssignItems('Zucchini', 0)), findsNothing);
      expect(
        find.text(l10n.kochmodusAssignItems('knoblauch', 0)),
        findsNothing,
      );
    });

    testWidgets('a food with another name keeps its second line', (
      tester,
    ) async {
      await openRows(
        tester,
        [
          textLine(
            'l-courgette',
            '375 g Zucchini',
            settlement: assigned({'courgette': 375}),
          ),
        ],
        items: [
          stockItem('flour', 1000),
          stockItem('courgette', 1000).copyWith(name: 'Gemüsemix'),
        ],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.cookAmountOf('375 g', 'Zucchini')), findsOne);
      expect(find.text(l10n.kochmodusAssignItems('Gemüsemix', 0)), findsOne);
    });

    testWidgets('the weighed grams replace the need', (tester) async {
      await openRows(tester, [_onion(weighed: 80, take: 80)]);
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.cookAmountOf('80 g', 'Zwiebel')), findsOneWidget);
    });

    testWidgets('a rough need reads "≈"', (tester) async {
      await openRows(tester, [
        textLine(
          'l-butter',
          'Butter zum Braten',
          settlement: assigned({'flour': 20}),
          roughWeight: const CookRoughWeight(
            amount: 20,
            unit: TemplateIngredientUnit.gram,
          ),
        ),
      ]);
      final l10n = harness.l10n(tester);

      expect(
        find.text(
          l10n.cookAmountOf(l10n.eatPageApprox('20 g'), 'Butter zum Braten'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('several foods read "+ N weitere" under the first', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine(
            'l-rice',
            '300 g Reis',
            settlement: assigned({'rice': 100, 'rice2': 200}),
          ),
        ]),
        items: [stockItem('rice', 800), stockItem('rice2', 800)],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusAssignItems('Item rice', 1)), findsOne);
    });

    testWidgets('a missing weight joins the food and holds the button', (
      tester,
    ) async {
      await openRows(tester, [_onion()]);
      final l10n = harness.l10n(tester);

      expect(
        find.text(
          l10n.kochmodusJoined(
            l10n.kochmodusAssignItems('Item onion', 0),
            l10n.kochmodusWeightMissing,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a left-out, a not-counted and an open row say so', (
      tester,
    ) async {
      await openRows(tester, [
        textLine('l-skip', 'Basilikum', settlement: const LineIgnored()),
        textLine('l-salt', 'Salz', settlement: const LineIgnored()),
        cookedLine('l-open', '2 Eier'),
      ]);
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusRowIgnored), findsOneWidget);
      expect(find.text(l10n.kochmodusRowNotCounted), findsOneWidget);
      expect(find.text(l10n.kochmodusLineNotAssigned), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Basilikum')).style?.decoration,
        TextDecoration.lineThrough,
      );
      expect(
        tester.widget<Text>(find.text('Salz')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );
      expect(find.text('2 Eier'), findsWidgets);
    });
  });

  group('edit', () {
    testWidgets('on an assigned row opens the keypad and stores the weight', (
      tester,
    ) async {
      await open(tester, _run([_flour(), _onion()]));

      await tapVisible(tester, KochmodusPortionLine.editKey('l-onion'));
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsOneWidget);
      await typeWeight(tester, '80');
      await tapVisible(tester, KochmodusWeighSheet.confirmKey);

      final line = (await stored(tester)).lineOf('l-onion')!;
      expect(line.weighed, 80);
      // The item is kept in grams, so the take follows the weight.
      expect((line.settlement as LineAssigned).takes.single.amount, 80);
    });

    testWidgets('on a row that is not assigned starts the assign flow', (
      tester,
    ) async {
      // A line that came in while cooking: an open line of the recipe would
      // send the page back to "Zuweisen".
      await open(tester, _run([_flour(), cookedLine('l-open', '2 Eier')]));
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLine.editKey('l-open'));
      // Open, so it asks "Was hast du da?", not "Zutat ändern".
      expect(find.text(l10n.kochmodusAssignTitle), findsOneWidget);
      expect(find.text(l10n.kochmodusChangeTitle), findsNothing);

      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsOne,
      );
      // A shopping line would lock Kochen and Portion.
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.shop)),
        findsNothing,
      );
    });

    testWidgets('on a line that takes nothing from a whole pack assigns', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-senf', '1 EL Senf', settlement: assigned({'pack': 0})),
        ]),
        items: [stockItem('flour', 1000), packItem('pack', 2)],
      );

      await tapVisible(tester, KochmodusPortionLine.editKey('l-senf'));

      // Weighing would not help: another food is the way out.
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.shop)),
        findsNothing,
      );
    });

    testWidgets('on a line that takes nothing on pieces assigns too', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-rice', '200 g Reis', settlement: assigned({'egg': 0})),
        ]),
        items: [
          stockItem('flour', 1000),
          stockItem('egg', 3000, unit: InventoryAmountUnit.piece, scale: 1000),
        ],
      );

      await tapVisible(tester, KochmodusPortionLine.editKey('l-rice'));

      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
    });

    testWidgets('on a line without nutrition assigns', (tester) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-rice', '200 g Reis', settlement: assigned({'rice': 200})),
        ]),
        items: [
          stockItem('flour', 1000),
          stockItem('rice', 500, nutrition: null),
        ],
      );

      await tapVisible(tester, KochmodusPortionLine.editKey('l-rice'));

      // A weight cannot bring the nutrition in: another food is the way out.
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
    });

    testWidgets('on a line whose item is gone assigns', (tester) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-gone', '200 g Reis', settlement: assigned({'gone': 200})),
        ]),
      );

      await tapVisible(tester, KochmodusPortionLine.editKey('l-gone'));

      // A weight cannot bring the item back.
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsNothing);
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
    });

    testWidgets('a line weighed above its stock can pick another food', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine(
            'l-oil',
            '200 g Öl',
            settlement: assigned({'oil': 500}),
            weighed: 500,
          ),
        ]),
        items: [stockItem('flour', 1000), stockItem('oil', 300)],
      );

      await tapVisible(tester, KochmodusPortionLine.otherFoodKey('l-oil'));

      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.shop)),
        findsNothing,
      );
    });

    testWidgets('on a line weighed above its stock opens the keypad', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine(
            'l-oil',
            '200 g Öl',
            settlement: assigned({'oil': 500}),
            weighed: 500,
          ),
        ]),
        items: [stockItem('flour', 1000), stockItem('oil', 300)],
      );
      final l10n = harness.l10n(tester);

      expect(
        find.text(
          l10n.kochmodusOnlyAvailable(
            kochmodusItemAmountText(
              l10n,
              300,
              InventoryAmountUnit.gram,
              stockItem('oil', 300),
            ),
          ),
        ),
        findsOneWidget,
      );

      await tapVisible(tester, KochmodusPortionLine.editKey('l-oil'));

      // The pencil corrects the weight; "Ändern" picks another food.
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsOneWidget);
    });
  });

  group('a line on a whole pack that takes nothing', () {
    testWidgets('says it takes nothing and blocks with another food', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-senf', '1 EL Senf', settlement: assigned({'pack': 0})),
        ]),
        items: [stockItem('flour', 1000), packItem('pack', 2)],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTakesNothing), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(KochmodusPortionStep.toStockKey))
            .onPressed,
        isNull,
      );
      expect(blockText(tester), l10n.kochmodusBlockOtherFood('1 EL Senf'));
      expect(
        find.descendant(
          of: find.byKey(KochmodusPortionStep.toStockKey),
          matching: find.text(l10n.cookToStock),
        ),
        findsOneWidget,
      );
      expect(
        find.text(l10n.kochmodusBlockWithoutTake('1 EL Senf')),
        findsNothing,
      );
    });
  });

  group('remove', () {
    testWidgets('ignores a recipe line and keeps it below', (tester) async {
      await open(tester, _run([_onion(weighed: 80, take: 80), _flour()]));
      final weighedTitle = harness.l10n(tester).cookAmountOf('80 g', 'Zwiebel');
      expect(
        tester.getTopLeft(find.text(weighedTitle)).dy,
        lessThan(tester.getTopLeft(find.text('Mehl')).dy),
      );

      await tapVisible(tester, KochmodusPortionLine.removeKey('l-onion'));

      expect(
        (await stored(tester)).lineOf('l-onion')!.settlement,
        isA<LineIgnored>(),
      );
      // It stays, now below the line that goes into the pot, with a way
      // back instead of edit and remove.
      expect(find.text('1 Zwiebel'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('1 Zwiebel')).dy,
        greaterThan(tester.getTopLeft(find.text('Mehl')).dy),
      );
      expect(
        find.byKey(KochmodusPortionLine.restoreKey('l-onion')),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusPortionLine.editKey('l-onion')), findsNothing);
      expect(
        find.byKey(KochmodusPortionLine.removeKey('l-onion')),
        findsNothing,
      );
    });

    testWidgets('deletes a line that came in while cooking', (tester) async {
      await open(
        tester,
        _run([
          _flour(),
          cookedLine('new-1', 'Reis', settlement: assigned({'onion': 50})),
        ]),
      );
      expect(find.text('Reis'), findsOneWidget);

      await tapVisible(tester, KochmodusPortionLine.removeKey('new-1'));

      expect(find.text('Reis'), findsNothing);
      expect((await stored(tester)).lineOf('new-1'), isNull);
    });
  });

  group('undo of remove', () {
    Future<void> undo(WidgetTester tester) async {
      expect(find.byKey(KochmodusActionFlow.lineRemovedKey), findsOneWidget);
      await tester.tap(find.text(harness.l10n(tester).commonUndoAction));
      await harness.idle(tester);
    }

    testWidgets('names the removed line in the snack bar', (tester) async {
      await open(tester, _run([_onion(weighed: 80, take: 80), _flour()]));
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLine.removeKey('l-onion'));

      expect(
        find.descendant(
          of: find.byKey(KochmodusActionFlow.lineRemovedKey),
          matching: find.text(l10n.kochmodusLineRemoved('1 Zwiebel')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('brings a recipe line back with its takes and weight', (
      tester,
    ) async {
      await open(tester, _run([_onion(weighed: 80, take: 80), _flour()]));
      final before = (await stored(tester)).lineOf('l-onion')!;

      await tapVisible(tester, KochmodusPortionLine.removeKey('l-onion'));
      expect(
        (await stored(tester)).lineOf('l-onion')!.settlement,
        isA<LineIgnored>(),
      );
      await undo(tester);

      final line = (await stored(tester)).lineOf('l-onion')!;
      expect(line, before);
      expect(line.weighed, 80);
      expect((line.settlement as LineAssigned).takes.single.amount, 80);
      expect(
        find.byKey(KochmodusPortionLine.editKey('l-onion')),
        findsOneWidget,
      );
    });

    testWidgets('brings a line from cooking back as it was', (tester) async {
      // What the cook weighed is what the line takes, so undo refills it.
      final cooked = textLine(
        'new-1',
        'Reis',
        origin: CookLineOrigin.cooking,
        settlement: assigned({'extra': 50}),
        weighed: 50,
        addedItemIds: const ['extra'],
      );
      await open(
        tester,
        _run([_flour(), cooked, _onion()]),
        items: [
          stockItem('flour', 1000),
          stockItem('onion', 1000),
          stockItem('extra', 1000),
        ],
      );

      await tapVisible(tester, KochmodusPortionLine.removeKey('new-1'));
      final removed = await stored(tester);
      expect(removed.lineOf('new-1'), isNull);
      expect(removed.droppedItemIds, ['extra']);
      await undo(tester);

      final run = await stored(tester);
      expect(run.lines.map((line) => line.id), ['l-flour', 'new-1', 'l-onion']);
      expect(run.lineOf('new-1'), cooked);
      expect(run.droppedItemIds, isEmpty);
      expect(find.text('50 g Reis'), findsOneWidget);
    });
  });

  group('restore', () {
    testWidgets('opens the assign flow without offering to ignore', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-skip', 'Salz', settlement: const LineIgnored()),
        ]),
      );

      await tapVisible(tester, KochmodusPortionLine.restoreKey('l-skip'));

      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.have)),
        findsOne,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsNothing,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.shop)),
        findsNothing,
      );
    });

    testWidgets('is no undo: its tooltip says Zuordnen', (tester) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-skip', 'Salz', settlement: const LineIgnored()),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(
        tester
            .widget<IconButton>(
              find.byKey(KochmodusPortionLine.restoreKey('l-skip')),
            )
            .tooltip,
        l10n.cookAssign,
      );
      expect(find.byIcon(Icons.undo_rounded), findsNothing);
    });

    testWidgets('backing out of the picker leaves the line ignored', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour(),
          textLine('l-skip', 'Salz', settlement: const LineIgnored()),
        ]),
      );

      await tapVisible(tester, KochmodusPortionLine.restoreKey('l-skip'));
      await tapVisible(
        tester,
        KochmodusChangeSheet.answerKey(KochmodusChange.have),
      );
      await tester.pageBack();
      await harness.idle(tester);

      // Backing out of the picker changes nothing.
      expect(
        (await stored(tester)).lineOf('l-skip')!.settlement,
        isA<LineIgnored>(),
      );
    });
  });

  group('a line that takes nothing', () {
    testWidgets('weighed, but with nothing in stock, says so', (tester) async {
      await open(
        tester,
        _run([_flour(), _onion(weighed: 80)]),
        items: [stockItem('flour', 1000), stockItem('onion', 0)],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTakesNothing), findsOneWidget);
    });

    testWidgets('unweighed says the weight is missing instead', (tester) async {
      await open(tester, _run([_flour(), _onion()]));
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTakesNothing), findsNothing);
      expect(find.textContaining(l10n.kochmodusWeightMissing), findsOneWidget);
    });

    testWidgets('a weighed line that takes its weight does not say it', (
      tester,
    ) async {
      await open(tester, _run([_flour(), _onion(weighed: 80, take: 80)]));
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTakesNothing), findsNothing);
    });
  });

  group('In Vorrat', () {
    bool enabled(WidgetTester tester) =>
        tester.widget<FilledButton>(toStock()).onPressed != null;

    testWidgets('shows the block text of a line without take', (tester) async {
      await open(tester, _run([_flour(), _onion()]));
      final l10n = harness.l10n(tester);

      expect(enabled(tester), isFalse);
      expect(blockText(tester), l10n.kochmodusBlockWithoutTake('1 Zwiebel'));
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
    });

    testWidgets('goes through once the line is weighed', (tester) async {
      await open(tester, _run([_flour(), _onion()]));
      final l10n = harness.l10n(tester);

      await tapVisible(tester, KochmodusPortionLine.editKey('l-onion'));
      await typeWeight(tester, '80');
      await tapVisible(tester, KochmodusWeighSheet.confirmKey);

      expect(enabled(tester), isTrue);
      expect(
        find.descendant(of: toStock(), matching: find.text(l10n.cookToStock)),
        findsOneWidget,
      );
    });

    testWidgets('goes through once the line is removed', (tester) async {
      await open(tester, _run([_flour(), _onion()]));

      await tapVisible(tester, KochmodusPortionLine.removeKey('l-onion'));

      expect(enabled(tester), isTrue);
    });
  });
}
