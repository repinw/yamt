import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/food_pick_route_args.dart';
import 'package:yamt/features/inventory/presentation/models/recipe_food_pick.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
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
import 'kochmodus_held_support.dart';
import 'kochmodus_page_harness.dart';

const _pickKey = Key('pick-food');

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

void main() {
  late KochmodusCookingHarness harness;
  RecipeFoodPick Function()? answer;
  FoodPickRouteArgs? pickArgs;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    answer = null;
    pickArgs = null;
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    List<InventoryItem> items = const [],
    CookRun? other,
  }) async {
    await harness.stock(tester, items);
    if (other != null) await harness.store(tester, other);
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
          builder: (context, state) {
            pickArgs = state.extra as FoodPickRouteArgs?;
            return Scaffold(
              body: TextButton(
                key: _pickKey,
                onPressed: () => context.pop<RecipeFoodPick>(answer!()),
                child: const Text('pick'),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  Future<CookRunLine> lineA(WidgetTester tester) async =>
      (await harness.storedRun(
        tester,
        'recipe-t1',
      )).lines.singleWhere((l) => l.id == 'a');

  Finder onCard(String text) => find.descendant(
    of: find.byKey(KochmodusAssignStep.cardKey),
    matching: find.text(text),
  );

  group('milk of several words is no stand-in for pudding rice', () {
    testWidgets('"Hab ich" shows the milk under all, not as a suggestion, and '
        'the card names no stock before', (tester) async {
      final milk = stockItem(
        'milk',
        1000,
        unit: InventoryAmountUnit.milliliter,
      ).copyWith(name: 'Fettarme H-Milch');
      await open(
        tester,
        _run([textLine('a', '250 g Milchreis')]),
        items: [milk],
        other: otherRun({'milk': 1000}),
      );
      final l10n = harness.l10n(tester);

      expect(onCard('Fettarme H-Milch'), findsNothing);
      expect(
        find.text(l10n.kochmodusPickerHeldFor('Pfannkuchen')),
        findsNothing,
      );

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(
        find.byKey(KochmodusItemPickerSheet.rowKey('milk')),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsNothing);
      expect(
        find.text(l10n.kochmodusPickerSuggested.toUpperCase()),
        findsNothing,
      );
    });
  });

  group('every matching Vorrat food is planned for something else', () {
    final rice = namedStock('rice', 'Reis', 800);

    CookRun mine() =>
        _run([textLine('a', '500 g Reis'), textLine('b', 'Milch')]);

    testWidgets('the card claims nothing about the food', (tester) async {
      await open(tester, mine(), items: [rice], other: otherRun({'rice': 800}));

      expect(
        find.descendant(
          of: find.byKey(KochmodusAssignStep.cardKey),
          matching: find.textContaining('Pfannkuchen'),
        ),
        findsNothing,
      );
    });

    testWidgets('"Hab ich" opens the picker with the planned food, and '
        '"Etwas anderes suchen" goes to the food search with the held '
        'foods', (tester) async {
      await open(tester, mine(), items: [rice], other: otherRun({'rice': 800}));

      await tap(tester, KochmodusCardAnswers.haveKey);

      expect(find.byKey(_pickKey), findsNothing);
      expect(
        find.byKey(KochmodusItemPickerSheet.rowKey('rice')),
        findsOneWidget,
      );

      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);

      expect(find.byKey(_pickKey), findsOneWidget);
      expect(pickArgs!.heldItemIds, {'rice'});
    });

    testWidgets('a new pack from the search is taken, not the planned one', (
      tester,
    ) async {
      final fresh = namedStock(
        'fresh',
        'Reis frisch',
        1000,
      ).copyWith(weight: '1 kg');
      answer = () => newPackFood(fresh, amount: 1000);
      await open(tester, mine(), items: [rice], other: otherRun({'rice': 800}));

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);
      // 500 g of a 1 kg pack: the cook is asked how much he takes.
      await tap(
        tester,
        KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe),
      );

      final takes = (await lineA(tester)).settlement as LineAssigned;
      // The pack goes in under a new id; the planned one stays untouched.
      expect(takes.takes, hasLength(1));
      expect(takes.takes.single.itemId, isNot('rice'));
      expect(takes.takes.single.amount, 500);
      expect(
        harness.cook.inventory.items.map((item) => item.name),
        contains('Reis frisch'),
      );
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
    });

    testWidgets('the same holds when another line of this cooking took it', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('a', '500 g Reis'),
          textLine('b', '800 g Reis', settlement: assigned({'rice': 800})),
        ]),
        items: [rice],
      );

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);

      expect(find.byKey(_pickKey), findsOneWidget);
      expect(pickArgs!.heldItemIds, {'rice'});
    });
  });

  group('the picker names what is planned', () {
    final held = namedStock('rice', 'Reis', 800);
    final free = namedStock('free', 'Reis Bio', 500);
    final noodles = namedStock('noodles', 'Nudeln', 100);

    CookRun mine({List<CookRunLine> extra = const []}) =>
        _run([textLine('a', '500 g Reis'), ...extra]);

    Future<void> openPicker(
      WidgetTester tester, {
      CookRun? other,
      List<CookRunLine> extra = const [],
    }) async {
      await open(
        tester,
        mine(extra: extra),
        items: [held, free, noodles],
        other: other,
      );
      await tap(tester, KochmodusCardAnswers.haveKey);
    }

    testWidgets('says for which cooking, not a red "missing"', (tester) async {
      await openPicker(tester, other: otherRun({'rice': 800}));
      final l10n = harness.l10n(tester);

      final row = find.byKey(KochmodusItemPickerSheet.rowKey('rice'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(
          of: row,
          matching: find.text(l10n.kochmodusPickerHeldFor('Pfannkuchen')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(KochmodusItemPickerSheet.rowKey('free')),
        findsOneWidget,
      );
    });

    testWidgets('says just "planned" when the cooking itself holds it', (
      tester,
    ) async {
      await openPicker(
        tester,
        extra: [
          textLine('b', '800 g Reis', settlement: assigned({'rice': 800})),
        ],
      );
      final l10n = harness.l10n(tester);

      expect(
        find.descendant(
          of: find.byKey(KochmodusItemPickerSheet.rowKey('rice')),
          matching: find.text(l10n.kochmodusPickerHeld),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows every Vorrat food at once, the name matches first', (
      tester,
    ) async {
      await openPicker(tester, other: otherRun({'rice': 800}));
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusPickerSuggested.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusPickerAll.toUpperCase()), findsOneWidget);
      expect(
        find.byKey(KochmodusItemPickerSheet.rowKey('noodles')),
        findsOneWidget,
      );
      // Too little of a food that is no match is no red "missing".
      expect(
        find.descendant(
          of: find.byKey(KochmodusItemPickerSheet.rowKey('noodles')),
          matching: find.textContaining('missing'),
        ),
        findsNothing,
      );
    });
  });
}
