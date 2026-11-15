import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_said_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_timer_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';
import 'kochmodus_controller_harness.dart';

const _recipe = KochmodusTarget.recipe(recipeId: 't1');

void main() {
  late KochmodusHarness harness;

  // How many times the stored run was written since [watch].
  var writes = 0;

  Future<void> watch() async {
    writes = 0;
    final subscription = harness.cook.firestore
        .collection('households')
        .doc('h1')
        .collection('cook_runs')
        .doc('recipe-t1')
        .snapshots()
        .listen((_) => writes++);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    writes = 0;
  }

  CookRun cooking() => buildCookRun(
    step: CookRunStep.cook,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    lines: [
      textLine('a', '200 g Reis', settlement: assigned({'f': 200})),
      textLine('b', 'Salz', settlement: const LineIgnored()),
    ],
  );

  setUp(() async {
    harness = await KochmodusHarness.open();
    await harness.stock([stockItem('f', 500)]);
    await harness.cook.start(cooking());
  });

  bool failed() => harness.states.any((state) => state is AsyncError);

  group('startTimer', () {
    const label = 'Schritt 1';
    const nine = Duration(minutes: 9);

    test('two taps at once start one timer', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);

      await Future.wait([
        timers.startTimer(label, nine),
        timers.startTimer(label, nine),
      ]);
      await harness.settle();

      expect(harness.view(_recipe)!.timers, hasLength(1));
      expect((await harness.cook.storedRun('recipe-t1'))!.timers, hasLength(1));
      expect(failed(), isFalse);
    });

    test('a tap while a timer of that name counts starts none', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer(label, nine);
      await harness.settle();

      expect(await timers.startTimer(label, nine), isTrue);
      await harness.settle();

      expect(harness.view(_recipe)!.timers, hasLength(1));
    });

    test(
      'starts when nothing listens to the timer or the page controller',
      () async {
        final pageProvider = kochmodusControllerProvider(_recipe);
        final page = harness.container.listen(pageProvider, (_, _) {});
        await harness.container.read(pageProvider.future);
        // Nobody listens to the timer provider.
        final timers = harness.container.read(
          kochmodusTimerControllerProvider(_recipe).notifier,
        );

        final started = timers.startTimer(label, nine);
        // The page closes while the timer starts.
        page.close();
        await pumpEventQueue();

        expect(await started, isTrue);
        await harness.settle();

        final stored = (await harness.cook.storedRun('recipe-t1'))!;
        expect(stored.timers.single.label, label);
      },
    );

    test('another name starts its own timer', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer(label, nine);
      await timers.startTimer('Schritt 2', nine);
      await harness.settle();

      expect(harness.view(_recipe)!.timers, hasLength(2));
    });

    test('after stopTimer a new one starts', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer(label, nine);
      await harness.settle();
      await timers.stopTimer(harness.view(_recipe)!.timers.single.id);
      await harness.settle();

      await timers.startTimer(label, nine);
      await harness.settle();

      expect(harness.view(_recipe)!.timers, hasLength(1));
    });
  });

  group('a second call', () {
    test('stopTimer twice: the second changes nothing and fails not', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer('Reis', const Duration(minutes: 9));
      await harness.settle();
      final id = harness.view(_recipe)!.timers.single.id;
      expect(await timers.stopTimer(id), isTrue);
      await harness.settle();
      await watch();

      expect(await timers.stopTimer(id), isTrue);
      await harness.settle();

      expect(writes, 0);
      expect(failed(), isFalse);
      expect(harness.view(_recipe)!.timers, isEmpty);
    });

    test(
      'removeLine twice: the second changes nothing and fails not',
      () async {
        final controller = await harness.openPage(_recipe);
        final id = await controller.addLine('Zwiebeln', CookLineOrigin.cooking);
        await harness.settle();
        expect(await controller.removeLine(id!), isTrue);
        await harness.settle();
        await watch();

        expect(await controller.removeLine(id), isTrue);
        await harness.settle();

        expect(writes, 0);
        expect(failed(), isFalse);
        expect(
          (await harness.cook.storedRun('recipe-t1'))!.lines.map((l) => l.id),
          ['a', 'b'],
        );
      },
    );
  });

  group('"nein"', () {
    KochmodusSaidController said() => harness.container.read(
      kochmodusSaidControllerProvider(_recipe).notifier,
    );

    Future<({String first, String second})> speak(
      KochmodusController controller,
    ) async {
      final first = await said().take(
        controller,
        'Zwiebeln',
        items: const {},
        localeCode: 'de',
      );
      final second = await said().take(
        controller,
        'Reis',
        items: const {},
        localeCode: 'de',
      );
      await harness.settle();
      return (first: first!.lineId, second: second!.lineId);
    }

    test('takes the last said line away after a change of tab', () async {
      final controller = await harness.openPage(_recipe);
      final lines = await speak(controller);

      // The cook looks at another tab and comes back.
      await controller.goTo(KochmodusStep.pots);
      await controller.goTo(KochmodusStep.cook);
      expect(await said().undoLast(controller), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf(lines.second), isNull);
      expect(stored.lineOf(lines.first), isNotNull);
    });

    test('skips a line that is gone and takes the one before it', () async {
      final controller = await harness.openPage(_recipe);
      final lines = await speak(controller);
      await controller.removeLine(lines.second);
      await harness.settle();

      expect(await said().undoLast(controller), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf(lines.first), isNull);
      expect(
        harness.container.read(kochmodusSaidControllerProvider(_recipe)),
        isEmpty,
      );
    });

    test('with nothing said, nothing happens', () async {
      final controller = await harness.openPage(_recipe);
      await watch();

      expect(await said().undoLast(controller), isTrue);

      expect(writes, 0);
    });

    test('never undoes what the cook did after speaking', () async {
      await harness.stock([
        stockItem('f', 500).copyWith(name: 'Reis'),
        stockItem('g', 500).copyWith(name: 'Basmati'),
      ]);
      final controller = await harness.openPage(_recipe);
      final items = harness.view(_recipe)!.items;
      final onions = await said().take(
        controller,
        'Zwiebeln',
        items: items,
        localeCode: 'de',
      );
      final rice = await said().take(
        controller,
        '30 g Reis',
        items: items,
        localeCode: 'de',
      );
      await harness.settle();
      expect(rice!.before?.id, 'a');
      // The cook gives the rice line another food after speaking.
      await controller.assignItems('a', ['g']);
      await harness.settle();
      final changed = (await harness.cook.storedRun('recipe-t1'))!.lineOf('a')!;

      expect(await said().undoLast(controller), isTrue);
      await harness.settle();

      final stored = (await harness.cook.storedRun('recipe-t1'))!;
      // The rice line keeps its food and its weight ...
      expect(stored.lineOf('a'), changed);
      expect(stored.lineOf('a')!.weighed, 30);
      // ... and "nein" went on to the line before it.
      expect(stored.lineOf(onions!.lineId), isNull);
    });
  });
}
