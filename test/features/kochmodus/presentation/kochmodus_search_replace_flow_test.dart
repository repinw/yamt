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

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_held_support.dart';
import 'kochmodus_page_harness.dart';

const _pickKey = Key('pick-food');
const _runId = 'recipe-t1';

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

InventoryItem _pack(int grams) =>
    namedStock('fresh', 'Hack frisch', grams).copyWith(weight: '$grams g');

void main() {
  late KochmodusCookingHarness harness;
  RecipeFoodPick Function()? answer;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    answer = null;
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

  Future<List<ItemTake>> takes(WidgetTester tester) async {
    final run = await harness.storedRun(tester, _runId);
    final line = run.lines.singleWhere((line) => line.id == 'a');
    return (line.settlement as LineAssigned).takes;
  }

  // The line holds the Vorrat food "mince" and offers "Anderes nehmen".
  Future<void> openCovered(WidgetTester tester, String text) async {
    await open(tester, _run([textLine('a', text), textLine('b', 'Milch')]), [
      namedStock('mince', 'Hack', 1000),
    ]);
    await tap(tester, KochmodusCardAnswers.haveKey);
    await tap(tester, KochmodusItemPickerSheet.rowKey('mince'));
    await tap(tester, KochmodusEnteredCard.changeKey);
  }

  group('"Anderes nehmen" and then the search', () {
    final recipe = KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe);

    testWidgets('a found pack replaces the old food, and the question comes '
        'when the pack holds little more than the need', (tester) async {
      answer = () => newPackFood(_pack(500), amount: 500);
      await openCovered(tester, '400 g Hack');

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);

      expect(find.byKey(recipe), findsOneWidget);
      await tap(tester, recipe);

      final held = await takes(tester);
      expect(held, hasLength(1));
      expect(held.single.itemId, isNot('mince'));
      expect(held.single.amount, 400);
    });

    testWidgets('a pack that holds plenty asks nothing and is the only food', (
      tester,
    ) async {
      answer = () => newPackFood(_pack(1000), amount: 1000);
      await openCovered(tester, '200 g Hack');

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);

      expect(find.byKey(recipe), findsNothing);
      final held = await takes(tester);
      expect(held, hasLength(1));
      expect(held.single.itemId, isNot('mince'));
      expect(held.single.amount, 200);
    });

    testWidgets('closing the search without a pick changes nothing', (
      tester,
    ) async {
      answer = () => const RecipeFoodInStock([]);
      await openCovered(tester, '200 g Hack');
      final before = await takes(tester);

      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      harness.router.pop();
      await harness.idle(tester);

      expect(await takes(tester), before);
    });

    testWidgets('"Zweite Packung" keeps the old food and adds the pack', (
      tester,
    ) async {
      answer = () => newPackFood(_pack(1000), amount: 1000);
      await open(
        tester,
        _run([
          textLine('a', '400 g Hack', settlement: assigned({'mince': 300})),
        ]),
        [namedStock('mince', 'Hack', 300)],
      );
      await tap(tester, KochmodusCardAnswers.secondPackKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);

      final held = await takes(tester);
      expect(held.map((take) => take.itemId), contains('mince'));
      expect(held, hasLength(2));
      expect(held.fold<int>(0, (sum, take) => sum + take.amount), 400);
    });

    testWidgets('a page that is gone while the question is open stores the '
        "pack with the recipe's amount", (tester) async {
      answer = () => newPackFood(_pack(500), amount: 500);
      await openCovered(tester, '400 g Hack');
      await tap(tester, KochmodusCardAnswers.haveKey);
      await tap(tester, KochmodusItemPickerSheet.searchOtherKey);
      await tap(tester, _pickKey);
      expect(find.byKey(recipe), findsOneWidget);

      // The cook leaves the page while the sheet is open.
      harness.router.go('/');
      await harness.idle(tester);
      await tester.pumpAndSettle();

      final held = await takes(tester);
      expect(held, hasLength(1));
      expect(held.single.itemId, isNot('mince'));
      expect(held.single.amount, 400);
      expect(
        harness.cook.inventory.items.map((item) => item.name),
        contains('Hack frisch'),
      );
    });
  });
}
