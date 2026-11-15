import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _potA = 'pot-a';

// Pot A, empty 900 g, weighed at [gross] with the food in [count] parts.
CookRun _run({
  required bool inCans,
  int? gross = 1900,
  int count = 4,
  bool inPieces = false,
}) => buildCookRun(
  step: CookRunStep.portion,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: inCans),
  steps: const [],
  meals: [
    CookMealDraft(
      potId: _potA,
      name: 'Chili',
      count: count,
      inPieces: inPieces,
      grossWeight: gross,
    ),
  ],
  lines: [
    textLine('l-flour', '200 g Mehl', settlement: assigned({'flour': 200})),
  ],
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.stock(tester, [stockItem('flour', 1000)]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  Finder perCount() => find.byKey(KochmodusMealBox.perCountKey(_potA));

  testWidgets('a weighed pot in cans says how much goes into each', (
    tester,
  ) async {
    await open(tester, _run(inCans: true));

    expect(
      find.text(harness.l10n(tester).kochmodusMealPerCount('can', 250)),
      findsOneWidget,
    );
  });

  testWidgets('in portions it says how much each portion is, rounded', (
    tester,
  ) async {
    await open(tester, _run(inCans: false, count: 3));

    expect(
      find.text(harness.l10n(tester).kochmodusMealPerCount('portion', 333)),
      findsOneWidget,
    );
  });

  testWidgets('nothing before the pot is weighed', (tester) async {
    await open(tester, _run(inCans: true, gross: null));

    expect(perCount(), findsNothing);
  });

  testWidgets('nothing for a meal in pieces', (tester) async {
    await open(tester, _run(inCans: true, inPieces: true));

    expect(perCount(), findsNothing);
  });

  testWidgets('without a pot it says roughly how much each portion is, from '
      'the ingredients', (tester) async {
    await open(
      tester,
      buildCookRun(
        step: CookRunStep.portion,
        pots: const CookCounted(),
        steps: const [],
        meals: const [
          CookMealDraft(
            potId: countedMealPotId,
            name: 'Chili',
            count: 4,
            inPieces: false,
            grossWeight: null,
          ),
        ],
        lines: [
          textLine(
            'l-flour',
            '200 g Mehl',
            settlement: assigned({'flour': 200}),
          ),
        ],
      ),
    );

    expect(
      find.text(
        harness.l10n(tester).kochmodusMealPerCountEstimated('portion', 50),
      ),
      findsOneWidget,
    );
  });
}
