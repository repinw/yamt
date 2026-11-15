import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

// 3 pieces of 60 g, kept as a thousand per piece.
final InventoryItem _eggs = stockItem(
  'eggs',
  3000,
  unit: InventoryAmountUnit.piece,
  scale: 1000,
  servingQuantity: 60,
  servingQuantityUnit: 'g',
);
final InventoryItem _flour = stockItem('flour', 1000);
final InventoryItem _packs = packItem('packs', 2);

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  step: CookRunStep.cook,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: lines,
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.stock(tester, [_eggs, _flour, _packs]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  group('Kochen list', () {
    testWidgets('shows every line, a left-out one struck, a pinch plain', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine(
            'l-flour',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
          textLine('l-salt', 'Salz', settlement: const LineIgnored()),
          textLine('l-basil', 'Basilikum', settlement: const LineIgnored()),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(find.byKey(const ValueKey<String>('l-flour')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('l-salt')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('l-basil')), findsOneWidget);
      // Salt does not count; only the left-out line says "weggelassen".
      expect(find.text(l10n.kochmodusRowNotCounted), findsOneWidget);
      expect(find.text(l10n.kochmodusRowIgnored), findsOneWidget);
      final basil = tester.widget<Text>(find.text('Basilikum'));
      expect(basil.style?.decoration, TextDecoration.lineThrough);
      final salt = tester.widget<Text>(find.text('Salz'));
      expect(salt.style?.decoration, isNot(TextDecoration.lineThrough));
      final flour = tester.widget<Text>(find.textContaining('Mehl').first);
      expect(flour.style?.decoration, isNot(TextDecoration.lineThrough));
      // The ignored lines do not count.
      expect(find.text(l10n.kochmodusCookCount(1)), findsOneWidget);
      // Exact grams need no weighing.
      expect(find.byKey(KochmodusCookRow.weighKey('l-flour')), findsNothing);
      expect(find.byKey(KochmodusCookRow.weighKey('l-salt')), findsNothing);
    });

    testWidgets('a line whose food left the Vorrat says "Eintrag fehlt" and '
        'offers no weighing', (tester) async {
      await open(
        tester,
        _run([
          textLine(
            'l-gone',
            '300 g Reis',
            settlement: assigned({'ghost': 300}),
          ),
          textLine(
            'l-flour',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusEntryMissing), findsOneWidget);
      expect(find.byKey(KochmodusCookRow.weighKey('l-gone')), findsNothing);
      expect(find.text(l10n.kochmodusWeightMissing), findsNothing);
    });

    group('in German, a weight in the unit the food is kept in', () {
      Future<void> openGerman(
        WidgetTester tester,
        InventoryItem food,
        String text,
      ) async {
        await harness.stock(tester, [food]);
        final run = _run([
          textLine('l-x', text, settlement: assigned({food.id: 1000})),
        ]);
        await harness.store(tester, run);
        await harness.pumpRun(tester, run.id, locale: const Locale('de'));
      }

      testWidgets('1000 ml taken exactly from a food kept in ml ends with '
          '"1.000 ml"', (tester) async {
        final milk = stockItem(
          'milk',
          1000,
          unit: InventoryAmountUnit.milliliter,
        ).copyWith(name: 'Milch');
        await openGerman(tester, milk, '1 l Milch');
        final l10n = harness.l10n(tester);

        expect(
          find.text(l10n.kochmodusCookLineSub('Milch', '1.000\u00A0ml')),
          findsOneWidget,
        );
      });

      testWidgets('1000 g taken exactly from a food kept in g ends with '
          '"1.000 g"', (tester) async {
        final flour = stockItem('flour', 1000).copyWith(name: 'Mehl');
        await openGerman(tester, flour, '1000 g Mehl');
        final l10n = harness.l10n(tester);

        expect(
          find.text(l10n.kochmodusCookLineSub('Mehl', '1.000\u00A0g')),
          findsOneWidget,
        );
      });
    });

    testWidgets('names the recipe and its portions above the list', (
      tester,
    ) async {
      // Settled lines: a recipe run with an open line would send the page
      // back to "Zuweisen".
      await open(
        tester,
        _run([
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusRunKicker('Eintopf', 4).toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('a new line is dashed, says it is open and can be removed', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
          cookedLine('new-1', 'Reis'),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusCookNewOpen), findsOneWidget);
      expect(find.text(l10n.kochmodusCookCountAdded(2, 1)), findsOneWidget);
      expect(find.byKey(KochmodusCookRow.removeKey('l-flour')), findsNothing);

      await tester.tap(find.byKey(KochmodusCookRow.removeKey('new-1')));
      await harness.idle(tester);

      expect(find.text('Reis'), findsNothing);
      expect(find.text(l10n.kochmodusCookCount(1)), findsOneWidget);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lines.map((line) => line.id), ['l-flour']);
    });

    testWidgets('a change of the run does not send the page back to loading', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
          cookedLine('new-1', 'Reis'),
        ]),
      );
      final states = <AsyncValue<KochmodusView?>>[];
      harness.container.listen(
        kochmodusControllerProvider(const KochmodusTarget.run('recipe-t1')),
        (_, next) => states.add(next),
      );

      await tester.tap(find.byKey(KochmodusCookRow.removeKey('new-1')));
      await harness.idle(tester);

      // A loading state would replace the page, and with it what a widget
      // on it keeps, such as the line heard last.
      expect(states, isNotEmpty);
      expect(states.where((state) => state.isLoading), isEmpty);
    });

    testWidgets('an empty pot shows the hint to say what goes in', (
      tester,
    ) async {
      await open(tester, _run(const []));
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusCookEmptyTitle), findsOneWidget);
      expect(find.text(l10n.kochmodusCookEmptyHint), findsOneWidget);
    });
  });

  group('an estimated amount in the unit of its food', () {
    final oil = stockItem(
      'oil',
      500,
      unit: InventoryAmountUnit.milliliter,
    ).copyWith(name: 'Olivenöl');
    const tenMl = CookLineConversion(
      amountPerPiece: 10,
      unit: TemplateIngredientUnit.milliliter,
    );

    Future<void> openOil(WidgetTester tester, {required Locale locale}) async {
      final run = _run([
        textLine(
          'l-oil',
          '2 EL Öl',
          conversion: tenMl,
          settlement: assigned({'oil': 20}),
        ),
      ]);
      await harness.stock(tester, [oil]);
      await harness.store(tester, run);
      await harness.pumpRun(tester, run.id, locale: locale);
    }

    testWidgets('the cooking list says "≈ 20 ml estimated" for oil in ml', (
      tester,
    ) async {
      await openOil(tester, locale: const Locale('en'));

      expect(find.textContaining('≈ 20\u00A0ml estimated'), findsOneWidget);
      expect(find.textContaining('20\u00A0g'), findsNothing);
    });

    testWidgets('the cooking list says "≈ 20 ml geschätzt" in German', (
      tester,
    ) async {
      await openOil(tester, locale: const Locale('de'));

      expect(find.textContaining('≈ 20\u00A0ml geschätzt'), findsOneWidget);
    });
  });

  group('Wiegen', () {
    testWidgets('an estimated line offers Wiegen with the estimate as hint', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('l-eggs', 'Eier', settlement: assigned({'eggs': 2000})),
        ]),
      );
      final l10n = harness.l10n(tester);

      final estimated = l10n.kochmodusWeightEstimated(
        kochmodusWeightText(l10n, 120, _eggs),
      );
      expect(find.text(estimated), findsNothing);
      expect(find.textContaining(estimated), findsOneWidget);

      await tester.tap(find.byKey(KochmodusCookRow.weighKey('l-eggs')));
      await harness.idle(tester);

      // The sheet's sub line names the food and the recipe's estimate.
      expect(
        find.text(
          l10n.kochmodusCookLineSub(
            _eggs.name,
            l10n.kochmodusWeighRecipeEstimate(120),
          ),
        ),
        findsOneWidget,
      );
      // The hint key holds the estimate; the confirm button is off.
      expect(
        tester
            .widget<FilledButton>(find.byKey(KochmodusWeighSheet.confirmKey))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(KochmodusWeighSheet.hintKey));
      await tester.pump();
      expect(find.text(l10n.kochmodusWeighConfirm(120)), findsOneWidget);

      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(5)));
      await tester.pump();
      expect(find.text(l10n.kochmodusWeighConfirm(1205)), findsOneWidget);
    });

    testWidgets('weighing a missing weight stores it and offers Ändern', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('l-pack', 'Dose', settlement: assigned({'packs': 1})),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(find.textContaining(l10n.kochmodusWeightMissing), findsOneWidget);
      await tester.tap(find.byKey(KochmodusCookRow.weighKey('l-pack')));
      await harness.idle(tester);
      // No estimate to take.
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(
                of: find.byKey(KochmodusWeighSheet.hintKey),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );

      for (final digit in [4, 0, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(
        find.textContaining(l10n.kochmodusWeightWeighed(400)),
        findsOneWidget,
      );
      expect(find.text(l10n.kochmodusChange), findsOneWidget);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-pack')!.weighed, 400);
    });

    testWidgets('Wiegen changes a weighed line again', (tester) async {
      await open(
        tester,
        _run([
          textLine(
            'l-eggs',
            'Eier',
            settlement: assigned({'eggs': 2000}),
            weighed: 100,
          ),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(
        find.textContaining(l10n.kochmodusWeightWeighed(100)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(KochmodusCookRow.weighKey('l-eggs')));
      await harness.idle(tester);
      // The hint offers the weighed grams.
      await tester.tap(find.byKey(KochmodusWeighSheet.hintKey));
      await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(5)));
      await tester.pump();
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-eggs')!.weighed, 1005);
    });
  });

  group('actions', () {
    testWidgets('Fertig · Portionieren opens Portion and stores the step', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
        ]),
      );

      await tester.tap(find.byKey(KochmodusCookList.portionKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusCookList.portionKey), findsNothing);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.step, CookRunStep.portion);
    });
  });
  group('Kochen head at a large text', () {
    testWidgets('keeps room for the title: Timer is an icon, no overflow', (
      tester,
    ) async {
      final run = buildCookRun(
        step: CookRunStep.cook,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const ['Rühren.'],
        lines: [
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
        ],
      );
      await harness.stock(tester, [_flour]);
      await harness.store(tester, run);

      await harness.pumpRun(
        tester,
        run.id,
        width: 360,
        textScale: 2,
        locale: const Locale('de'),
      );
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusCookList.guideKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(KochmodusCookList.timerKey),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget(find.byKey(KochmodusCookList.timerKey)),
        isA<IconButton>(),
      );
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(KochmodusCookList),
                matching: find.text(l10n.cookStepCooking),
              ),
            )
            .width,
        greaterThanOrEqualTo(150),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at normal text Timer stays a labelled button', (tester) async {
      final run = buildCookRun(
        step: CookRunStep.cook,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        steps: const ['Rühren.'],
        lines: [
          textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
        ],
      );
      await harness.stock(tester, [_flour]);
      await harness.store(tester, run);

      await harness.pumpRun(tester, run.id);

      expect(
        tester.widget(find.byKey(KochmodusCookList.timerKey)),
        isNot(isA<IconButton>()),
      );
    });
  });
}
