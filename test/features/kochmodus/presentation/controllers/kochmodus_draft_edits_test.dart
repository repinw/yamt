import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';
import 'kochmodus_controller_harness.dart';
import 'slow_cook_runs.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');
const _free = KochmodusTarget.free('free-1');

void main() {
  late KochmodusHarness harness;
  late SlowCookRuns runs;

  setUp(() async {
    harness = await KochmodusHarness.open();
    runs = SlowCookRuns(harness.cook.runs);
    harness.runsOverride = runs;
  });

  group('the edits of a recipe draft', () {
    test('two edits in a row give one create, then one mutate, and both '
        'land', () async {
      final controller = await harness.openPage(_recipe);
      final gate = runs.createGate = Completer<void>();

      final first = controller.setGuide(on: true);
      final second = controller.setToCookbook(on: true);
      await harness.settle();
      // The second waits: only the first create started.
      expect(runs.creates, 1);
      expect(runs.mutates, 0);

      gate.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      await harness.settle();

      expect(runs.creates, 1);
      expect(runs.mutates, 1);
      final stored = (await harness.cook.storedRun('recipe-t1'))!;
      expect(stored.withGuide, isTrue);
      expect(stored.toCookbook, isTrue);
    });

    test(
      'a second edit still runs after the create of the first failed',
      () async {
        final controller = await harness.openPage(_recipe);
        runs.createFails = true;
        final gate = runs.createGate = Completer<void>();

        final first = controller.setGuide(on: true);
        final second = controller.setToCookbook(on: true);
        await harness.settle();
        runs.createFails = false;
        gate.complete();

        expect(await first, isFalse);
        expect(await second, isTrue);
        await harness.settle();

        expect(runs.creates, 2);
        final stored = (await harness.cook.storedRun('recipe-t1'))!;
        expect(stored.toCookbook, isTrue);
      },
    );

    test('a queued edit still lands after the page closed', () async {
      final provider = kochmodusControllerProvider(_recipe);
      final subscription = harness.container.listen(provider, (_, _) {});
      await harness.container.read(provider.future);
      final controller = harness.container.read(provider.notifier);
      final gate = runs.createGate = Completer<void>();

      final first = controller.setGuide(on: true);
      final second = controller.setToCookbook(on: true);
      await harness.settle();
      subscription.close();
      await pumpEventQueue();
      gate.complete();

      expect(await first, isTrue);
      expect(await second, isTrue);
      await harness.settle();

      final stored = (await harness.cook.storedRun('recipe-t1'))!;
      expect(stored.withGuide, isTrue);
      expect(stored.toCookbook, isTrue);
    });
  });

  test('the edits of a free draft before the pots stay in order, and the '
      'pots store them all', () async {
    final controller = await harness.openPage(_free);

    final edits = [
      controller.setGuide(on: true),
      controller.setToCookbook(on: true),
      controller.setGuide(on: false),
    ];
    expect(await Future.wait(edits), [true, true, true]);
    await harness.settle();

    expect(await harness.cook.storedRun('free-1'), isNull);
    final draft = harness.view(_free)!.run;
    expect(draft.withGuide, isFalse);
    expect(draft.toCookbook, isTrue);

    expect(
      await controller.choosePots([utensil('pot-a')], inCans: false),
      isTrue,
    );
    await harness.settle();
    final stored = (await harness.cook.storedRun('free-1'))!;
    expect(stored.withGuide, isFalse);
    expect(stored.toCookbook, isTrue);
    expect(stored.pots, isA<CookPotsChosen>());
    expect(runs.creates, 1);
  });

  test('the edits of a stored run do not wait for each other', () async {
    await harness.cook.start(
      buildCookRun(
        step: CookRunStep.cook,
        pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
        lines: [textLine('line-0', '200 g Reis')],
      ),
    );
    final controller = await harness.openPage(_recipe);
    final gate = runs.gate = Completer<void>();

    final first = controller.setGuide(on: true);
    final second = controller.setToCookbook(on: true);
    await harness.settle();

    // Both writes started while the first is still open.
    expect(runs.mutates, 2);
    gate.complete();
    await Future.wait([first, second]);
    await harness.settle();
    final stored = (await harness.cook.storedRun('recipe-t1'))!;
    expect(stored.withGuide, isTrue);
    expect(stored.toCookbook, isTrue);
  });
}
