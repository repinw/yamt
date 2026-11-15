import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/kitchen_utensil_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/kochmodus/presentation/kochmodus_cooking_harness.dart';
import '../../test/features/kochmodus/presentation/kochmodus_page_harness.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sets a recipe up from Zuweisen to the cooking page', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [utensil('pot-1', 'Topf')];
    addRecipe(
      harness,
      kochmodusRecipe(ingredients: ['500 g Hackfleisch', '200 g Karotten']),
    );
    await harness.stock(tester, [
      stockItem('mince', 800).copyWith(name: 'Hackfleisch'),
      stockItem('mince2', 800).copyWith(name: 'Hackfleisch Bio'),
      stockItem('rice', 500).copyWith(name: 'Reis'),
    ]);
    // Zuweisen of 5 portions: nothing is stored before the first change.
    await openPage(
      tester,
      harness,
      const KochmodusAssignPage(recipeId: 't1', portions: 5),
      routes: [
        GoRoute(
          path: AppRoutes.homeCookRun,
          builder: (context, state) =>
              KochmodusPage.run(runId: state.pathParameters['runId']!),
        ),
      ],
    );
    expect(
      await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
      isNull,
    );
    expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);
    // Lines are open: the card asks, "Kochen" is not there yet.
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);

    // Zuweisen: two foods are called Hackfleisch, so "Hab ich" asks which.
    await tester.tap(find.byKey(KochmodusCardAnswers.haveKey));
    await harness.idle(tester);
    expect(find.byKey(KochmodusItemPickerSheet.rowKey('mince')), findsOne);
    expect(find.byKey(KochmodusItemPickerSheet.rowKey('mince2')), findsOne);
    // Rice is no name match: it stands under "Alles im Vorrat", on the
    // same list.
    expect(find.byKey(KochmodusItemPickerSheet.suggestedKey), findsOne);
    expect(find.byKey(KochmodusItemPickerSheet.allKey), findsOne);
    expect(find.byKey(KochmodusItemPickerSheet.rowKey('rice')), findsOne);
    // The tapped food covers the 625 g, so the sheet closes with it; it holds
    // a bit more, so the cook is asked how much he takes.
    await tester.tap(find.byKey(KochmodusItemPickerSheet.rowKey('mince')));
    await harness.idle(tester);
    expect(find.byKey(KochmodusItemPickerSheet.keepKey), findsNothing);
    await tester.tap(
      find.byKey(KochmodusTakeSheet.answerKey(KochmodusTakeAnswer.recipe)),
    );
    await harness.idle(tester);

    // The cook wants 170 g, not the 625 g of the recipe.
    await tester.tap(find.byKey(KochmodusIngredientRow.rowKey('line-0')));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusIngredientCard.amountKey));
    await harness.idle(tester);
    await tester.enterText(find.byKey(KochmodusAmountSheet.fieldKey), '170');
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusAmountSheet.applyKey));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusIngredientCard.closeKey));
    await harness.idle(tester);
    // The carrots are left out.
    await tester.tap(find.byKey(KochmodusCardAnswers.ignoreKey));
    await harness.idle(tester);

    // Kochen replaces Zuweisen with the cooking page on Töpfe.
    await tester.tap(find.byKey(KochmodusReadyCard.mainKey));
    await harness.idle(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    expect(find.byType(KochmodusPage), findsOneWidget);
    expect(
      (await harness.storedRun(tester, 'recipe-t1')).step,
      CookRunStep.pots,
    );

    // Töpfe: the pot goes on to Kochen.
    await tester.tap(find.byKey(KochmodusPotsStep.potKey('pot-1')));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusPotsStep.nextKey));
    await harness.idle(tester);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);

    final run = await harness.storedRun(tester, 'recipe-t1');
    expect(run.portions, 5);
    expect(run.step, CookRunStep.cook);
    expect(run.lines[0].settlement, isA<LineAssigned>());
    expect(run.lines[0].amount, 170);
    final takes = (run.lines[0].settlement as LineAssigned).takes;
    expect(takes.single.itemId, 'mince');
    expect(takes.single.amount, 170);
    expect(run.lines[1].settlement, isA<LineIgnored>());
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a pot added on Töpfe is chosen and goes on to Kochen', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [utensil('pot-1', 'Topf')];
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.pots,
        lines: [
          textLine('line-0', '200 g Karotten', settlement: const LineIgnored()),
        ],
      ),
    );
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
    );
    final l10n = harness.l10n(tester);
    FilledButton next() =>
        tester.widget<FilledButton>(find.byKey(KochmodusPotsStep.nextKey));
    expect(next().onPressed, isNull);

    await tester.ensureVisible(find.byKey(KochmodusPotsStep.addKey));
    await tester.tap(find.byKey(KochmodusPotsStep.addKey));
    await harness.idle(tester);
    // The sheet is titled like the tile that opened it and hints at the
    // weight of the empty pot.
    Finder inSheet(String text) => find.descendant(
      of: find.byType(KitchenUtensilSheet),
      matching: find.text(text),
    );
    expect(inSheet(l10n.kochmodusPotsAdd), findsOneWidget);
    expect(inSheet(l10n.kitchenUtensilWeightHelper), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, l10n.kitchenUtensilNameLabel),
      'Wok',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.kitchenUtensilWeightLabel),
      '800',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.kitchenUtensilAddShort),
    );
    await harness.idle(tester);

    // The new pot is chosen without a tap on its tile.
    expect(next().onPressed, isNotNull);
    await tester.tap(find.byKey(KochmodusPotsStep.nextKey));
    await harness.idle(tester);

    final run = await harness.storedRun(tester, 'recipe-t1');
    expect(run.step, CookRunStep.cook);
    final pots = run.pots! as CookPotsChosen;
    expect(pots.pots.single.name, 'Wok');
    expect(pots.pots.single.emptyWeight, 800);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
