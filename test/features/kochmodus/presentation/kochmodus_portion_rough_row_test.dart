import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _pot = CookMealDraft(
  potId: 'pot-a',
  name: 'Gemüsepfanne',
  count: 2,
  inPieces: false,
  grossWeight: 1500,
);

CookRun _run(List<CookRunLine> lines) => buildCookRun(
  step: CookRunStep.portion,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  meals: const [_pot],
  lines: lines,
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  testWidgets('the row of a rough line reads "≈ 3 g Zucker"', (tester) async {
    final run = _run([
      textLine(
        'l-sugar',
        'etwas Zucker',
        settlement: assigned({'sugar': 3}),
        roughWeight: const CookRoughWeight(
          amount: 3,
          unit: TemplateIngredientUnit.gram,
        ),
      ),
    ]);
    await harness.stock(tester, [
      stockItem('sugar', 1000).copyWith(name: 'Zucker'),
    ]);
    await harness.store(tester, run);

    await harness.pumpRun(tester, run.id);

    expect(find.text('≈ 3 g Zucker'), findsOneWidget);
    expect(find.textContaining('etwas'), findsNothing);
  });
}
