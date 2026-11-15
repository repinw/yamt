import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_counted_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pot_tile.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_bar.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    harness.utensils.utensils = [
      utensil('pot-1', 'Topf'),
      utensil('pot-2', 'Pfanne', weight: 700),
    ];
  });

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await harness.idle(tester);
  }

  Future<CookRun?> stored(WidgetTester tester, String id) async =>
      await tester.runAsync<CookRun?>(() => harness.cook.storedRun(id));

  group('"Töpfe"', () {
    // The cooking page of a recipe whose lines are settled, before it chose
    // its pots.
    Future<void> openPots(WidgetTester tester) async {
      await harness.store(
        tester,
        buildCookRun(
          step: CookRunStep.pots,
          lines: [
            textLine(
              'line-0',
              '500 g Hackfleisch',
              settlement: const LineIgnored(),
            ),
            textLine(
              'line-1',
              '200 g Karotten',
              settlement: const LineIgnored(),
            ),
          ],
        ),
      );
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
      );
    }

    bool nextOn(WidgetTester tester) =>
        tester
            .widget<FilledButton>(find.byKey(KochmodusPotsStep.nextKey))
            .onPressed !=
        null;

    testWidgets('"Weiter" waits for a pot or "Ohne Topf"', (tester) async {
      await openPots(tester);
      final l10n = harness.l10n(tester);

      expect(nextOn(tester), isFalse);
      expect(find.text(l10n.kochmodusPotsTitle), findsOneWidget);
      expect(find.text(l10n.kochmodusPotsLead), findsOneWidget);
      // Nothing chosen: the hint above the button, no result line yet.
      expect(find.text(l10n.kochmodusPotsChooseHint), findsOneWidget);
      expect(find.text(l10n.kochmodusPotsResultLabel), findsNothing);
      expect(find.byKey(KochmodusPotsStep.potKey('pot-1')), findsOneWidget);
      expect(find.byKey(KochmodusPotsStep.potKey('pot-2')), findsOneWidget);
      expect(find.byKey(KochmodusPotsStep.addKey), findsOneWidget);

      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      expect(nextOn(tester), isTrue);
      expect(find.text(l10n.kochmodusPotsResultLabel), findsOneWidget);
      expect(find.text(l10n.kochmodusPotsResultTogether('Topf')), findsOne);
      expect(find.text(l10n.kochmodusPotsChooseHint), findsNothing);

      // Tapping the pot again takes it back.
      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      expect(nextOn(tester), isFalse);
      expect(find.text(l10n.kochmodusPotsResultLabel), findsNothing);
      expect(find.text(l10n.kochmodusPotsChooseHint), findsOneWidget);
    });

    testWidgets('one pot is stored and opens "Kochen"', (tester) async {
      await openPots(tester);

      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      await tap(tester, KochmodusPotsStep.nextKey);

      final run = (await stored(tester, 'recipe-t1'))!;
      expect(run.step, CookRunStep.cook);
      expect(run.pots, isA<CookPotsChosen>());
      final pots = run.pots! as CookPotsChosen;
      expect(pots.pots.map((pot) => pot.id), ['pot-1']);
      expect(pots.pots.single.emptyWeight, 900);
      expect(pots.inCans, isFalse);
      expect(run.lines.map((line) => line.id), ['line-0', 'line-1']);
      expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);
      expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    });

    testWidgets('several pots keep the order they were picked in', (
      tester,
    ) async {
      await openPots(tester);
      final l10n = harness.l10n(tester);

      await tap(tester, KochmodusPotsStep.potKey('pot-2'));
      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      expect(find.text(l10n.kochmodusPotsResultSeparate(2)), findsOneWidget);
      await tap(tester, KochmodusPotsStep.nextKey);

      final pots = (await stored(tester, 'recipe-t1'))!.pots! as CookPotsChosen;
      expect(pots.pots.map((pot) => pot.id), ['pot-2', 'pot-1']);
    });

    testWidgets('the add sheet is titled like the tile and hints at the '
        'weight', (tester) async {
      await openPots(tester);
      final l10n = harness.l10n(tester);

      await tester.ensureVisible(find.byKey(KochmodusPotsStep.addKey));
      await tap(tester, KochmodusPotsStep.addKey);

      Finder inSheet(String text) => find.descendant(
        of: find.byType(KitchenUtensilSheet),
        matching: find.text(text),
      );
      expect(inSheet(l10n.kochmodusPotsAdd), findsOneWidget);
      expect(inSheet(l10n.kitchenUtensilAddTitle), findsNothing);
      expect(inSheet(l10n.kitchenUtensilWeightHelper), findsOneWidget);
    });

    group('a pot added here', () {
      // Adds a pot through the sheet and returns its id.
      Future<String> addPot(WidgetTester tester) async {
        final l10n = harness.l10n(tester);
        final known = {
          for (final utensil in harness.utensils.utensils) utensil.id,
        };
        await tester.ensureVisible(find.byKey(KochmodusPotsStep.addKey));
        await tap(tester, KochmodusPotsStep.addKey);
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
        return harness.utensils.utensils
            .firstWhere((utensil) => !known.contains(utensil.id))
            .id;
      }

      bool chosen(WidgetTester tester, String id) => tester
          .widget<KochmodusPotTile>(find.byKey(KochmodusPotsStep.potKey(id)))
          .selected;

      testWidgets('is chosen and "Weiter" is on', (tester) async {
        await openPots(tester);
        final l10n = harness.l10n(tester);
        expect(nextOn(tester), isFalse);

        final id = await addPot(tester);

        expect(chosen(tester, id), isTrue);
        expect(nextOn(tester), isTrue);
        expect(find.text(l10n.kochmodusPotsResultTogether('Wok')), findsOne);
      });

      testWidgets('is chosen next to a pot that is chosen already', (
        tester,
      ) async {
        await openPots(tester);
        final l10n = harness.l10n(tester);
        await tap(tester, KochmodusPotsStep.potKey('pot-1'));

        final id = await addPot(tester);

        expect(chosen(tester, 'pot-1'), isTrue);
        expect(chosen(tester, id), isTrue);
        expect(find.text(l10n.kochmodusPotsResultSeparate(2)), findsOne);
      });

      testWidgets('is chosen and takes "Ohne Topf" off', (tester) async {
        await openPots(tester);
        final l10n = harness.l10n(tester);
        await tester.ensureVisible(find.byKey(KochmodusCountedRow.tileKey));
        await tap(tester, KochmodusCountedRow.tileKey);
        expect(find.text(l10n.kochmodusPotsResultCounted), findsOneWidget);

        final id = await addPot(tester);

        expect(chosen(tester, id), isTrue);
        expect(find.text(l10n.kochmodusPotsResultCounted), findsNothing);
        expect(find.text(l10n.kochmodusPotsResultTogether('Wok')), findsOne);
      });

      testWidgets('is stored with the run on "Weiter"', (tester) async {
        await openPots(tester);
        final id = await addPot(tester);

        await tap(tester, KochmodusPotsStep.nextKey);

        final pots =
            (await stored(tester, 'recipe-t1'))!.pots! as CookPotsChosen;
        expect(pots.pots.map((pot) => pot.id), [id]);
        expect(pots.pots.single.emptyWeight, 800);
      });

      testWidgets('is not chosen any more after the undo of adding it', (
        tester,
      ) async {
        await openPots(tester);
        final l10n = harness.l10n(tester);
        final id = await addPot(tester);
        expect(nextOn(tester), isTrue);

        await tester.tap(find.text(l10n.commonUndoAction));
        await harness.idle(tester);

        expect(find.byKey(KochmodusPotsStep.potKey(id)), findsNothing);
        expect(nextOn(tester), isFalse);
        expect(find.text(l10n.kochmodusPotsResultLabel), findsNothing);
      });

      testWidgets('is not added when the cook closes the sheet', (
        tester,
      ) async {
        await openPots(tester);
        await tester.ensureVisible(find.byKey(KochmodusPotsStep.addKey));
        await tap(tester, KochmodusPotsStep.addKey);

        await tester.tapAt(const Offset(10, 10));
        await harness.idle(tester);

        expect(harness.utensils.utensils, hasLength(2));
        expect(nextOn(tester), isFalse);
      });
    });

    testWidgets('"Danach in Dosen" is stored with the pots', (tester) async {
      await openPots(tester);
      final l10n = harness.l10n(tester);

      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      await tester.ensureVisible(find.byKey(KochmodusPotsStep.cansKey));
      await tap(tester, KochmodusPotsStep.cansKey);
      expect(find.text(l10n.kochmodusPotsResultTogetherCans), findsOneWidget);
      await tap(tester, KochmodusPotsStep.nextKey);

      final pots = (await stored(tester, 'recipe-t1'))!.pots! as CookPotsChosen;
      expect(pots.inCans, isTrue);
    });

    testWidgets('"Ohne Topf" unpicks the pots and turns the cans off', (
      tester,
    ) async {
      await openPots(tester);
      final l10n = harness.l10n(tester);

      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      await tester.ensureVisible(find.byKey(KochmodusCountedRow.tileKey));
      await tap(tester, KochmodusCountedRow.tileKey);

      expect(find.text(l10n.kochmodusPotsResultCounted), findsOneWidget);
      final cans = tester.widget<AppSwitchListTile>(
        find.byKey(KochmodusPotsStep.cansKey),
      );
      expect(cans.onChanged, isNull);
      expect(nextOn(tester), isTrue);

      await tap(tester, KochmodusPotsStep.nextKey);

      final run = (await stored(tester, 'recipe-t1'))!;
      expect(run.pots, isA<CookCounted>());
      expect(run.step, CookRunStep.cook);
    });

    testWidgets('free cooking goes on to "Kochen" too', (tester) async {
      await openPage(tester, harness, const KochmodusPage.free());
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusPotsNextCook), findsOneWidget);
      await tap(tester, KochmodusPotsStep.potKey('pot-1'));
      await tap(tester, KochmodusPotsStep.nextKey);

      expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);
      expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    });

    testWidgets('a stored run starts from its pots', (tester) async {
      await harness.store(
        tester,
        buildCookRun(
          step: CookRunStep.cook,
          lines: [textLine('line-0', 'Salz', settlement: const LineIgnored())],
          pots: CookPotsChosen(
            pots: const [
              CookPot(
                id: 'pot-2',
                name: 'Pfanne',
                emptyWeight: 700,
                imageStoragePath: null,
              ),
            ],
            inCans: true,
          ),
        ),
      );
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
      );
      await tap(tester, KochmodusStepBar.tabKey(KochmodusStep.pots));
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusPotsResultTogetherCans), findsOneWidget);
      expect(nextOn(tester), isTrue);
    });
  });
}
