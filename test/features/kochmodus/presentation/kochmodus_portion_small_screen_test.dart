import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_estimates_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

final InventoryItem _flour = stockItem('flour', 1000);
final InventoryItem _eggs = stockItem(
  'eggs',
  3000,
  unit: InventoryAmountUnit.piece,
  scale: 1000,
  servingQuantity: 60,
  servingQuantityUnit: 'g',
);
final InventoryItem _carrot = stockItem('carrot', 500).copyWith(name: 'Möhre');

const _weighed = CookMealDraft(
  potId: 'pot-a',
  name: 'Eintopf',
  count: 4,
  inPieces: false,
  grossWeight: 1200,
);

CookRunLine _flour1() =>
    textLine('l-flour', '200 g Mehl', settlement: assigned({'flour': 200}));

CookRunLine _eggLine(String id) =>
    textLine(id, 'Eier', settlement: assigned({'eggs': 1000}));

// "1 Möhre" has no weight: it takes nothing until it is weighed.
CookRunLine _noWeight() =>
    textLine('l-carrot', '1 Möhre', settlement: assigned({'carrot': 0}));

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  step: CookRunStep.portion,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  meals: const [_weighed],
  lines: lines,
);

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
    await harness.stock(tester, [_flour, _eggs, _carrot]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id, width: width, textScale: textScale);
  }

  group('the page after cooking on 360x640', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('with a reason and an estimated line it fits at text scale '
          '$scale', (tester) async {
        await open(
          tester,
          _run([_flour1(), _eggLine('l-eggs'), cookedLine('new-1', 'Reis')]),
          width: 360,
          textScale: scale,
        );
        tester.view.physicalSize = const Size(360, 640);
        await harness.idle(tester);
        const screen = Rect.fromLTWH(0, 0, 360, 640);

        expect(tester.takeException(), isNull);
        final block = find.byKey(KochmodusPortionStep.blockKey);
        final toStock = find.byKey(KochmodusPortionStep.toStockKey);
        expect(block, findsOneWidget);
        expect(toStock, findsOneWidget);
        // The reason and the main button stay on the screen, the reason right
        // above the button.
        expect(screen.contains(tester.getTopLeft(block)), isTrue);
        expect(screen.contains(tester.getBottomRight(toStock)), isTrue);
        expect(
          tester.getBottomLeft(block).dy,
          lessThanOrEqualTo(tester.getTopLeft(toStock).dy),
        );
        // "Ansehen" is in the list now.
        final review = find.byKey(KochmodusPortionStep.reviewKey);
        await tester.scrollUntilVisible(
          review,
          200,
          scrollable: find
              .descendant(
                of: find.byType(KochmodusPortionStep),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(review, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the estimates sheet', () {
    Future<void> review(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(KochmodusPortionStep.reviewKey));
      await tester.tap(find.byKey(KochmodusPortionStep.reviewKey));
      await harness.idle(tester);
    }

    Finder inSheet(Finder finder) => find.descendant(
      of: find.byType(KochmodusEstimatesSheet),
      matching: finder,
    );

    testWidgets('lists the lines without a weight first under "Noch zu '
        'wiegen", then the estimates under a title that counts them', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _flour1(),
          _noWeight(),
          _eggLine('l-egg-a'),
          _eggLine('l-egg-b'),
        ]),
      );
      final l10n = harness.l10n(tester);

      await review(tester);

      final toWeigh = inSheet(find.text(l10n.kochmodusToWeigh));
      final estimated = inSheet(
        find.text(l10n.kochmodusEstimatedIngredients(2)),
      );
      expect(toWeigh, findsOneWidget);
      expect(estimated, findsOneWidget);
      expect(
        inSheet(find.text(l10n.kochmodusEstimatesMustWeigh)),
        findsOneWidget,
      );
      double top(Finder finder) => tester.getTopLeft(finder).dy;
      final carrot = find.byKey(KochmodusEstimatesSheet.changeKey('l-carrot'));
      final eggA = find.byKey(KochmodusEstimatesSheet.changeKey('l-egg-a'));
      final eggB = find.byKey(KochmodusEstimatesSheet.changeKey('l-egg-b'));
      expect(top(toWeigh), lessThan(top(carrot)));
      expect(top(carrot), lessThan(top(estimated)));
      // N is the number of rows under its title.
      expect(top(estimated), lessThan(top(eggA)));
      expect(top(estimated), lessThan(top(eggB)));
      expect(
        find.byKey(KochmodusEstimatesSheet.changeKey('l-flour')),
        findsNothing,
      );
    });

    testWidgets('with only estimates it has one title and the plain note', (
      tester,
    ) async {
      await open(tester, _run([_flour1(), _eggLine('l-egg-a')]));
      final l10n = harness.l10n(tester);

      await review(tester);

      expect(
        inSheet(find.text(l10n.kochmodusEstimatedIngredients(1))),
        findsOneWidget,
      );
      expect(inSheet(find.text(l10n.kochmodusToWeigh)), findsNothing);
      expect(inSheet(find.text(l10n.kochmodusEstimatesNote)), findsOneWidget);
      expect(
        inSheet(find.text(l10n.kochmodusEstimatesMustWeigh)),
        findsNothing,
      );
    });

    testWidgets('with only lines without a weight it has one title and says '
        'they are still to weigh', (tester) async {
      await open(tester, _run([_flour1(), _noWeight()]));
      final l10n = harness.l10n(tester);

      await review(tester);

      expect(inSheet(find.text(l10n.kochmodusToWeigh)), findsOneWidget);
      expect(inSheet(find.text(l10n.kochmodusToWeighNote)), findsOneWidget);
      expect(inSheet(find.textContaining('Bei ')), findsNothing);
      expect(
        find.byKey(KochmodusEstimatesSheet.changeKey('l-carrot')),
        findsOneWidget,
      );
    });
  });
}
