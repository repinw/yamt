import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
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
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/kochmodus/presentation/kochmodus_cooking_harness.dart';
import '../../test/features/kochmodus/presentation/kochmodus_held_support.dart';
import '../../test/features/kochmodus/presentation/kochmodus_page_harness.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';

const _pickKey = Key('held-flow-pick');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The dead end: the Vorrat has the food, but another cooking (or another
  // line) holds all of it. "Hab ich" must lead to the food search, which
  // enters a new pack; the line takes from that, never from the empty pack.
  for (final holder in ['another cooking', 'another line']) {
    testWidgets('"Hab ich" enters a new pack when the only match is planned '
        'for $holder', (tester) async {
      final harness = await KochmodusCookingHarness.open();
      final otherLine = holder == 'another line';
      final rice = namedStock('rice', 'Reis', 800);
      await harness.stock(tester, [rice]);
      if (!otherLine) {
        await harness.store(tester, otherRun({'rice': 800}));
      }
      final run = buildCookRun(
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const [],
        lines: [
          textLine('a', '500 g Reis'),
          if (otherLine)
            textLine(
              'b',
              '800 g Reis',
              amount: 800,
              settlement: assigned({'rice': 800}),
            )
          else
            textLine('b', 'Milch'),
        ],
      );
      await harness.store(tester, run);
      FoodPickRouteArgs? foodSearch;
      final fresh = namedStock(
        'fresh',
        'Reis frisch',
        1000,
      ).copyWith(weight: '1 kg');
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
              foodSearch = state.extra as FoodPickRouteArgs?;
              return Scaffold(
                body: TextButton(
                  key: _pickKey,
                  onPressed: () => context.pop<RecipeFoodPick>(
                    newPackFood(fresh, amount: 1000),
                  ),
                  child: const Text('pick'),
                ),
              );
            },
          ),
        ],
      );
      expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);

      // "Hab ich": the picker shows the planned rice; the cook goes on to
      // the food search with "Etwas anderes suchen".
      await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
      await harness.idle(tester);
      expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
      expect(
        find.byKey(KochmodusItemPickerSheet.rowKey('rice')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(KochmodusItemPickerSheet.searchOtherKey));
      await harness.idle(tester);
      expect(find.byKey(_pickKey), findsOneWidget);
      expect(foodSearch!.heldItemIds, {'rice'});

      // The search finds a 1 kg pack for the 500 g of the line: the cook is
      // asked how much he takes, as after a pick from the Vorrat.
      await tester.tap(find.byKey(_pickKey));
      await harness.idle(tester);
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsNothing);
      for (final answer in KochmodusTakeAnswer.values) {
        expect(
          find.byKey(KochmodusTakeSheet.answerKey(answer)),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe)),
      );
      await harness.idle(tester);

      // The line takes from the new pack.
      expect(find.byKey(KochmodusEnteredCard.cardKey), findsOneWidget);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      final takes =
          (stored.lines.singleWhere((line) => line.id == 'a').settlement
                  as LineAssigned)
              .takes;
      expect(takes, hasLength(1));
      expect(takes.single.itemId, isNot('rice'));
      expect(takes.single.amount, 500);
      expect(
        harness.cook.inventory.items.where((item) => item.id == 'rice'),
        hasLength(1),
      );
      expect(
        harness.cook.inventory.items.map((item) => item.name),
        contains('Reis frisch'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
