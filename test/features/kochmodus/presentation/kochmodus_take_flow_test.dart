import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

const _nbsp = ' ';

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

InventoryItem _named(String id, String name, int amount) =>
    stockItem(id, amount).copyWith(name: name);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run,
    List<InventoryItem> items,
  ) async {
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
      ],
    );
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  Future<void> pick(WidgetTester tester, String itemId) async {
    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.rowKey(itemId));
  }

  Future<CookRunLine> lineA(WidgetTester tester) async =>
      (await harness.storedRun(
        tester,
        'recipe-t1',
      )).lines.singleWhere((line) => line.id == 'a');

  Future<Map<String, int>> takes(WidgetTester tester) async => {
    for (final take in ((await lineA(tester)).settlement as LineAssigned).takes)
      take.itemId: take.amount,
  };

  final sheet = find.byType(KochmodusTakeSheet);

  group('picking a food that holds a bit more than the line needs', () {
    CookRun chicken() =>
        _run([textLine('a', '400 g Hähnchenbrust'), textLine('b', 'Milch')]);

    testWidgets('asks how much, with the three answers', (tester) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');

      expect(sheet, findsOneWidget);
      for (final answer in KochmodusTakeAnswer.values) {
        expect(
          find.byKey(KochmodusTakeSheet.answerKey(answer)),
          findsOneWidget,
        );
      }
      // Nothing is stored before the answer.
      expect(await harness.storedRun(tester, 'recipe-t1'), isNotNull);
      expect((await lineA(tester)).settlement, isA<LineOpen>());
    });

    testWidgets('"wie im Rezept" takes the recipe amount and says so', (
      tester,
    ) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );
      final l10n = harness.l10n(tester);

      expect(await takes(tester), {'f': 400});
      expect((await lineA(tester)).amount, isNull);
      expect(
        find.text(
          l10n.kochmodusEnteredFromStockTake('400${_nbsp}g', '500${_nbsp}g'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Alles" takes all the food has for the line', (tester) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tap(tester, KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.all));

      expect(await takes(tester), {'f': 500});
      // The amount of the line for this cooking is 500 g.
      expect((await lineA(tester)).amount, 500);
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    });

    testWidgets('"Andere Menge" opens the amount sheet', (tester) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.other),
      );

      expect(find.byType(KochmodusAmountSheet), findsOneWidget);
    });

    testWidgets('closing the amount sheet keeps the recipe amount', (
      tester,
    ) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.other),
      );
      await tester.tapAt(const Offset(5, 5));
      await harness.idle(tester);

      expect(find.byType(KochmodusAmountSheet), findsNothing);
      expect(await takes(tester), {'f': 400});
    });

    testWidgets('closing the question keeps the recipe amount', (tester) async {
      await open(tester, chicken(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tester.tapAt(const Offset(5, 5));
      await harness.idle(tester);

      expect(sheet, findsNothing);
      expect(await takes(tester), {'f': 400});
    });
  });

  group('after an own amount', () {
    // 450 g were typed on "400 g Hähnchenbrust", 500 g are there.
    CookRun own() => _run([
      textLine('a', '400 g Hähnchenbrust', amount: 450),
      textLine('b', 'Milch'),
    ]);

    testWidgets("the first answer is the recipe's amount again", (
      tester,
    ) async {
      await open(tester, own(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      final l10n = harness.l10n(tester);

      expect(
        find.descendant(
          of: find.byKey(
            KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
          ),
          matching: find.text(l10n.kochmodusTakeAskRecipe('400${_nbsp}g')),
        ),
        findsOneWidget,
      );
    });

    testWidgets("choosing it puts the line back to the recipe's amount", (
      tester,
    ) async {
      await open(tester, own(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );

      expect((await lineA(tester)).amount, isNull);
      expect(await takes(tester), {'f': 400});
    });

    testWidgets('closing the question keeps the own amount', (tester) async {
      await open(tester, own(), [_named('f', 'Hähnchenbrust', 500)]);

      await pick(tester, 'f');
      await tester.tapAt(const Offset(5, 5));
      await harness.idle(tester);

      expect((await lineA(tester)).amount, 450);
      expect(await takes(tester), {'f': 450});
    });
  });

  group('a food that does not cover the line', () {
    testWidgets('"400 g Mehl" on a food of 200 g keeps the picker open and '
        'says what is missing', (tester) async {
      await open(
        tester,
        _run([textLine('a', '400 g Mehl'), textLine('b', 'Milch')]),
        [_named('f', 'Mehl', 200)],
      );

      await pick(tester, 'f');
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusItemPickerSheet.missingKey), findsOneWidget);
      expect(
        find.text(l10n.kochmodusPickerStillMissing('200 g')),
        findsOneWidget,
      );
      expect((await lineA(tester)).settlement, isA<LineOpen>());
    });
  });

  group('nothing is asked', () {
    testWidgets('for 200 g Mehl on a food of 1 kg', (tester) async {
      await open(
        tester,
        _run([textLine('a', '200 g Mehl'), textLine('b', 'Milch')]),
        [_named('f', 'Mehl', 1000)],
      );

      await pick(tester, 'f');

      expect(sheet, findsNothing);
      expect(await takes(tester), {'f': 200});
    });

    testWidgets('for two foods picked for one line', (tester) async {
      await open(
        tester,
        _run([textLine('a', '400 g Mehl'), textLine('b', 'Milch')]),
        [_named('f', 'Mehl', 250), _named('g', 'Mehl Bio', 250)],
      );

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.rowKey('f'));
      await tap(tester, KochmodusItemPickerSheet.rowKey('g'));

      expect(sheet, findsNothing);
      expect(await takes(tester), {'f': 250, 'g': 150});
    });
  });

  group('a line in pieces on a food kept in grams', () {
    testWidgets('says the food is weighed while cooking', (tester) async {
      await open(
        tester,
        _run([textLine('a', '1 Zwiebel'), textLine('b', 'Milch')]),
        [_named('f', 'Zwiebel', 800)],
      );

      await pick(tester, 'f');
      // The weight comes while cooking, so the tapped food covers the line and
      // the picker closes at once.
      final l10n = harness.l10n(tester);

      expect(sheet, findsNothing);
      expect(find.byType(KochmodusItemPickerSheet), findsNothing);
      expect(
        find.textContaining(l10n.kochmodusPickerStillMissing('1')),
        findsNothing,
      );
      expect(
        find.text(l10n.kochmodusEnteredFromStockWeigh('800${_nbsp}g')),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
    });
  });
}
