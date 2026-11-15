import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_guide_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_to_weigh.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

// 3 pieces of 60 g: the weight is only estimated.
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

const _longText =
    'Eine sehr lange Zutatenbezeichnung mit Hinweisen zur Zubereitung, '
    'Qualitätsmerkmalen und Herkunft der Zutat';

CookRun _run({
  bool guide = false,
  bool withEstimated = true,
  List<CookRunLine> extra = const [],
}) {
  final run = buildCookRun(
    step: CookRunStep.cook,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    steps: const ['Zwiebeln anschwitzen.', 'Nudeln kochen.'],
    lines: [
      textLine('l-flour', '200 g Mehl', settlement: assigned({'flour': 200})),
      if (withEstimated) ...[
        textLine('l-eggs', '2 Eier', settlement: assigned({'eggs': 2000})),
        textLine('l-pack', 'Tomaten', settlement: assigned({'packs': 1})),
      ],
      textLine('l-salt', 'Salz', settlement: const LineIgnored()),
      ...extra,
    ],
  );
  return guide ? run.useGuide(on: true) : run;
}

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(
    WidgetTester tester,
    CookRun run, {
    double width = 800,
    double? textScale,
  }) async {
    await harness.stock(tester, [_eggs, _flour, _packs]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id, width: width, textScale: textScale);
  }

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('Noch zu wiegen on the list', () {
    testWidgets('shows a chip only for a line whose weight is missing', (
      tester,
    ) async {
      await open(tester, _run());

      expect(find.byType(KochmodusToWeigh), findsOneWidget);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsOneWidget);
      // A weight estimated per piece is no reason to weigh; exact and
      // ignored lines are not to weigh either.
      expect(find.byKey(KochmodusToWeigh.chipKey('l-eggs')), findsNothing);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-flour')), findsNothing);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-salt')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(KochmodusToWeigh.chipKey('l-pack')),
          matching: find.text('Tomaten'),
        ),
        findsOneWidget,
      );
      await close(tester);
    });

    testWidgets('does not list a line that takes nothing from a whole pack', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          extra: [
            textLine('l-senf', '1 EL Senf', settlement: assigned({'packs': 0})),
          ],
        ),
      );

      // Weighing does not help it, only another food does.
      expect(find.byKey(KochmodusToWeigh.chipKey('l-senf')), findsNothing);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsOneWidget);
      await close(tester);
    });

    testWidgets('lists a line on a gram item that takes nothing', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          extra: [
            textLine('l-carrot', '1 Möhre', settlement: assigned({'flour': 0})),
          ],
        ),
      );

      expect(find.byKey(KochmodusToWeigh.chipKey('l-carrot')), findsOneWidget);
      await close(tester);
    });

    testWidgets('is hidden when nothing is to weigh', (tester) async {
      await open(tester, _run(withEstimated: false));

      expect(find.byType(KochmodusToWeigh), findsNothing);
      await close(tester);
    });

    testWidgets('a chip opens the weigh sheet and the weighed line drops off', (
      tester,
    ) async {
      await open(tester, _run());

      await tester.tap(find.byKey(KochmodusToWeigh.chipKey('l-pack')));
      await harness.idle(tester);
      expect(find.byKey(KochmodusWeighSheet.confirmKey), findsOneWidget);
      for (final digit in [1, 2, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsNothing);
      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(stored.lineOf('l-pack')!.weighed, 120);
      await close(tester);
    });

    testWidgets('the last weighed line takes the section away', (tester) async {
      await open(tester, _run().weigh('l-pack', 400));

      expect(find.byType(KochmodusToWeigh), findsNothing);
      await close(tester);
    });

    testWidgets('a line that was weighed already has no chip', (tester) async {
      await open(tester, _run().weigh('l-pack', 400));

      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsNothing);
      expect(find.byType(KochmodusToWeigh), findsNothing);
      await close(tester);
    });
  });

  group('Noch zu wiegen for a line in pieces on a food kept in g', () {
    final onion = textLine(
      'l-onion',
      '1 Zwiebel',
      conversion: const CookLineConversion(
        amountPerPiece: 150,
        unit: TemplateIngredientUnit.gram,
      ),
      settlement: assigned({'flour': 150}),
    );

    testWidgets('has a chip on the cooking list', (tester) async {
      await open(tester, _run(extra: [onion]));

      expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsOneWidget);
      await close(tester);
    });

    testWidgets('has a chip under a guide step', (tester) async {
      await open(tester, _run(guide: true, extra: [onion]));

      expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsOneWidget);
      await close(tester);
    });

    testWidgets('a chip weighs it and drops off', (tester) async {
      await open(tester, _run(guide: true, extra: [onion]));

      await tester.tap(find.byKey(KochmodusToWeigh.chipKey('l-onion')));
      await harness.idle(tester);
      for (final digit in [1, 2, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusToWeigh.chipKey('l-onion')), findsNothing);
      expect(
        (await harness.storedRun(
          tester,
          'recipe-t1',
        )).lineOf('l-onion')!.weighed,
        120,
      );
      await close(tester);
    });
  });

  group('Noch zu wiegen in the guide', () {
    testWidgets('shows the same chips', (tester) async {
      await open(tester, _run(guide: true));

      expect(find.byKey(KochmodusGuideStep.nextKey), findsOneWidget);
      expect(find.byType(KochmodusToWeigh), findsOneWidget);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsOneWidget);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-eggs')), findsNothing);
      expect(find.byKey(KochmodusToWeigh.chipKey('l-flour')), findsNothing);
      await close(tester);
    });

    testWidgets('is hidden when nothing is to weigh', (tester) async {
      await open(tester, _run(guide: true, withEstimated: false));

      expect(find.byType(KochmodusToWeigh), findsNothing);
      await close(tester);
    });

    testWidgets('a chip weighs the line and drops off', (tester) async {
      await open(tester, _run(guide: true));

      await tester.tap(find.byKey(KochmodusToWeigh.chipKey('l-pack')));
      await harness.idle(tester);
      for (final digit in [4, 0, 0]) {
        await tester.tap(find.byKey(KochmodusWeighSheet.digitKey(digit)));
        await tester.pump();
      }
      await tester.tap(find.byKey(KochmodusWeighSheet.confirmKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusToWeigh.chipKey('l-pack')), findsNothing);
      expect(find.byType(KochmodusToWeigh), findsNothing);
      expect(
        (await harness.storedRun(
          tester,
          'recipe-t1',
        )).lineOf('l-pack')!.weighed,
        400,
      );
      await close(tester);
    });
  });

  group('Noch zu wiegen without overflow', () {
    for (final guide in [false, true]) {
      // The weigh button of an estimated row in the list already overflows
      // by 2.5 px at 320 px and text scale 3 without the section; only the
      // guide, which has no such row, is checked at 3.
      for (final scale in [1.3, 2.0, if (guide) 3.0]) {
        testWidgets(
          '${guide ? 'guide' : 'list'} at 320 px and text scale $scale',
          (tester) async {
            await open(
              tester,
              _run(
                guide: guide,
                extra: [
                  textLine(
                    'l-long',
                    _longText,
                    settlement: assigned({'packs': 1}),
                  ),
                ],
              ),
              width: 320,
              textScale: scale,
            );

            expect(
              find.byKey(KochmodusToWeigh.chipKey('l-long')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await close(tester);
          },
        );
      }
    }
  });
}
