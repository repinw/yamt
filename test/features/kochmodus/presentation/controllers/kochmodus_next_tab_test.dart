import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';
import 'kochmodus_controller_harness.dart';
import 'slow_cook_runs.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');

void main() {
  late KochmodusHarness harness;
  late SlowCookRuns runs;

  setUp(() async {
    harness = await KochmodusHarness.open();
    await harness.cook.start(
      buildCookRun(
        step: CookRunStep.cook,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        lines: [textLine('line-0', '200 g Reis')],
      ),
    );
    runs = SlowCookRuns(harness.cook.runs);
    harness.runsOverride = runs;
  });

  group('a stored run opens the next tab only once the step is stored', () {
    test('a failed write keeps the tab', () async {
      final controller = await harness.openPage(_recipe);
      expect(harness.view(_recipe)!.step, KochmodusStep.cook);
      runs.fails = true;

      expect(await controller.toPortion(), isFalse);
      await harness.settle();

      expect(harness.view(_recipe)!.step, KochmodusStep.cook);
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.cook,
      );
    });

    test('the tab stays until the write lands, then the next opens', () async {
      final controller = await harness.openPage(_recipe);
      final gate = runs.gate = Completer<void>();

      final done = controller.toPortion();
      await harness.settle();
      expect(harness.view(_recipe)!.step, KochmodusStep.cook);

      gate.complete();
      expect(await done, isTrue);
      await harness.settle();

      expect(harness.view(_recipe)!.step, KochmodusStep.portion);
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.portion,
      );
    });

    test('a goTo during the write is not overwritten', () async {
      final controller = await harness.openPage(_recipe);
      final gate = runs.gate = Completer<void>();

      final done = controller.toPortion();
      await harness.settle();
      // The cook looks back at Töpfe while the write is still on its way.
      await controller.goTo(KochmodusStep.pots);
      gate.complete();
      expect(await done, isTrue);
      await harness.settle();

      expect(harness.view(_recipe)!.step, KochmodusStep.pots);
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.portion,
      );
    });
  });
}
