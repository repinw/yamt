import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';

import 'kochmodus_controller_harness.dart';
import 'slow_cook_runs.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');
const _runId = 'recipe-t1';

void main() {
  late KochmodusHarness harness;
  late SlowCookRuns runs;

  setUp(() async {
    harness = await KochmodusHarness.open();
    runs = SlowCookRuns(harness.cook.runs);
    harness.runsOverride = runs;
  });

  // The server rejects the create of the draft: the local cache rolls it
  // back, and the rejection comes before or after that.
  Future<void> reject({required bool rollbackFirst}) async {
    if (rollbackFirst) {
      await harness.cook.removeRun(_runId);
      await harness.settle();
    }
    runs.serverRejects.add(_runId);
    if (!rollbackFirst) {
      await harness.cook.removeRun(_runId);
    }
    await harness.settle();
  }

  for (final rollbackFirst in [true, false]) {
    final order = rollbackFirst ? 'after the rollback' : 'before the rollback';

    test('a rejected create $order keeps what the cook did as a draft, '
        'counts the rejection and does not end the page', () async {
      final controller = await harness.openPage(_recipe);
      expect(await controller.setGuide(on: true), isTrue);
      await harness.settle();
      expect(harness.view(_recipe)!.saved, isTrue);

      await reject(rollbackFirst: rollbackFirst);

      final view = harness.view(_recipe)!;
      expect(view.ended, isFalse);
      expect(view.saved, isFalse);
      expect(view.rejected, 1);
      expect(view.run.withGuide, isTrue);
    });

    test('after a rejected create $order the next change stores the run '
        'again with both changes', () async {
      final controller = await harness.openPage(_recipe);
      expect(await controller.setGuide(on: true), isTrue);
      await harness.settle();
      await reject(rollbackFirst: rollbackFirst);

      expect(await controller.setToCookbook(on: true), isTrue);
      await harness.settle();

      expect(runs.creates, 2);
      final stored = (await harness.cook.storedRun(_runId))!;
      expect(stored.withGuide, isTrue);
      expect(stored.toCookbook, isTrue);
      expect(harness.view(_recipe)!.saved, isTrue);
    });
  }

  test('a rejection of another run changes nothing', () async {
    final controller = await harness.openPage(_recipe);
    expect(await controller.setGuide(on: true), isTrue);
    await harness.settle();

    runs.serverRejects.add('recipe-other');
    await harness.settle();

    final view = harness.view(_recipe)!;
    expect(view.saved, isTrue);
    expect(view.rejected, 0);
  });
}
