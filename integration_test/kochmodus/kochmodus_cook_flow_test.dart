import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_done_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_guide_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_line.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_lines.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foods.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_to_weigh.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../test/features/kochmodus/kochmodus_fixtures.dart';
import '../../test/features/kochmodus/presentation/kochmodus_cooking_harness.dart';
import '../../test/features/recipes/cook_run_fixtures.dart';

CookRun _run({bool guide = false}) {
  final run = buildCookRun(
    step: CookRunStep.cook,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    steps: const [
      'Zwiebeln und Mehl anschwitzen.',
      'Nudeln 8-10 Minuten kochen.',
    ],
    lines: [
      textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
    ],
  );
  return guide ? run.useGuide(on: true) : run;
}

bool _toStockEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.byKey(KochmodusPortionStep.toStockKey))
        .onPressed !=
    null;

// The pot with the food on the scale: 1200 g, from the pot's field or, with
// [fromMainButton], from the main button that says "Topf wiegen".
Future<void> _weighPot(
  WidgetTester tester,
  KochmodusCookingHarness harness, {
  bool fromMainButton = false,
}) async {
  await tester.tap(
    find.byKey(
      fromMainButton
          ? KochmodusPortionStep.toStockKey
          : KochmodusMealBox.weighKey(cookPotA.id),
    ),
  );
  await harness.idle(tester);
  for (final digit in [1, 2, 0, 0]) {
    await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
    await tester.pump();
  }
  await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
  await harness.idle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cooks from the list to Fertig', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [stockItem('flour', 1000)]);
    await harness.store(tester, _run());
    await harness.pumpRun(tester, 'recipe-t1');
    expect(find.byType(KochmodusPage), findsOneWidget);

    // A timer from the sheet.
    await tester.tap(find.byKey(KochmodusCookList.timerKey));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(0)));
    await harness.idle(tester);
    final timerId = (await harness.storedRun(
      tester,
      'recipe-t1',
    )).timers.single.id;
    expect(find.byKey(KochmodusTimerBar.stopKey(timerId)), findsOneWidget);

    // An ingredient typed in, the timer stopped.
    await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
    await harness.idle(tester);
    await tester.enterText(find.byKey(KochmodusTypeSheet.fieldKey), 'Salz');
    await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
    await harness.idle(tester);
    expect(find.text('Salz'), findsOneWidget);
    await tester.tap(find.byKey(KochmodusTimerBar.stopKey(timerId)));
    await harness.idle(tester);
    expect(find.byKey(KochmodusTimerBar.stopKey(timerId)), findsNothing);

    // Portion: In Vorrat waits for the pot's weight, then for the new line.
    await tester.tap(find.byKey(KochmodusCookList.portionKey));
    await harness.idle(tester);
    final l10n = harness.l10n(tester);
    // The main button weighs the pot first.
    expect(
      find.descendant(
        of: find.byKey(KochmodusPortionStep.toStockKey),
        matching: find.text(l10n.kochmodusWeighPotsAction(1)),
      ),
      findsOneWidget,
    );
    await _weighPot(tester, harness, fromMainButton: true);
    expect(_toStockEnabled(tester), isFalse);
    await tester.tap(find.byKey(KochmodusPortionLines.takeNewKey));
    await harness.idle(tester);
    await tester.tap(
      find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
    );
    await harness.idle(tester);
    expect(_toStockEnabled(tester), isTrue);

    await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
    await harness.idle(tester);
    expect(find.byType(KochmodusDoneView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a chip and a said weight take lines off Noch zu wiegen', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    // Packs have no known weight: only the cook's weight settles them.
    InventoryItem piece(String id, String name) =>
        packItem(id, 2).copyWith(name: name);
    await harness.stock(tester, [
      stockItem('flour', 1000),
      piece('onion', 'Zwiebel'),
      piece('pepper', 'Paprika'),
    ]);
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.cook,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const [],
        lines: [
          textLine(
            'l-flour',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
          textLine('l-onion', '1 Zwiebel', settlement: assigned({'onion': 1})),
          textLine(
            'l-pepper',
            '1 Paprika',
            settlement: assigned({'pepper': 1}),
          ),
        ],
      ),
    );
    await harness.pumpRun(tester, 'recipe-t1');
    expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsOneWidget);
    expect(find.byKey(KochmodusToWeigh.chipKey('l-pepper')), findsOneWidget);

    // The chip opens the keypad: 120 g of Paprika.
    await tester.tap(find.byKey(KochmodusToWeigh.chipKey('l-pepper')));
    await harness.idle(tester);
    for (final digit in [1, 2, 0]) {
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
      await tester.pump();
    }
    await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
    await harness.idle(tester);
    expect(find.byKey(KochmodusToWeigh.chipKey('l-pepper')), findsNothing);
    expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsOneWidget);

    // A typed weight counts for the line, adds no line and drops it off.
    await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
    await harness.idle(tester);
    await tester.enterText(
      find.byKey(KochmodusTypeSheet.fieldKey),
      '180 g Zwiebel',
    );
    await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
    await harness.idle(tester);

    expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsNothing);
    expect(find.byType(KochmodusToWeigh), findsNothing);
    expect(find.text('180 g Zwiebel'), findsNothing);
    final stored = await harness.storedRun(tester, 'recipe-t1');
    expect(stored.lines, hasLength(3));
    expect(stored.lineOf('l-pepper')!.weighed, 120);
    expect(stored.lineOf('l-onion')!.weighed, 180);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a piece line on Portion is weighed, then In Vorrat goes', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    // "1 Zwiebel" on an item kept in grams has no piece weight: it takes
    // nothing until the cook weighs it.
    await harness.stock(tester, [
      stockItem('flour', 1000),
      stockItem('onion', 1000),
    ]);
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.portion,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const [],
        lines: [
          textLine(
            'l-flour',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
          textLine('l-onion', '1 Zwiebel', settlement: assigned({'onion': 0})),
        ],
      ),
    );
    await harness.pumpRun(tester, 'recipe-t1');
    await _weighPot(tester, harness);
    expect(_toStockEnabled(tester), isFalse);

    await tester.ensureVisible(
      find.byKey(KochmodusPortionLine.editKey('l-onion')),
    );
    await tester.tap(find.byKey(KochmodusPortionLine.editKey('l-onion')));
    await harness.idle(tester);
    for (final digit in [8, 0]) {
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
      await tester.pump();
    }
    await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
    await harness.idle(tester);

    expect(_toStockEnabled(tester), isTrue);
    await tester.ensureVisible(find.byKey(KochmodusPortionStep.toStockKey));
    await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
    await harness.idle(tester);

    expect(find.byType(KochmodusDoneView), findsOneWidget);
    final onion = await tester.runAsync(() => harness.cook.storedItem('onion'));
    expect(onion!.currentAmount, 920);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a line removed on Portion comes back with Rückgängig', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [
      stockItem('flour', 1000),
      stockItem('onion', 1000),
      packItem('pack', 2),
    ]);
    await harness.store(
      tester,
      buildCookRun(
        step: CookRunStep.portion,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const [],
        lines: [
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
          textLine(
            'l-onion',
            '1 Zwiebel',
            settlement: assigned({'onion': 80}),
            weighed: 80,
          ),
          textLine('l-senf', '1 EL Senf', settlement: assigned({'pack': 0})),
        ],
      ),
    );
    await harness.pumpRun(tester, 'recipe-t1');
    await _weighPot(tester, harness);
    // A line on a whole pack is told to pick another food, not to weigh.
    expect(_toStockEnabled(tester), isFalse);
    final l10n = harness.l10n(tester);
    expect(
      tester.widget<Text>(find.byKey(KochmodusPortionStep.blockKey)).data,
      l10n.kochmodusBlockOtherFood('1 EL Senf'),
    );

    await tester.ensureVisible(
      find.byKey(KochmodusPortionLine.removeKey('l-senf')),
    );
    await tester.tap(find.byKey(KochmodusPortionLine.removeKey('l-senf')));
    await harness.idle(tester);
    expect(_toStockEnabled(tester), isTrue);

    await tester.ensureVisible(
      find.byKey(KochmodusPortionLine.removeKey('l-onion')),
    );
    await tester.tap(find.byKey(KochmodusPortionLine.removeKey('l-onion')));
    await harness.idle(tester);
    expect(find.byKey(KochmodusActionFlow.lineRemovedKey), findsOneWidget);
    await tester.tap(find.text(l10n.commonUndoAction));
    await harness.idle(tester);

    final onion = (await harness.storedRun(
      tester,
      'recipe-t1',
    )).lineOf('l-onion')!;
    expect(onion.weighed, 80);
    expect((onion.settlement as LineAssigned).takes.single.amount, 80);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cooks with the guide up to Fertig', (tester) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [stockItem('flour', 1000)]);
    await harness.store(tester, _run(guide: true));
    await harness.pumpRun(tester, 'recipe-t1');

    // The first step names the flour and says how much it takes.
    expect(find.byKey(KochmodusStepFoods.blockKey), findsOneWidget);
    expect(find.byKey(KochmodusStepFoods.rowKey('l-flour')), findsOneWidget);
    await tester.tap(find.byKey(KochmodusGuideStep.nextKey));
    await harness.idle(tester);
    expect(find.byKey(KochmodusStepFoods.blockKey), findsNothing);
    await tester.tap(find.byKey(KochmodusGuideStep.portionKey));
    await harness.idle(tester);
    await _weighPot(tester, harness);
    final l10n = harness.l10n(tester);
    expect(
      find.descendant(
        of: find.byKey(KochmodusPortionStep.toStockKey),
        matching: find.text(l10n.cookToStock),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
    await harness.idle(tester);

    expect(find.byType(KochmodusDoneView), findsOneWidget);
    await tester.tap(find.byKey(KochmodusDoneView.cookbookKey));
    await harness.idle(tester);
    expect(find.byType(KochmodusPage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a meal name typed with the keyboard open lands in the Vorrat', (
    tester,
  ) async {
    final harness = await KochmodusCookingHarness.open();
    await harness.stock(tester, [stockItem('flour', 1000)]);
    await harness.store(tester, _run());
    await harness.pumpRun(tester, 'recipe-t1');
    await tester.tap(find.byKey(KochmodusCookList.portionKey));
    await harness.idle(tester);
    await _weighPot(tester, harness);

    // The keyboard stays open: no "done", only the tap on In Vorrat.
    await tester.enterText(
      find.byKey(KochmodusMealBox.nameKey(cookPotA.id)),
      'Gulasch',
    );
    await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
    await harness.idle(tester);

    expect(find.byType(KochmodusDoneView), findsOneWidget);
    final meal = await tester.runAsync(
      () => harness.cook.storedMeal('${buildCookRun().cookingId}-pot-a'),
    );
    expect(meal!.name, 'Gulasch');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
