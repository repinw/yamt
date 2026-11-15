import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_held_support.dart';
import 'kochmodus_page_harness.dart';

const _pickKey = Key('pick-food');
const _nbsp = ' ';

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

void main() {
  late KochmodusCookingHarness harness;
  RecipeFoodPick Function()? answer;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    answer = null;
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    List<InventoryItem> items = const [],
    CookRun? other,
    Locale locale = const Locale('en'),
  }) async {
    await harness.stock(tester, items);
    if (other != null) await harness.store(tester, other);
    await harness.store(tester, run);
    await openPage(
      tester,
      harness,
      const KochmodusAssignPage(recipeId: 't1'),
      locale: locale,
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

  testWidgets('is hidden when the line takes nothing of the food', (
    tester,
  ) async {
    // Another cooking holds all of the Vorrat food the cook picks.
    final home = namedStock('home', 'Reis', 800);
    answer = () => RecipeFoodInStock([home]);
    await open(
      tester,
      _run([textLine('a', '500 g Reis'), textLine('b', 'Milch')]),
      items: [home],
      other: otherRun({'home': 800}),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
    await tap(tester, _pickKey);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
  });

  testWidgets('a food with nothing left for the line never says it is weighed '
      'while cooking', (tester) async {
    // "1 Zwiebel" would wait for a weight on a food kept in g, but another
    // cooking holds all of this one.
    final home = namedStock('home', 'Zwiebel', 800);
    answer = () => RecipeFoodInStock([home]);
    await open(
      tester,
      _run([textLine('a', '1 Zwiebel'), textLine('b', 'Milch')]),
      items: [home],
      other: otherRun({'home': 800}),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
    await tap(tester, _pickKey);

    expect(find.textContaining('weigh it while cooking'), findsNothing);
    expect(find.textContaining('0${_nbsp}g'), findsNothing);
  });

  testWidgets('says nothing could be taken of a new food the line cannot take '
      'from yet', (tester) async {
    // Pieces without a weight, on a line in grams.
    final eggs = namedStock(
      'eggs',
      'Reis',
      6000,
    ).copyWith(amountUnit: InventoryAmountUnit.piece, amountScale: 1000);
    answer = () => newPackFood(eggs, amount: 6000);
    await open(
      tester,
      _run([textLine('a', '500 g Reis'), textLine('b', 'Milch')]),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);
    final l10n = harness.l10n(tester);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(find.text(l10n.kochmodusEnteredNothing), findsOneWidget);
    expect(find.byKey(KochmodusEnteredCard.changeKey), findsOneWidget);
  });

  testWidgets('is shown for a line without a need', (tester) async {
    await open(
      tester,
      _run([textLine('a', 'Milch'), textLine('b', '300 g Mehl')]),
      items: [namedStock('milk', 'Milch', 800)],
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.rowKey('milk'));

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
  });

  testWidgets('a rough need that waits for a weight says the pack and the '
      'weighing, not a guessed take', (tester) async {
    final sugar = namedStock('sugar', 'Zucker', 1000).copyWith(weight: '1 kg');
    answer = () => newPackFood(sugar, amount: 1000);
    await open(
      tester,
      _run([
        textLine(
          'a',
          'etwas Zucker',
          roughWeight: const CookRoughWeight(
            amount: 3,
            unit: TemplateIngredientUnit.gram,
          ),
        ),
        textLine('b', 'Milch'),
      ]),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);
    final l10n = harness.l10n(tester);

    expect(
      find.text(l10n.kochmodusEnteredPackWeigh('1,000${_nbsp}g')),
      findsOneWidget,
    );
    // The guess is no fact: no take is named.
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets('a spoon on a pack in g says the pack and the weighing, not a '
      'guessed take', (tester) async {
    final honey = namedStock('honey', 'Honig', 1000).copyWith(weight: '1 kg');
    answer = () => newPackFood(honey, amount: 1000);
    // A spoon is a standard 15 g: a guess the cook weighs while cooking.
    await open(
      tester,
      _run([textLine('a', '1 EL Honig'), textLine('b', 'Milch')]),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);
    final l10n = harness.l10n(tester);

    expect(
      find.text(l10n.kochmodusEnteredPackWeigh('1,000${_nbsp}g')),
      findsOneWidget,
    );
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets('a count in pieces of a new pack kept in pieces has no "≈"', (
    tester,
  ) async {
    final eggs = namedStock('eggs', 'Eier', 30000).copyWith(
      amountUnit: InventoryAmountUnit.piece,
      amountScale: 1000,
      weight: '30 Stk.',
    );
    answer = () => newPackFood(eggs, amount: 30000);
    await open(tester, _run([textLine('a', '3 Eier'), textLine('b', 'Milch')]));

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);
    expect(find.textContaining('3'), findsWidgets);
  });

  testWidgets('a rough line that waits for no weight says "≈" and keeps '
      'amount and unit together', (tester) async {
    final salt = namedStock('salt', 'Salz', 1000).copyWith(weight: '1 kg');
    answer = () => newPackFood(salt, amount: 1000);
    await open(
      tester,
      _run([
        textLine(
          'a',
          'Prise Salz',
          roughWeight: const CookRoughWeight(
            amount: 1,
            unit: TemplateIngredientUnit.gram,
          ),
        ),
        textLine('b', 'Milch'),
      ]),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);
    final l10n = harness.l10n(tester);

    expect(
      find.text(
        l10n.kochmodusEnteredPack(
          '1,000${_nbsp}g',
          '≈$_nbsp'
              '1${_nbsp}g',
          '999${_nbsp}g',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps amounts of a plain need on one line', (tester) async {
    final flour = namedStock('flour', 'Mehl', 1000).copyWith(weight: '1 kg');
    answer = () => newPackFood(flour, amount: 1000);
    await open(
      tester,
      _run([textLine('a', '300 g Mehl'), textLine('b', 'Milch')]),
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, _pickKey);
    final l10n = harness.l10n(tester);

    expect(
      find.text(
        l10n.kochmodusEnteredPack(
          '1,000${_nbsp}g',
          '300${_nbsp}g',
          '700${_nbsp}g',
        ),
      ),
      findsOneWidget,
    );
  });

  group('a pack from the search or a scan', () {
    Future<void> find400(WidgetTester tester, int pack, String text) async {
      final food = namedStock(
        'found',
        'Hähnchen',
        pack,
      ).copyWith(weight: '$pack g');
      answer = () => newPackFood(food, amount: pack);
      await open(tester, _run([textLine('a', text), textLine('b', 'Milch')]));
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, _pickKey);
    }

    testWidgets('400 g in the recipe and a 500 g pack ask how much', (
      tester,
    ) async {
      await find400(tester, 500, '400 g Hähnchen');
      final l10n = harness.l10n(tester);

      expect(find.byType(KochmodusTakeSheet), findsOneWidget);
      for (final answer in KochmodusTakeAnswer.values) {
        expect(
          find.byKey(KochmodusTakeSheet.answerKey(answer)),
          findsOneWidget,
        );
      }
      expect(
        find.text(l10n.kochmodusTakeAskRecipe('400${_nbsp}g')),
        findsOneWidget,
      );
      // Nothing is stored before the answer.
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
    });

    testWidgets('"Alles" takes the whole pack as the line\'s amount', (
      tester,
    ) async {
      await find400(tester, 500, '400 g Hähnchen');

      await tap(tester, KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.all));

      final run = await harness.storedRun(tester, 'recipe-t1');
      final line = run.lines.singleWhere((line) => line.id == 'a');
      expect(line.amount, 500);
      expect((line.settlement as LineAssigned).takes.single.amount, 500);
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    });

    testWidgets('200 g in the recipe and a 1 kg pack ask nothing', (
      tester,
    ) async {
      await find400(tester, 1000, '200 g Hähnchen');

      expect(find.byType(KochmodusTakeSheet), findsNothing);
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      final run = await harness.storedRun(tester, 'recipe-t1');
      final line = run.lines.singleWhere((line) => line.id == 'a');
      expect(line.amount, isNull);
      expect((line.settlement as LineAssigned).takes.single.amount, 200);
    });
  });

  group("in German, amounts in the food's unit", () {
    Future<void> enter(
      WidgetTester tester,
      CookRunLine line,
      InventoryItem food,
      int amount,
    ) async {
      answer = () => newPackFood(food, amount: amount);
      await open(
        tester,
        _run([line, textLine('b', 'Milch')]),
        locale: const Locale('de'),
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, _pickKey);
    }

    testWidgets('an estimated lemon taken by half says "0,5 Stk."', (
      tester,
    ) async {
      final lemon = stockItem(
        'lemon',
        1000,
        unit: InventoryAmountUnit.piece,
        scale: 1000,
      ).copyWith(name: 'Zitrone', aiEstimated: true, weight: '1 pc');
      // The line takes half of the one piece: 500 of 1000 thousandths.
      await enter(tester, textLine('a', '1/2 Zitrone'), lemon, 1000);
      // Half of one piece of a whole piece: the cook is asked how much first.
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusEnteredEstimated('0,5${_nbsp}Stk.')),
        findsOneWidget,
      );
      expect(l10n.localeName, 'de');
    });

    testWidgets('a pack of 1000 ml taken whole says "1.000 ml"', (
      tester,
    ) async {
      final milk = stockItem(
        'milk',
        1000,
        unit: InventoryAmountUnit.milliliter,
      ).copyWith(name: 'Milch frisch', weight: '1 l');
      await enter(tester, textLine('a', '1 l Milch'), milk, 1000);
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusEnteredPackAll('1.000${_nbsp}ml')),
        findsOneWidget,
      );
      expect(l10n.localeName, 'de');
    });
  });

  testWidgets('for a food from the Vorrat is never empty', (tester) async {
    // The food has enough: the cook picks it, nothing more is asked.
    final home = namedStock('home', 'Reis', 800);
    await open(
      tester,
      _run([textLine('a', '300 g Reis'), textLine('b', 'Milch')]),
      items: [home],
    );

    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.rowKey('home'));
    final l10n = harness.l10n(tester);

    expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    expect(
      find.text(
        l10n.kochmodusEnteredFromStockTake('300${_nbsp}g', '800${_nbsp}g'),
      ),
      findsOneWidget,
    );
  });
}
