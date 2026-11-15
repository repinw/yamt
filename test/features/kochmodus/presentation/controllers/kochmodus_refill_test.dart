import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';
import 'kochmodus_controller_harness.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');

Map<String, int> _takes(CookRun run, String lineId) => {
  for (final take in (run.lineOf(lineId)!.settlement as LineAssigned).takes)
    take.itemId: take.amount,
};

void main() {
  group('through the controller', () {
    late KochmodusHarness harness;

    // A take that was cut at 300 g: the Vorrat holds 500 g now.
    CookRun cut({CookRunStep step = CookRunStep.assign}) => buildCookRun(
      step: step,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      lines: [
        textLine('a', '400 g Reis', settlement: assigned({'f': 300})),
        textLine('b', 'Salz', settlement: const LineIgnored()),
      ],
    );

    // How many times the stored run was written since [watch].
    var writes = 0;

    Future<void> watch() async {
      writes = 0;
      final stream = harness.cook.firestore
          .collection('households')
          .doc('h1')
          .collection('cook_runs')
          .doc('recipe-t1')
          .snapshots();
      final subscription = stream.listen((_) => writes++);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      writes = 0;
    }

    setUp(() async {
      harness = await KochmodusHarness.open();
      await harness.stock([stockItem('f', 500)]);
    });

    test('opening the page after the stock grew refills the take, and the '
        'line no longer reads short', () async {
      await harness.cook.start(cut());
      final controller = await harness.openPage(_recipe);
      await watch();

      expect(await controller.open(), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(_takes(stored!, 'a'), {'f': 400});
      final line = harness
          .view(_recipe)!
          .lines
          .singleWhere((line) => line.id == 'a');
      expect(line.shortBy, isNull);
      expect(writes, 1);
    });

    test('"Kochen" refills too', () async {
      await harness.cook.start(cut());
      final controller = await harness.openPage(_recipe);

      expect(await controller.toPots(), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.step, CookRunStep.pots);
      expect(_takes(stored, 'a'), {'f': 400});
    });

    test('opening a run where nothing changes writes nothing', () async {
      await harness.cook.start(
        buildCookRun(
          lines: [
            textLine('a', '400 g Reis', settlement: assigned({'f': 400})),
          ],
        ),
      );
      final controller = await harness.openPage(_recipe);
      await watch();

      expect(await controller.open(), isTrue);
      await harness.settle();

      expect(writes, 0);
    });

    test('a take never grows past what another cooking leaves', () async {
      await harness.cook.start(cut());
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          recipeId: 't2',
          lines: [
            textLine('o', '300 g Reis', settlement: assigned({'f': 300})),
          ],
        ),
      );
      final controller = await harness.openPage(_recipe);

      expect(await controller.open(), isTrue);
      await harness.settle();

      // 500 g minus the 300 g the other cooking holds: 200 g are free, the
      // take was cut at 300 g already, and a take is never cut here.
      expect(
        _takes((await harness.cook.storedRun('recipe-t1'))!, 'a')['f'],
        greaterThanOrEqualTo(300),
      );
    });

    test('"Alles" stores the food and the amount in one write', () async {
      await harness.cook.start(
        buildCookRun(lines: [textLine('a', '400 g Reis')]),
      );
      final controller = await harness.openPage(_recipe);
      await watch();

      expect(
        await controller.assignItems(
          'a',
          ['f'],
          own: (amount: 500, unit: null),
        ),
        isTrue,
      );
      await harness.settle();

      final stored = (await harness.cook.storedRun('recipe-t1'))!;
      expect(stored.lineOf('a')!.amount, 500);
      expect(_takes(stored, 'a'), {'f': 500});
      expect(writes, 1);
    });
  });
}
