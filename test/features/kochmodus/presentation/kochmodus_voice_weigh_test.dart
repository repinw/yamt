import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_to_weigh.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_type_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_voice_bar.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

final InventoryItem _oil = stockItem('oil', 500).copyWith(name: 'Öl');
final InventoryItem _rice = stockItem('rice', 800).copyWith(name: 'Reis');
final InventoryItem _onion = stockItem(
  'onion',
  6000,
  unit: InventoryAmountUnit.piece,
  scale: 1000,
  servingQuantity: 90,
  servingQuantityUnit: 'g',
).copyWith(name: 'Zwiebel');

final InventoryItem _tomato = packItem('tomato', 2).copyWith(name: 'Tomaten');

CookRun _run({bool guide = false, List<String> steps = const []}) {
  final run = buildCookRun(
    step: CookRunStep.cook,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    steps: steps,
    lines: [
      textLine('oil', '20 g Öl', settlement: assigned({'oil': 20})),
      textLine('rice', '200 g Reis', settlement: assigned({'rice': 200})),
      textLine('onion', '1 Zwiebel', settlement: assigned({'onion': 1000})),
      textLine('tomato', 'Tomaten', settlement: assigned({'tomato': 1})),
      textLine('salt', 'Salz', settlement: const LineIgnored()),
    ],
  );
  return guide ? run.useGuide(on: true) : run;
}

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.stock(tester, [_oil, _rice, _onion, _tomato]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  Future<void> listen(WidgetTester tester) async {
    await tester.tap(find.byKey(KochmodusVoiceBar.speakKey));
    await harness.idle(tester);
  }

  Future<void> say(WidgetTester tester, String said) async {
    harness.voice.say(said);
    await harness.idle(tester);
  }

  Future<CookRun> stored(WidgetTester tester) =>
      harness.storedRun(tester, 'recipe-t1');

  Future<List<CookRunLine>> added(WidgetTester tester) async => [
    for (final line in (await stored(tester)).lines)
      if (line.origin == CookLineOrigin.cooking) line,
  ];

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('a said weight', () {
    testWidgets('30 g Öl weighs the line and adds no line', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);
      await listen(tester);

      await say(tester, '30 g Öl');

      final run = await stored(tester);
      expect(run.lines, hasLength(5));
      expect(run.lineOf('oil')!.weighed, 30);
      expect(await added(tester), isEmpty);
      expect(find.text(l10n.kochmodusVoiceHeard('30 g Öl')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(KochmodusVoiceBar.weighedKey('oil')))
            .data,
        l10n.kochmodusCookLineSub('Öl', l10n.kochmodusWeightWeighed(30)),
      );
      await close(tester);
    });

    testWidgets('Öl 30 Gramm goes the same way', (tester) async {
      await open(tester, _run());
      await listen(tester);

      await say(tester, 'Öl 30 Gramm');

      expect((await stored(tester)).lineOf('oil')!.weighed, 30);
      expect(await added(tester), isEmpty);
      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsOneWidget);
      await close(tester);
    });

    testWidgets('1,5 kg Reis converts', (tester) async {
      await open(tester, _run());
      await listen(tester);

      await say(tester, '1,5 kg Reis');

      expect((await stored(tester)).lineOf('rice')!.weighed, 1500);
      await close(tester);
    });

    testWidgets('a second mention adds up and the feedback follows', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);
      await listen(tester);
      await say(tester, '30 g Öl');

      await say(tester, '10 g Öl');

      expect((await stored(tester)).lineOf('oil')!.weighed, 40);
      expect(
        tester
            .widget<Text>(find.byKey(KochmodusVoiceBar.weighedKey('oil')))
            .data,
        l10n.kochmodusCookLineSub('Öl', l10n.kochmodusWeightWeighed(40)),
      );
      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('what is heard next clears the old feedback', (tester) async {
      await open(tester, _run());
      await listen(tester);
      await say(tester, '30 g Öl');
      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsOneWidget);

      await say(tester, 'Zucker');

      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsNothing);
      await close(tester);
    });

    testWidgets('pieces, spoons and no amount stay new lines', (tester) async {
      await open(tester, _run());
      await listen(tester);

      await say(tester, '2 EL Öl');
      await say(tester, 'Öl');
      await say(tester, '2 Zwiebeln');

      expect((await added(tester)).map((line) => line.text), [
        '2 EL Öl',
        'Öl',
        '2 Zwiebeln',
      ]);
      final run = await stored(tester);
      expect(run.lineOf('oil')!.weighed, isNull);
      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsNothing);
      await close(tester);
    });

    testWidgets('an ignored line is not matched, a new line comes', (
      tester,
    ) async {
      await open(tester, _run());
      await listen(tester);

      await say(tester, '5 g Salz');

      expect((await added(tester)).map((line) => line.text), ['5 g Salz']);
      expect((await stored(tester)).lineOf('salt')!.weighed, isNull);
      await close(tester);
    });

    testWidgets('a part with a weight and a part without split', (
      tester,
    ) async {
      await open(tester, _run());
      await listen(tester);

      await say(tester, 'Pfeffer und 50 g Reis');

      final run = await stored(tester);
      expect(run.lineOf('rice')!.weighed, 50);
      expect((await added(tester)).map((line) => line.text), ['Pfeffer']);
      await close(tester);
    });

    testWidgets('a weighed line without weight drops off Noch zu wiegen', (
      tester,
    ) async {
      await open(tester, _run());
      await listen(tester);
      expect(find.byKey(KochmodusToWeigh.chipKey('tomato')), findsOneWidget);
      // An onion with a piece weight is only estimated: nothing to weigh.
      expect(find.byKey(KochmodusToWeigh.chipKey('onion')), findsNothing);

      await say(tester, '180 g Tomaten');

      expect((await stored(tester)).lineOf('tomato')!.weighed, 180);
      expect(find.byKey(KochmodusToWeigh.chipKey('tomato')), findsNothing);
      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('works in the guide too', (tester) async {
      await open(tester, _run(guide: true, steps: const ['Eins.', 'Zwei.']));
      await listen(tester);

      await say(tester, '30 g Öl');

      expect((await stored(tester)).lineOf('oil')!.weighed, 30);
      expect(await added(tester), isEmpty);
      await close(tester);
    });
  });

  group('nein after a weight', () {
    testWidgets('takes back the last action, whichever it was', (tester) async {
      await open(tester, _run());
      await listen(tester);
      await say(tester, '30 g Öl');
      await say(tester, '10 g Öl');
      await say(tester, 'Zucker');
      expect((await added(tester)).map((line) => line.text), ['Zucker']);

      await say(tester, 'nein');
      expect(await added(tester), isEmpty);
      expect((await stored(tester)).lineOf('oil')!.weighed, 40);

      await say(tester, 'nein');
      expect((await stored(tester)).lineOf('oil')!.weighed, 30);

      await say(tester, 'nein');
      var run = await stored(tester);
      expect(run.lineOf('oil')!.weighed, isNull);
      expect(
        (run.lineOf('oil')!.settlement as LineAssigned).takes.single.amount,
        20,
      );

      // Nothing left to undo.
      await say(tester, 'nein');
      run = await stored(tester);
      expect(run.lines, hasLength(5));
      expect(run.lineOf('oil')!.weighed, isNull);
      await close(tester);
    });

    testWidgets('a line with a weight and a new line come off one by one', (
      tester,
    ) async {
      await open(tester, _run());
      await listen(tester);
      await say(tester, 'Pfeffer und 50 g Reis');

      await say(tester, 'nein');
      final run = await stored(tester);
      expect(run.lineOf('rice')!.weighed, isNull);
      expect(await added(tester), hasLength(1));

      await say(tester, 'nein');
      expect(await added(tester), isEmpty);
      await close(tester);
    });

    testWidgets('puts a line back into Noch zu wiegen', (tester) async {
      await open(tester, _run());
      await listen(tester);
      await say(tester, '180 g Tomaten');
      expect(find.byKey(KochmodusToWeigh.chipKey('tomato')), findsNothing);

      await say(tester, 'nein');

      expect(find.byKey(KochmodusToWeigh.chipKey('tomato')), findsOneWidget);
      await close(tester);
    });
  });

  group('a typed weight', () {
    testWidgets('behaves like a said one', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
      await harness.idle(tester);
      await tester.enterText(
        find.byKey(KochmodusTypeSheet.fieldKey),
        '30 g Öl',
      );
      await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
      await harness.idle(tester);

      expect((await stored(tester)).lineOf('oil')!.weighed, 30);
      expect(await added(tester), isEmpty);
      expect(find.text(l10n.kochmodusVoiceTyped('30 g Öl')), findsOneWidget);
      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsOneWidget);
      await close(tester);
    });

    testWidgets('typed parts split into a weight and a new line', (
      tester,
    ) async {
      await open(tester, _run());

      await tester.tap(find.byKey(KochmodusVoiceBar.typeKey));
      await harness.idle(tester);
      await tester.enterText(
        find.byKey(KochmodusTypeSheet.fieldKey),
        '200 g Reis, Eier',
      );
      await tester.tap(find.byKey(KochmodusTypeSheet.addKey));
      await harness.idle(tester);

      expect((await stored(tester)).lineOf('rice')!.weighed, 200);
      expect((await added(tester)).map((line) => line.text), ['Eier']);
      await close(tester);
    });
  });

  group('the other commands stay', () {
    testWidgets('weiter and zurück move the step, Timer starts a timer', (
      tester,
    ) async {
      await open(
        tester,
        _run(guide: true, steps: const ['Eins.', 'Zwei.', 'Drei.']),
      );
      await listen(tester);

      await say(tester, 'weiter');
      expect((await stored(tester)).guideStep, 1);
      await say(tester, 'zurück');
      expect((await stored(tester)).guideStep, 0);
      await say(tester, 'Timer 5 Minuten');

      final run = await stored(tester);
      expect(run.timers, hasLength(1));
      expect(run.lines, hasLength(5));
      expect(find.byKey(KochmodusVoiceBar.weighedKey('oil')), findsNothing);
      await close(tester);
    });
  });
}
