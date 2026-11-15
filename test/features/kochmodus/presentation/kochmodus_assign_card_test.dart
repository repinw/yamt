import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

const _runId = 'recipe-t1';
const _pickKey = Key('pick-food');

CookRun _run(List<CookRunLine> lines, {List<String>? steps}) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: steps ?? const [],
  lines: lines,
);

InventoryItem _named(String id, String name, int amount) =>
    stockItem(id, amount).copyWith(name: name);

// The confirmation line keeps amounts and units together with no-break
// spaces.
String _held(String amount) => amount.replaceAll(' ', '\u00A0');

void main() {
  late KochmodusCookingHarness harness;

  // What the food pick route answers with.
  RecipeFoodPick Function()? answer;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    answer = null;
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    List<InventoryItem> items = const [],
  }) async {
    await harness.stock(tester, items);
    await harness.store(tester, run);
    await openPage(
      tester,
      harness,
      const KochmodusAssignPage(recipeId: 't1'),
      routes: [
        GoRoute(
          path: AppRoutes.homeCookRun,
          builder: (context, state) =>
              KochmodusPage.run(runId: state.pathParameters['runId']!),
        ),
        GoRoute(
          path: AppRoutes.homeFoodPick,
          builder: (context, state) => Scaffold(
            body: TextButton(
              key: _pickKey,
              onPressed: () => context.pop<RecipeFoodPick>(answer!()),
              child: const Text('pick'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  Future<CookRun> stored(WidgetTester tester) =>
      harness.storedRun(tester, _runId);

  CookRunLine lineOf(CookRun run, String id) =>
      run.lines.singleWhere((line) => line.id == id);

  Finder onCard(String text) => find.descendant(
    of: find.byKey(KochmodusAssignStep.cardKey),
    matching: find.text(text),
  );

  Finder badge(String lineId, IconData icon) => find.descendant(
    of: find.byKey(KochmodusIngredientRow.rowKey(lineId)),
    matching: find.byIcon(icon),
  );

  RecipeFoodNew newFood(InventoryItem item, {required int amount}) =>
      RecipeFoodNew((
        result: InventoryReceiptManualProductResult(
          item: item,
          action: InventoryReceiptManualProductAction.addToInventory,
          requiresGlobalPersistence: false,
          skipMissingBarcodePrompt: true,
        ),
        request: InventoryItemEatRequest(
          inventoryAmount: amount,
          loggedAt: DateTime(2026, 11, 12),
          mealType: MealType.lunch,
        ),
      ));

  group('the card and the answers', () {
    testWidgets('the first unanswered ingredient is on the card', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
      );

      expect(onCard('Hack'), findsOneWidget);
      expect(onCard('Milch'), findsNothing);
      expect(find.byKey(KochmodusIngredientRow.rowKey('a')), findsOne);
      expect(find.byKey(KochmodusIngredientRow.rowKey('b')), findsOne);
    });

    testWidgets('"Hab ich" with one name match opens the picker and takes '
        'nothing until its row is tapped', (tester) async {
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', 'Milch')]),
        items: [_named('mince', 'Hack', 1000), _named('x', 'Nudeln', 800)],
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      // Not by itself: the picker asks, the line is still open.
      expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsOne);
      expect(find.byKey(KochmodusItemPickerSheet.allKey), findsOne);
      expect(find.byKey(_pickKey), findsNothing);
      expect(lineOf(await stored(tester), 'a').settlement, isA<LineOpen>());
      expect(onCard('Hack'), findsOneWidget);

      await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));

      final line = lineOf(await stored(tester), 'a');
      final takes = (line.settlement as LineAssigned).takes;
      expect(takes.map((take) => take.itemId), ['mince']);
      expect(takes.single.amount, 300);
      expect(onCard('Milch'), findsOneWidget);
      expect(badge('a', Icons.check_rounded), findsOneWidget);
      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
      expect(find.byKey(_pickKey), findsNothing);
    });

    testWidgets('"Hab ich" with a Vorrat of only other foods opens the '
        'picker, not the search, without a group title', (tester) async {
      await open(
        tester,
        _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
        items: [_named('x', 'Nudeln', 800)],
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(find.byKey(KochmodusItemPickerSheet.rowKey('x')), findsOne);
      expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsNothing);
      expect(find.byKey(KochmodusItemPickerSheet.allKey), findsNothing);
      expect(find.byKey(_pickKey), findsNothing);
      expect(lineOf(await stored(tester), 'a').settlement, isA<LineOpen>());
    });

    testWidgets('"Hab ich" with an empty Vorrat opens the search', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(find.byKey(_pickKey), findsOneWidget);
      expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsNothing);
    });

    testWidgets('"Kaufen" and "Weglassen" settle the line and move on', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '500 g Hack'),
          textLine('b', 'Milch'),
          textLine('c', '2 Eier'),
        ]),
      );

      await tap(tester, KochmodusCardAnswers.shopKey);
      expect(onCard('Milch'), findsOneWidget);
      await tap(tester, KochmodusCardAnswers.ignoreKey);
      expect(onCard('Eier'), findsOneWidget);

      final run = await stored(tester);
      expect(lineOf(run, 'a').settlement, isA<LineShopping>());
      expect(lineOf(run, 'b').settlement, isA<LineIgnored>());
      expect(lineOf(run, 'c').settlement, isA<LineOpen>());
    });

    testWidgets('a tap on a row of "Alle Zutaten" puts it on the card, the '
        'row shows the badge of its answer', (tester) async {
      await open(
        tester,
        _run([
          textLine('a', '500 g Hack'),
          textLine('b', 'Milch'),
          textLine('c', '2 Eier'),
        ]),
      );
      await tap(tester, KochmodusCardAnswers.shopKey);
      await tap(tester, KochmodusCardAnswers.ignoreKey);
      expect(badge('a', Icons.shopping_cart_outlined), findsOneWidget);
      expect(badge('b', Icons.remove_rounded), findsOneWidget);
      expect(badge('c', Icons.check_rounded), findsNothing);

      await tap(tester, KochmodusIngredientRow.rowKey('a'));

      expect(onCard('Hack'), findsOneWidget);
      expect(find.byKey(KochmodusIngredientCard.closeKey), findsOneWidget);
      await tap(tester, KochmodusIngredientCard.closeKey);
      expect(onCard('Eier'), findsOneWidget);
    });

    testWidgets('a line that does not count starts left out, the cook can '
        'switch it back through the list', (tester) async {
      await open(
        tester,
        _run([
          textLine('a', '1 Prise Salz', settlement: const LineIgnored()),
          textLine('b', 'Milch'),
        ]),
      );
      expect(onCard('Milch'), findsOneWidget);
      expect(badge('a', Icons.remove_rounded), findsOneWidget);

      await tap(tester, KochmodusIngredientRow.rowKey('a'));
      expect(find.byKey(KochmodusCardAnswers.ignoreKey), findsNothing);
      await tap(tester, KochmodusCardAnswers.shopKey);

      expect(lineOf(await stored(tester), 'a').settlement, isA<LineShopping>());
    });

    testWidgets('an assignment that takes nothing is still asked, the page '
        'is not ready', (tester) async {
      await open(
        tester,
        _run([
          textLine('a', '250 g Mehl', settlement: assigned({'pack': 0})),
        ]),
        items: [packItem('pack', 2).copyWith(name: 'Mehl')],
      );

      expect(find.byKey(KochmodusIngredientCard.amountKey), findsOneWidget);
      expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
      expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
    });
  });

  group('a picked food that holds too little', () {
    Future<void> pickShort(WidgetTester tester) async {
      await open(
        tester,
        _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
        items: [_named('mince', 'Hack', 400)],
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));
      // The picker stays open with the two ways on, not "So lassen".
      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
    }

    testWidgets('"Nur 400 g nehmen" takes what is there', (tester) async {
      await pickShort(tester);
      await tap(tester, KochmodusItemPickerSheet.takeOnlyKey);

      final run = await stored(tester);
      final line = lineOf(run, 'a');
      final takes = (line.settlement as LineAssigned).takes;
      expect(takes.single.itemId, 'mince');
      expect(takes.single.amount, 400);
      expect(line.amount, 400);
      expect(run.lineOf(cookRestLineId('a')), isNull);
      expect(find.byKey(KochmodusCardAnswers.buyRestKey), findsNothing);
    });

    testWidgets('"100 g kaufen" takes what is there and puts the rest on '
        'the shopping list', (tester) async {
      await pickShort(tester);
      await tap(tester, KochmodusItemPickerSheet.buyRestKey);

      final run = await stored(tester);
      final takes = (lineOf(run, 'a').settlement as LineAssigned).takes;
      expect(takes.single.amount, 400);
      final rest = run.lineOf(cookRestLineId('a'));
      expect(rest?.text, '100 g Hack');
      expect(rest?.settlement, isA<LineShopping>());
    });
  });

  group('too little in the Vorrat', () {
    CookRun short() => _run([
      textLine('a', '500 g Hack', settlement: assigned({'mince': 300})),
    ]);
    final mince = _named('mince', 'Hack', 300);

    testWidgets('offers the rest, a second pack and only what is there', (
      tester,
    ) async {
      await open(tester, short(), items: [mince]);

      expect(find.byKey(KochmodusCardAnswers.buyRestKey), findsOneWidget);
      expect(find.byKey(KochmodusCardAnswers.secondPackKey), findsOneWidget);
      expect(find.byKey(KochmodusCardAnswers.takeOnlyKey), findsOneWidget);
    });

    testWidgets('"200 g kaufen" puts the rest on the shopping list', (
      tester,
    ) async {
      await open(tester, short(), items: [mince]);

      await tap(tester, KochmodusCardAnswers.buyRestKey);

      final run = await stored(tester);
      expect(lineOf(run, 'a').amount, 300);
      final rest = lineOf(run, cookRestLineId('a'));
      expect(rest.settlement, isA<LineShopping>());
      expect(rest.text, '200 g Hack');
    });

    testWidgets('"Nur 300 g nehmen" takes what is there and the line is '
        'answered', (tester) async {
      await open(tester, short(), items: [mince]);

      await tap(tester, KochmodusCardAnswers.takeOnlyKey);

      final run = await stored(tester);
      expect(lineOf(run, 'a').amount, 300);
      expect(
        run.lines.where((line) => line.id == cookRestLineId('a')),
        isEmpty,
      );
      expect(find.byKey(KochmodusReadyCard.mainKey), findsOneWidget);
    });

    testWidgets('"Zweite Packung" fills the rest from another food', (
      tester,
    ) async {
      await open(
        tester,
        short(),
        items: [mince, _named('beef', 'Hack Bio', 400)],
      );

      await tap(tester, KochmodusCardAnswers.secondPackKey);
      // The food the line holds stays tapped for the second pack.
      expect(
        find.descendant(
          of: find.byKey(KochmodusItemPickerSheet.rowKey('mince')),
          matching: find.byType(CircleAvatar),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('beef')));
      await harness.idle(tester);

      final takes =
          (lineOf(await stored(tester), 'a').settlement as LineAssigned).takes;
      expect(takes.fold<int>(0, (sum, take) => sum + take.amount), 500);
      expect(takes.map((take) => take.itemId), containsAll(['mince', 'beef']));
    });
  });

  group('"Anderes nehmen" on a covered line', () {
    final mince = _named('mince', 'Hack', 1000);
    final beef = _named('beef', 'Hack Bio', 1000);

    Future<void> openCovered(WidgetTester tester) async {
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', 'Milch')]),
        items: [mince, beef],
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));
      // Back on the card, the line is covered and offers another food.
      await tap(tester, KochmodusEnteredCard.changeKey);
    }

    Finder tapped(String id) => find.descendant(
      of: find.byKey(KochmodusItemPickerSheet.rowKey(id)),
      matching: find.byType(CircleAvatar),
    );

    testWidgets('opens the picker with nothing tapped', (tester) async {
      await openCovered(tester);
      final l10n = harness.l10n(tester);

      expect(
        find.descendant(
          of: find.byKey(KochmodusCardAnswers.haveKey),
          matching: find.text(l10n.kochmodusTakeOther),
        ),
        findsOneWidget,
      );
      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(find.byKey(KochmodusItemPickerSheet.rowKey('mince')), findsOne);
      expect(tapped('mince'), findsNothing);
      expect(tapped('beef'), findsNothing);
      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
    });

    testWidgets('the tapped food replaces the old one', (tester) async {
      await openCovered(tester);

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('beef'));

      final takes =
          (lineOf(await stored(tester), 'a').settlement as LineAssigned).takes;
      expect(takes.map((take) => take.itemId), ['beef']);
      expect(takes.single.amount, 300);
    });
  });

  group('a guessed spoon above its stock', () {
    CookRun spoon(String text, int take) => _run([
      textLine('a', text, settlement: assigned({'z': take})),
    ]);

    testWidgets(
      'offers "Nur 8 g nehmen" first, no shopping, one tap takes it',
      (tester) async {
        await open(
          tester,
          spoon('1 EL Zimt', 15),
          items: [_named('z', 'Zimt', 8)],
        );
        final l10n = harness.l10n(tester);

        expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(KochmodusCardAnswers.takeOnlyKey),
            matching: find.text(l10n.kochmodusAmountTakeOnly(_held('8 g'))),
          ),
          findsOneWidget,
        );
        expect(find.byKey(KochmodusCardAnswers.shopKey), findsNothing);
        expect(find.byKey(KochmodusCardAnswers.buyRestKey), findsNothing);
        expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
        expect(find.byKey(KochmodusCardAnswers.ignoreKey), findsOneWidget);
        expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);

        await tap(tester, KochmodusCardAnswers.takeOnlyKey);

        final takes =
            (lineOf(await stored(tester), 'a').settlement as LineAssigned)
                .takes;
        expect(takes.map((take) => (take.itemId, take.amount)), [('z', 8)]);
        expect(find.byKey(KochmodusReadyCard.mainKey), findsOneWidget);
      },
    );

    testWidgets('with nothing left the card offers to buy the rest', (
      tester,
    ) async {
      // Another cooking holds the 4 g that are left.
      await harness.store(
        tester,
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [
            textLine('o', '4 g Zimt', settlement: assigned({'z': 4})),
          ],
        ),
      );
      await open(
        tester,
        spoon('1/2 TL Zimt', 3),
        items: [_named('z', 'Zimt', 4)],
      );

      expect(find.byKey(KochmodusCardAnswers.buyRestKey), findsOneWidget);
      expect(find.byKey(KochmodusCardAnswers.takeOnlyKey), findsNothing);
    });
  });

  group('a line that waits for a weight while cooking', () {
    testWidgets('says "Gewicht fehlt" in its row, with no check', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          // No recipe weight of a carrot: nothing is taken until it is
          // weighed while cooking.
          textLine('a', '1 Möhre', settlement: assigned({'carrot': 0})),
          textLine('b', 'Milch'),
        ]),
        items: [_named('carrot', 'Möhre', 500)],
      );
      final l10n = harness.l10n(tester);

      expect(
        find.descendant(
          of: find.byKey(KochmodusIngredientRow.rowKey('a')),
          matching: find.text(l10n.kochmodusWeightMissing),
        ),
        findsOneWidget,
      );
      expect(badge('a', Icons.check_rounded), findsNothing);
    });

    testWidgets('says so on its card, as a warning', (tester) async {
      await open(
        tester,
        _run([
          textLine('a', '1 Möhre', settlement: assigned({'carrot': 0})),
          textLine('b', 'Milch'),
        ]),
        items: [_named('carrot', 'Möhre', 500)],
      );
      final l10n = harness.l10n(tester);

      await tap(tester, KochmodusIngredientRow.rowKey('a'));

      expect(onCard(l10n.kochmodusCardWeighWhileCooking), findsOneWidget);
    });
  });

  group('the finished card', () {
    CookRun settled({List<CookRunLine> extra = const []}) => _run(
      [
        textLine('a', '800 g Reis', settlement: assigned({'rice': 800})),
        ...extra,
      ],
      steps: const ['Kochen'],
    );

    testWidgets('with nothing to buy: Kochen and the guide choice', (
      tester,
    ) async {
      await open(tester, settled(), items: [_named('rice', 'Reis', 1000)]);
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusAssignSettledTitle), findsOneWidget);
      expect(find.byKey(KochmodusReadyCard.guideKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(KochmodusReadyCard.mainKey),
          matching: find.text(l10n.kochmodusAssignCook),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the energy and the three macros of one portion', (
      tester,
    ) async {
      await open(tester, settled(), items: [_named('rice', 'Reis', 1000)]);
      final l10n = harness.l10n(tester);
      Finder onFinishedCard(Finder finder) => find.descendant(
        of: find.byKey(KochmodusAssignStep.cardKey),
        matching: finder,
      );

      // 800 g for 4 portions at 100 kcal, 1 g each per 100 g.
      expect(
        onFinishedCard(find.text(l10n.kochmodusAssignKcalPerPortion(200))),
        findsOne,
      );
      // A no-break space keeps number and unit together.
      expect(onFinishedCard(find.text('2\u00A0g')), findsNWidgets(3));
      expect(
        onFinishedCard(find.text(l10n.caloriesProteinLabel)),
        findsOneWidget,
      );
      expect(
        onFinishedCard(find.text(l10n.caloriesCarbsLabel)),
        findsOneWidget,
      );
      expect(onFinishedCard(find.text(l10n.caloriesFatLabel)), findsOneWidget);
    });

    testWidgets('with an estimated line the energy and the label say so', (
      tester,
    ) async {
      await open(
        tester,
        settled(
          extra: [
            textLine('b', '1 EL Honig', settlement: assigned({'honey': 15})),
          ],
        ),
        items: [_named('rice', 'Reis', 1000), _named('honey', 'Honig', 500)],
      );
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusReadyCard.mainKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.cardKey),
          matching: find.textContaining('≈'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.labelKey),
          matching: find.text(l10n.kochmodusNutritionPortionEstimated),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.labelKey),
          matching: find.text(l10n.kochmodusNutritionPer('portion')),
        ),
        findsNothing,
      );
    });

    testWidgets('without an estimated line the plain forms stay', (
      tester,
    ) async {
      await open(tester, settled(), items: [_named('rice', 'Reis', 1000)]);
      final l10n = harness.l10n(tester);

      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.cardKey),
          matching: find.textContaining('≈'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.labelKey),
          matching: find.text(l10n.kochmodusNutritionPer('portion')),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusNutritionPortionEstimated), findsNothing);
    });

    testWidgets('with something to buy: "Erst einkaufen", no macros', (
      tester,
    ) async {
      await open(
        tester,
        settled(
          extra: [textLine('b', 'Milch', settlement: const LineShopping())],
        ),
        items: [_named('rice', 'Reis', 1000)],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusAssignAlmostTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(KochmodusReadyCard.mainKey),
          matching: find.text(l10n.kochmodusAssignPause),
        ),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusReadyCard.guideKey), findsNothing);
      expect(find.text(l10n.caloriesProteinLabel), findsNothing);
      expect(find.text(l10n.caloriesCarbsLabel), findsNothing);
      expect(find.text(l10n.caloriesFatLabel), findsNothing);
    });

    testWidgets('a take without complete nutrition shows no macros', (
      tester,
    ) async {
      await open(
        tester,
        settled(),
        items: [
          stockItem('rice', 1000, nutrition: null).copyWith(name: 'Reis'),
        ],
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusAssignSettledTitle), findsOneWidget);
      expect(find.text(l10n.caloriesProteinLabel), findsNothing);
    });
  });

  group('the food label under "Alles bereit"', () {
    CookRun settled({List<CookRunLine> extra = const []}) => _run(
      [
        textLine('a', '800 g Reis', settlement: assigned({'rice': 800})),
        ...extra,
      ],
      steps: const ['Kochen'],
    );

    Finder inLabel(Finder finder) => find.descendant(
      of: find.byKey(KochmodusAssignStep.labelKey),
      matching: finder,
    );

    testWidgets('stands under the card of one portion, with no per-100 '
        'column', (tester) async {
      await open(tester, settled(), items: [_named('rice', 'Reis', 1000)]);
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusAssignStep.labelKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(KochmodusAssignStep.labelKey)).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(KochmodusAssignStep.cardKey)).dy,
        ),
      );
      final table = tester.widget<EatLabelTable>(
        inLabel(find.byType(EatLabelTable)),
      );
      expect(table.eatenHeader, l10n.kochmodusNutritionPer('portion'));
      expect(table.per100Header, isNull);
      expect(
        inLabel(find.text(l10n.kochmodusNutritionPer('portion'))),
        findsOne,
      );
      // 800 g at 100 kcal and 1 g each per 100 g, over 4 portions.
      expect(table.rows.first.eaten, contains('200'));
      expect(inLabel(find.text(l10n.caloriesProteinLabel)), findsOneWidget);
      expect(inLabel(find.text(l10n.caloriesCarbsLabel)), findsOneWidget);
      expect(inLabel(find.text(l10n.caloriesFatLabel)), findsOneWidget);
    });

    testWidgets('is not there with something to buy', (tester) async {
      await open(
        tester,
        settled(
          extra: [textLine('b', 'Milch', settlement: const LineShopping())],
        ),
        items: [_named('rice', 'Reis', 1000)],
      );

      expect(find.byKey(KochmodusAssignStep.labelKey), findsNothing);
    });

    testWidgets('is not there while a line is open', (tester) async {
      await open(
        tester,
        settled(extra: [textLine('b', 'Milch')]),
        items: [_named('rice', 'Reis', 1000)],
      );

      expect(find.byKey(KochmodusAssignStep.labelKey), findsNothing);
    });

    testWidgets('right after "Hab ich" it comes after the confirmation', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '300 g Reis')], steps: const ['Kochen']),
        items: [_named('rice', 'Reis', 1000)],
      );
      expect(find.byKey(KochmodusAssignStep.labelKey), findsNothing);

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('rice'));

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect(find.byKey(KochmodusAssignStep.labelKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(KochmodusAssignStep.labelKey)).dy,
        greaterThan(
          tester.getBottomLeft(find.byKey(KochmodusEnteredCard.cardKey)).dy,
        ),
      );
    });
  });

  group('"+" in the top bar', () {
    testWidgets('adds the typed text as an open line', (tester) async {
      await open(
        tester,
        _run([textLine('e', 'Zimt', settlement: const LineIgnored())]),
      );
      final l10n = harness.l10n(tester);
      expect(find.text(l10n.kochmodusAssignSettledTitle), findsOneWidget);

      await tap(tester, KochmodusAssignPage.addLineKey);
      await tester.enterText(
        find.byKey(KochmodusTypeSheet.fieldKey),
        '  Reis  ',
      );
      await tester.pump();
      await tap(tester, KochmodusTypeSheet.addKey);

      final run = await stored(tester);
      expect(run.lines, hasLength(2));
      expect(run.lines.last.text, 'Reis');
      expect(run.lines.last.origin, CookLineOrigin.added);
      expect(run.lines.last.settlement, isA<LineOpen>());
      expect(onCard('Reis'), findsOneWidget);
    });
  });

  group('the line that says what was entered', () {
    // A food that is not in the Vorrat yet: a full pack of 1 kg.
    final pack = stockItem(
      'found',
      1000,
    ).copyWith(name: 'Hack frisch', weight: '1 kg');

    Future<void> findFood(
      WidgetTester tester,
      RecipeFoodPick Function() pick,
    ) async {
      answer = pick;
      await open(
        tester,
        _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, _pickKey);
    }

    testWidgets('after a full pack it names the food, the pack and what '
        'stays', (tester) async {
      await findFood(tester, () => newFood(pack, amount: 1000));
      // 500 g of a 1 kg pack: the cook is asked how much he takes first.
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );
      final l10n = harness.l10n(tester);
      // Always in the food's unit: a full pack reads "1,000 g", not "1 kg".
      String amount(int value) => _held(
        l10n.cookAmountGrams(NumberFormat.decimalPattern('en').format(value)),
      );

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(KochmodusEnteredCard.cardKey),
          matching: find.text(pack.name),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.kochmodusEnteredPack(amount(1000), amount(500), amount(500)),
        ),
        findsOneWidget,
      );
      expect(onCard('Milch'), findsOneWidget);
    });

    testWidgets('after an estimated food it says the values are estimated', (
      tester,
    ) async {
      final estimated = pack.copyWith(aiEstimated: true);
      await findFood(tester, () => newFood(estimated, amount: 500));
      final l10n = harness.l10n(tester);

      expect(
        find.text(
          l10n.kochmodusEnteredEstimated(
            _held(
              stockAmountText(
                l10n,
                amount: 500,
                unit: InventoryAmountUnit.gram,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('after a Vorrat pick it says so, and the next answer takes '
        'the line away', (tester) async {
      final home = _named('home', 'Fleisch', 800);
      await harness.stock(tester, [home]);
      answer = () => RecipeFoodInStock([home]);
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', 'Milch')]),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);
      final l10n = harness.l10n(tester);

      expect(
        find.text(
          l10n.kochmodusEnteredFromStockTake(_held('300 g'), _held('800 g')),
        ),
        findsOneWidget,
      );
      // The Vorrat food stays in the Vorrat; the line takes from it.
      final take =
          (lineOf(await stored(tester), 'a').settlement as LineAssigned)
              .takes
              .single;
      expect(take.itemId, 'home');
      expect(
        harness.cook.inventory.items.map((item) => item.id),
        contains('home'),
      );

      await tap(tester, KochmodusCardAnswers.ignoreKey);

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
    });

    testWidgets('"Ändern" of a Vorrat food puts the line back on the card', (
      tester,
    ) async {
      final home = _named('home', 'Fleisch', 800);
      await harness.stock(tester, [home]);
      answer = () => RecipeFoodInStock([home]);
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', 'Milch')]),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);
      expect(onCard('Milch'), findsOneWidget);

      await tap(tester, KochmodusEnteredCard.changeKey);

      expect(onCard('Hack'), findsOneWidget);
      expect(find.byType(InventoryStockAmountPage), findsNothing);
    });

    testWidgets('"Ändern" of a new food opens the amount page', (tester) async {
      await findFood(tester, () => newFood(pack, amount: 1000));
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );

      await tap(tester, KochmodusEnteredCard.changeKey);

      expect(find.byType(InventoryStockAmountPage), findsOneWidget);
    });

    testWidgets('a food picked in the Vorrat picker is reported with what '
        'the line takes of it', (tester) async {
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', 'Milch')]),
        items: [_named('mince', 'Hack', 800)],
      );
      final l10n = harness.l10n(tester);

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect(
        find.text(
          l10n.kochmodusEnteredFromStockTake(_held('300 g'), _held('800 g')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the answers keep their place when the line comes', (
      tester,
    ) async {
      await open(
        tester,
        _run([textLine('a', '300 g Hack'), textLine('b', '300 g Mehl')]),
        items: [_named('mince', 'Hack', 800)],
      );
      final before = tester.getTopLeft(
        find.byKey(KochmodusCardAnswers.haveKey),
      );

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));

      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(KochmodusCardAnswers.haveKey)),
        before,
      );
    });
  });

  group('the room for the hints', () {
    // The amount of a taken line is a tap target, that of an open or waiting
    // line is plain text, so each pair compares lines with the same amount.
    List<CookRunLine> lines() => [
      // Two hints: what is there, and that the cook takes less.
      textLine(
        'two',
        '500 g Mehl',
        amount: 300,
        settlement: assigned({'flour': 300}),
      ),
      // One hint: what is there.
      textLine('oneTaken', '500 g Mehl', settlement: assigned({'flour': 500})),
      // One hint: not in the Vorrat.
      textLine('one', '200 g Reis'),
      // No hint: the line waits on the shopping list.
      textLine('none', '100 g Salz', settlement: const LineShopping()),
    ];

    double haveY(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(KochmodusCardAnswers.haveKey)).dy;

    Finder inCard(String text) => find.descendant(
      of: find.byKey(KochmodusAssignStep.cardKey),
      matching: find.textContaining(text),
    );

    testWidgets('the answers keep their y position for 1 and 2 hints', (
      tester,
    ) async {
      await open(tester, _run(lines()), items: [_named('flour', 'Mehl', 800)]);

      await tap(tester, KochmodusIngredientRow.rowKey('two'));
      expect(inCard('Only'), findsOneWidget);
      final twoHints = haveY(tester);
      await tap(tester, KochmodusIngredientRow.rowKey('oneTaken'));
      expect(inCard('Only'), findsNothing);

      expect(haveY(tester), twoHints);
    });

    testWidgets('the answers keep their y position for 0 and 1 hints', (
      tester,
    ) async {
      await open(tester, _run(lines()), items: [_named('flour', 'Mehl', 800)]);

      await tap(tester, KochmodusIngredientRow.rowKey('one'));
      expect(onCard('Reis'), findsOneWidget);
      final oneHint = haveY(tester);
      await tap(tester, KochmodusIngredientRow.rowKey('none'));
      expect(onCard('Salz'), findsOneWidget);

      expect(haveY(tester), oneHint);
    });
  });

  group('small screens', () {
    for (final scale in [1.3, 2.0, 3.0]) {
      testWidgets('do not overflow at 320 px and text scale $scale', (
        tester,
      ) async {
        await harness.store(
          tester,
          _run([textLine('a', '500 g Hack'), textLine('b', 'Milch')]),
        );

        await harness.pumpAssign(
          tester,
          't1',
          width: 320,
          textScale: scale,
          locale: const Locale('de'),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
      });
    }
  });
}
