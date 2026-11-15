import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/install_id.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
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

CookRun _stored({CookRunStep step = CookRunStep.assign, int portions = 4}) =>
    buildCookRun(
      step: step,
      portions: portions,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      lines: [
        textLine('line-0', '200 g Reis'),
        textLine('line-1', 'Salz', settlement: const LineIgnored()),
      ],
    );

LineAssigned _assignedOf(CookRun? run, String lineId) =>
    run!.lineOf(lineId)!.settlement as LineAssigned;

void main() {
  late KochmodusHarness harness;

  setUp(() async => harness = await KochmodusHarness.open());

  group('draft', () {
    test('builds a draft from the recipe and stores nothing', () async {
      await harness.openPage(_recipe);

      final view = harness.view(_recipe)!;
      expect(view.saved, isFalse);
      expect(view.run.id, 'recipe-t1');
      expect(view.run.name, 'Eintopf');
      expect(view.run.step, CookRunStep.assign);
      expect(view.step, KochmodusStep.pots);
      expect(view.lines, hasLength(2));
      expect(await harness.cook.storedRun('recipe-t1'), isNull);
    });

    test('ends with the draft', () async {
      await harness.openPage(_recipe);

      expect(harness.states.last, isA<AsyncData<KochmodusView?>>());
      expect(harness.states.last.value!.saved, isFalse);
    });

    test('binds the portions of the target', () async {
      const target = KochmodusTarget.recipe(recipeId: 't1', portions: 6);
      await harness.openPage(target);

      expect(harness.view(target)!.run.portions, 6);
    });

    test('the first change stores the draft of a recipe', () async {
      final controller = await harness.openPage(_recipe);
      expect(await harness.cook.storedRun('recipe-t1'), isNull);

      expect(await controller.setGuide(on: true), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored, isNotNull);
      expect(stored!.withGuide, isTrue);
      expect(stored.step, CookRunStep.assign);
      expect(stored.pots, isNull);
      final view = harness.view(_recipe)!;
      expect(view.saved, isTrue);
      expect(view.busy, isFalse);
    });

    test('toPots stores the draft of a recipe on Töpfe', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.toPots(), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.step, CookRunStep.pots);
      expect(stored.pots, isNull);
      final view = harness.view(_recipe)!;
      expect(view.saved, isTrue);
      expect(view.step, KochmodusStep.pots);
    });

    test('choosePots stores the run and goes on to Kochen', () async {
      final controller = await harness.openPage(_recipe);

      final done = await controller.choosePots([
        utensil('pot-a'),
      ], inCans: true);
      await harness.settle();

      expect(done, isTrue);
      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored, isNotNull);
      expect(stored!.step, CookRunStep.cook);
      expect((stored.pots! as CookPotsChosen).inCans, isTrue);
      expect((stored.pots! as CookPotsChosen).pots.single.id, 'pot-a');
      final view = harness.view(_recipe)!;
      expect(view.saved, isTrue);
      expect(view.step, KochmodusStep.cook);
      expect(view.busy, isFalse);
    });

    test('creating shows busy, then settles', () async {
      final controller = await harness.openPage(_recipe);
      await harness.settle();
      harness.states.clear();

      await controller.choosePots([utensil('pot-a')], inCans: false);

      final busy = harness.states.map((state) => state.value?.busy).toList();
      // The draft edit of the pots emits first, not busy.
      expect(busy, contains(true));
      expect(busy.indexOf(true), lessThan(busy.lastIndexOf(false)));
      expect(busy.last, isFalse);
      expect(harness.states.every((state) => state is AsyncData), isTrue);
    });

    test(
      'choosePots moves a stored run from Zuweisen or Töpfe to Kochen',
      () async {
        for (final step in [CookRunStep.assign, CookRunStep.pots]) {
          final other = await KochmodusHarness.open();
          await other.cook.start(_stored(step: step));
          final controller = await other.openPage(_recipe);

          expect(
            await controller.choosePots([utensil('pot-b')], inCans: false),
            isTrue,
          );
          await other.settle();

          final stored = (await other.cook.storedRun('recipe-t1'))!;
          expect(stored.step, CookRunStep.cook);
          expect((stored.pots! as CookPotsChosen).pots.single.id, 'pot-b');
        }
      },
    );

    test('choosePots leaves a run past the pots where it is', () async {
      for (final step in [CookRunStep.cook, CookRunStep.portion]) {
        final other = await KochmodusHarness.open();
        await other.cook.start(_stored(step: step));
        final controller = await other.openPage(_recipe);

        await controller.choosePots([utensil('pot-b')], inCans: false);
        await other.settle();

        expect((await other.cook.storedRun('recipe-t1'))!.step, step);
      }
    });

    test('a free draft stays a draft after toPots', () async {
      const target = KochmodusTarget.free('free-1');
      final controller = await harness.openPage(target);

      await controller.toPots();
      await harness.settle();

      // Nothing to leave: free cooking starts on Töpfe and has no pots yet.
      expect(await harness.cook.storedRun('free-1'), isNull);
    });

    test('chooseCounted creates the run without a pot', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.chooseCounted(), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.pots, isA<CookCounted>());
      expect(harness.view(_recipe)!.counted, isTrue);
    });

    test('a free draft creates the run and goes on to Kochen', () async {
      const target = KochmodusTarget.free('free-1');
      final controller = await harness.openPage(target);

      final draft = harness.view(target)!;
      expect(draft.saved, isFalse);
      expect(draft.isFree, isTrue);
      expect(draft.run.id, 'free-1');
      expect(draft.step, KochmodusStep.pots);

      await controller.choosePots([utensil('pot-a')], inCans: false);
      await harness.settle();

      final stored = await harness.cook.storedRun('free-1');
      expect(stored!.kind, CookRunKind.free);
      expect(stored.step, CookRunStep.cook);
      expect(harness.view(target)!.step, KochmodusStep.cook);
    });

    test('a recipe that does not exist shows no page', () async {
      const target = KochmodusTarget.recipe(recipeId: 'nope');
      await harness.openPage(target);

      expect(harness.view(target), isNull);
      expect(harness.states.last, isA<AsyncData<KochmodusView?>>());
    });

    test('a run target that does not exist shows no page', () async {
      const target = KochmodusTarget.run('gone');
      await harness.openPage(target);

      expect(harness.view(target), isNull);
    });
  });

  group('binding', () {
    test('the recipe target is the run recipe-<id>', () {
      expect(_recipe.cookRunId, 'recipe-t1');
      expect(const KochmodusTarget.run('r1').cookRunId, 'r1');
      expect(const KochmodusTarget.free('f1').cookRunId, 'f1');
    });

    test('opens the stored run of the recipe instead of a draft', () async {
      await harness.cook.start(_stored(portions: 8));

      await harness.openPage(_recipe);

      final view = harness.view(_recipe)!;
      expect(view.saved, isTrue);
      expect(view.run.portions, 8);
      expect(view.step, KochmodusStep.pots);
    });

    test('opens a run by its id', () async {
      await harness.cook.start(_stored());
      const target = KochmodusTarget.run('recipe-t1');

      await harness.openPage(target);

      expect(harness.view(target)!.saved, isTrue);
    });

    test('a draft turns into the stored run when it arrives', () async {
      final controller = await harness.openPage(_recipe);
      await controller.choosePots([utensil('pot-a')], inCans: false);
      await harness.settle();

      final view = harness.view(_recipe)!;
      expect(view.saved, isTrue);
      expect(view.ended, isFalse);
    });
  });

  group('open', () {
    CookRun paused() => buildCookRun(
      step: CookRunStep.paused,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      lines: [
        textLine('line-0', '200 g Reis', settlement: const LineShopping()),
        textLine('line-1', 'Salz', settlement: const LineIgnored()),
      ],
    );

    test('a paused run opens its shopping lines again', () async {
      await harness.cook.start(paused());
      final controller = await harness.openPage(_recipe);
      expect(harness.view(_recipe)!.paused, isTrue);
      expect(harness.view(_recipe)!.reopened, isFalse);

      expect(await controller.open(), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.step, CookRunStep.assign);
      expect(stored.lineOf('line-0')!.settlement, isA<LineOpen>());
      expect(stored.lineOf('line-1')!.settlement, isA<LineIgnored>());
      final view = harness.view(_recipe)!;
      expect(view.reopened, isTrue);
      expect(view.paused, isFalse);
      expect(view.toAnswer.map((line) => line.id), contains('line-0'));
    });

    test('a run that is not paused stays as it is', () async {
      await harness.cook.start(_stored());
      final controller = await harness.openPage(_recipe);

      expect(await controller.open(), isTrue);

      expect(harness.view(_recipe)!.reopened, isFalse);
      expect(await harness.cook.storedRun('recipe-t1'), _stored());
    });

    test('a draft stays as it is', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.open(), isTrue);

      expect(harness.view(_recipe)!.reopened, isFalse);
      expect(harness.view(_recipe)!.saved, isFalse);
    });
  });

  group('lines', () {
    setUp(() async {
      await harness.stock([stockItem('i1', 500), stockItem('i2', 500)]);
      await harness.cook.start(_stored());
    });

    test('assignItems takes the need from the items', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.assignItems('line-0', ['i1']), isTrue);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(_assignedOf(stored, 'line-0').takes.single.itemId, 'i1');
      expect(_assignedOf(stored, 'line-0').takes.single.amount, 200);
      final view = harness.view(_recipe)!;
      // 500 g in the Vorrat hold more than the 200 g: ready, not short.
      expect(view.toAnswer, isEmpty);
      expect(view.shopping, isEmpty);
      expect(view.kcalPerPortion, 50);
    });

    test('a line left out because it does not count can be switched back on '
        'from the list', () async {
      final controller = await harness.openPage(_recipe);
      expect(harness.view(_recipe)!.ignored.map((line) => line.id), ['line-1']);

      expect(await controller.settle('line-1', const LineOpen()), isTrue);
      await harness.settle();

      final view = harness.view(_recipe)!;
      expect(view.ignored, isEmpty);
      expect(view.toAnswer.map((line) => line.id), ['line-0', 'line-1']);
    });

    test('assignItems without items opens the line again', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      await controller.assignItems('line-0', const []);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.settlement, isA<LineOpen>());
    });

    test('assignItems fails when every picked item left the Vorrat', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.assignItems('line-0', ['gone']), isFalse);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.settlement, isA<LineOpen>());
    });

    test('assignItems reads what other runs take', () async {
      await harness.cook.start(
        buildCookRun(
          id: 'recipe-t2',
          lines: [
            textLine('x', '450 g Reis', settlement: assigned({'i1': 450})),
          ],
        ),
      );
      final controller = await harness.openPage(_recipe);

      await controller.assignItems('line-0', ['i1', 'i2']);
      await harness.settle();

      final takes = _assignedOf(
        await harness.cook.storedRun('recipe-t1'),
        'line-0',
      ).takes;
      expect(takes.map((take) => '${take.itemId}:${take.amount}'), [
        'i1:50',
        'i2:150',
      ]);
      expect(harness.view(_recipe)!.otherReservations, {'i1': 450});
    });

    test('assignFound fills the need from the found food first', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      expect(
        await controller.assignFound('line-0', stockItem('i2', 500)),
        isTrue,
      );
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(
        _assignedOf(
          stored,
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['i2:200', 'i1:0'],
      );
      expect(stored!.lineOf('line-0')!.addedItemIds, ['i2']);
    });

    test(
      '"Ändern" to a found food for the same amount books it only',
      () async {
        final controller = await harness.openPage(_recipe);
        await controller.assignItems('line-0', ['i1']);

        await controller.assignFound('line-0', stockItem('i2', 500));
        await harness.settle();

        expect(
          _assignedOf(
            await harness.cook.storedRun('recipe-t1'),
            'line-0',
          ).takes.map((take) => '${take.itemId}:${take.amount}'),
          ['i2:200', 'i1:0'],
        );
        final line = harness
            .view(_recipe)!
            .lines
            .firstWhere((line) => line.id == 'line-0');
        expect(line.pictureItem?.id, 'i2');
        expect(line.itemCount, 1);
        expect(harness.view(_recipe)!.kcalPerPortion, 50);
      },
    );

    test('a second found food replaces the first one', () async {
      await harness.stock([stockItem('i3', 500)]);
      final controller = await harness.openPage(_recipe);
      await controller.assignFound('line-0', stockItem('i2', 500));

      await controller.assignFound('line-0', stockItem('i3', 500));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['i3:200', 'i2:0'],
      );
    });

    test(
      'assignFound alone drops the old takes, without it they stay',
      () async {
        final controller = await harness.openPage(_recipe);
        await controller.assignItems('line-0', ['i1']);

        await controller.assignFound(
          'line-0',
          stockItem('i2', 500),
          alone: true,
        );
        await harness.settle();

        expect(
          _assignedOf(
            await harness.cook.storedRun('recipe-t1'),
            'line-0',
          ).takes.map((take) => '${take.itemId}:${take.amount}'),
          ['i2:200'],
        );
      },
    );

    test('assignFound without alone keeps the old food behind', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      await controller.assignFound('line-0', stockItem('i2', 500));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => take.itemId),
        ['i2', 'i1'],
      );
    });

    test('a found food takes the need, not what the line had', () async {
      await harness.stock([stockItem('small', 150)]);
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['small']);

      await controller.assignFound('line-0', stockItem('i2', 500));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['i2:200', 'small:0'],
      );
    });

    test('a found food clears a take whose item is gone', () async {
      await harness.cook.start(
        buildCookRun(
          pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
          lines: [
            textLine(
              'line-0',
              '200 g Reis',
              settlement: assigned({'gone': 200}),
            ),
          ],
        ),
      );
      final controller = await harness.openPage(_recipe);

      await controller.assignFound('line-0', stockItem('i2', 500));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['i2:200'],
      );
      final line = harness
          .view(_recipe)!
          .lines
          .firstWhere((line) => line.id == 'line-0');
      expect(line.entryMissing, isFalse);
    });

    test(
      'a found food in another measure keeps its place with 0, the line keeps '
      'its take',
      () async {
        await harness.stock([packItem('pack', 3)]);
        final controller = await harness.openPage(_recipe);
        await controller.assignItems('line-0', ['i1']);

        await controller.assignFound('line-0', packItem('pack', 3));
        await harness.settle();

        expect(
          _assignedOf(
            await harness.cook.storedRun('recipe-t1'),
            'line-0',
          ).takes.map((take) => '${take.itemId}:${take.amount}'),
          ['pack:0', 'i1:200'],
        );
      },
    );

    test(
      'a found food in another measure leaves a short line its items',
      () async {
        await harness.stock([stockItem('small', 150), packItem('pack', 3)]);
        final controller = await harness.openPage(_recipe);
        await controller.assignItems('line-0', ['small']);

        await controller.assignFound('line-0', packItem('pack', 3));
        await harness.settle();

        expect(
          _assignedOf(
            await harness.cook.storedRun('recipe-t1'),
            'line-0',
          ).takes.map((take) => '${take.itemId}:${take.amount}'),
          ['pack:0', 'small:150'],
        );
      },
    );

    test('assignFound twice for the same food books it once', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignFound('line-0', stockItem('i2', 500));

      await controller.assignFound('line-0', stockItem('i2', 500));
      await harness.settle();

      final takes = _assignedOf(
        await harness.cook.storedRun('recipe-t1'),
        'line-0',
      ).takes;
      expect(takes.single.itemId, 'i2');
      expect(takes.single.amount, 200);
    });

    test('a found food takes the need capped by its stock', () async {
      await harness.stock([stockItem('tiny', 50)]);
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      await controller.assignFound('line-0', stockItem('tiny', 50));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['tiny:50', 'i1:150'],
      );
    });

    test('a found food with 500 g takes the 250 g the line needs', () async {
      final controller = await harness.openPage(_recipe);
      await controller.setAmount('line-0', 250);

      await controller.assignFound('line-0', stockItem('i2', 500));
      await harness.settle();

      expect(
        _assignedOf(
          await harness.cook.storedRun('recipe-t1'),
          'line-0',
        ).takes.map((take) => '${take.itemId}:${take.amount}'),
        ['i2:250'],
      );
    });

    test('the takes of a found food never exceed the need', () async {
      await harness.stock([stockItem('tiny', 50)]);
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1', 'i2']);

      await controller.assignFound('line-0', stockItem('tiny', 50));
      await harness.settle();

      final takes = _assignedOf(
        await harness.cook.storedRun('recipe-t1'),
        'line-0',
      ).takes;
      expect(takes.fold(0, (sum, take) => sum + take.amount), 200);
    });

    test(
      'buyRest sets the own amount and adds the rest to the shopping',
      () async {
        final controller = await harness.openPage(_recipe);
        await controller.assignItems('line-0', ['i1']);

        expect(
          await controller.buyRest('line-0', own: 120, rest: '80 g Reis'),
          isTrue,
        );
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(stored!.lineOf('line-0')!.amount, 120);
        expect(_assignedOf(stored, 'line-0').takes.single.amount, 120);
        final rest = stored.lineOf('line-0-rest')!;
        expect(rest.text, '80 g Reis');
        expect(rest.settlement, isA<LineShopping>());
        expect(rest.origin, CookLineOrigin.added);
        final view = harness.view(_recipe)!;
        expect(
          view.lines.firstWhere((l) => l.id == 'line-0').restOnList,
          isTrue,
        );
        expect(view.toAnswer, isEmpty);
        expect(view.shopping.map((line) => line.id), contains('line-0-rest'));
      },
    );

    test('buyRest replaces an earlier rest line', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);
      await controller.buyRest('line-0', own: 120, rest: '80 g Reis');

      await controller.buyRest('line-0', own: 100, rest: '100 g Reis');
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      final rests = stored!.lines.where((l) => l.id == 'line-0-rest');
      expect(rests, hasLength(1));
      expect(rests.single.text, '100 g Reis');
      expect(stored.lineOf('line-0')!.amount, 100);
    });

    test('setAmount sets the own amount and refills the takes', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      expect(await controller.setAmount('line-0', 350), isTrue);
      await harness.settle();

      var stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.amount, 350);
      expect(_assignedOf(stored, 'line-0').takes.single.amount, 350);
      expect(harness.view(_recipe)!.lines.first.text, '350 g Reis');

      expect(await controller.setAmount('line-0', null), isTrue);
      await harness.settle();

      stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.amount, isNull);
      expect(_assignedOf(stored, 'line-0').takes.single.amount, 200);
    });

    test('setAmount on an open line only stores the amount', () async {
      final controller = await harness.openPage(_recipe);

      await controller.setAmount('line-0', 350);
      await harness.settle();

      final stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.amount, 350);
      expect(stored.lineOf('line-0')!.settlement, isA<LineOpen>());
    });

    group('a line settled from an added item', () {
      Future<void> startWith({int? amount}) async {
        await harness.cook.start(
          buildCookRun(
            pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
            lines: [
              textLine(
                'line-0',
                '200 g Reis',
                amount: amount,
                settlement: assigned({'added': 200}),
                addedItemIds: ['added'],
              ),
            ],
          ),
        );
      }

      setUp(() async {
        await harness.stock([stockItem('added', 500)]);
      });

      test('setAmount sets the take to the own amount', () async {
        await startWith();
        final controller = await harness.openPage(_recipe);

        expect(await controller.setAmount('line-0', 100), isTrue);
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(_assignedOf(stored, 'line-0').takes.single.amount, 100);
      });

      test('setAmount above the stock takes the stock', () async {
        await startWith();
        final controller = await harness.openPage(_recipe);

        expect(await controller.setAmount('line-0', 900), isTrue);
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(_assignedOf(stored, 'line-0').takes.single.amount, 500);
      });
    });

    test('settle, weigh, addLine and removeLine change the run', () async {
      final controller = await harness.openPage(_recipe);

      await controller.settle('line-0', const LineShopping());
      await controller.weigh('line-0', 190);
      final id = await controller.addLine('Pfeffer', CookLineOrigin.cooking);
      await harness.settle();

      var stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf('line-0')!.settlement, isA<LineShopping>());
      expect(stored.lineOf('line-0')!.weighed, 190);
      expect(id, isNotNull);
      expect(stored.lineOf(id!)!.text, 'Pfeffer');
      expect(harness.view(_recipe)!.newLines.single.id, id);

      await controller.removeLine(id);
      await harness.settle();

      stored = await harness.cook.storedRun('recipe-t1');
      expect(stored!.lineOf(id), isNull);
    });

    test(
      'setPot, editMeal, setToCookbook and setGuide change the run',
      () async {
        final controller = await harness.openPage(_recipe);
        const draft = CookMealDraft(
          potId: 'pot-a',
          name: 'Suppe',
          count: 3,
          inPieces: false,
          grossWeight: 2000,
        );

        await controller.setPot('line-0', 'pot-a');
        await controller.editMeal(draft);
        await controller.setToCookbook(on: true);
        await controller.setGuide(on: true);
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(stored!.lineOf('line-0')!.potId, 'pot-a');
        expect(stored.meals, [draft]);
        expect(stored.toCookbook, isTrue);
        expect(stored.withGuide, isTrue);
      },
    );

    group('editMeal', () {
      const fallback = CookMealDraft(
        potId: 'pot-a',
        name: 'Fallback',
        count: 4,
        inPieces: false,
        grossWeight: 2400,
      );

      test('starts from the fallback and sets only the given field', () async {
        await harness.cook.start(_stored(step: CookRunStep.portion));
        final controller = await harness.openPage(_recipe);

        expect(await controller.editMeal(fallback, name: 'Suppe'), isTrue);
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(stored!.meals, [
          const CookMealDraft(
            potId: 'pot-a',
            name: 'Suppe',
            count: 4,
            inPieces: false,
            grossWeight: 2400,
          ),
        ]);
      });

      test('keeps the other stored fields', () async {
        await harness.cook.start(_stored(step: CookRunStep.portion));
        final controller = await harness.openPage(_recipe);
        await controller.editMeal(fallback, name: 'Suppe', count: 2);
        await harness.settle();

        await controller.editMeal(fallback, grossWeight: 1800);
        await controller.editMeal(fallback, inPieces: true);
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(stored!.meals, [
          const CookMealDraft(
            potId: 'pot-a',
            name: 'Suppe',
            count: 2,
            inPieces: true,
            grossWeight: 1800,
          ),
        ]);
      });
    });

    group('addDefaultMeals', () {
      CookMealDraft draft(String potId, String name) => CookMealDraft(
        potId: potId,
        name: name,
        count: 1,
        inPieces: false,
        grossWeight: null,
      );

      test('skips pots that already have a draft', () async {
        await harness.cook.start(_stored(step: CookRunStep.portion));
        final controller = await harness.openPage(_recipe);
        await controller.editMeal(draft('pot-a', 'x'), name: 'Getippt');
        await harness.settle();

        expect(
          await controller.addDefaultMeals([
            draft('pot-a', 'Standard'),
            draft('pot-b', 'Zweiter'),
          ]),
          isTrue,
        );
        await harness.settle();

        final stored = await harness.cook.storedRun('recipe-t1');
        expect(stored!.meals.map((meal) => (meal.potId, meal.name)), [
          ('pot-a', 'Getippt'),
          ('pot-b', 'Zweiter'),
        ]);
      });
    });

    test('goTo stores moving ahead, not looking back', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      expect(await controller.goTo(KochmodusStep.cook), isTrue);
      await harness.settle();
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.cook,
      );
      expect(harness.view(_recipe)!.step, KochmodusStep.cook);

      await controller.goTo(KochmodusStep.pots);
      await harness.settle();
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.cook,
      );
      expect(harness.view(_recipe)!.step, KochmodusStep.pots);
    });

    test('toPots leaves Zuweisen for Töpfe', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      expect(await controller.toPots(), isTrue);
      await harness.settle();

      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.pots,
      );
      expect(harness.view(_recipe)!.step, KochmodusStep.pots);
    });

    test('toPots leaves a paused run on Töpfe too', () async {
      await harness.cook.start(_stored().copyWith(step: CookRunStep.paused));
      final controller = await harness.openPage(_recipe);

      expect(await controller.toPots(), isTrue);
      await harness.settle();

      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.pots,
      );
    });

    test('toPots keeps a run that cooked already', () async {
      for (final step in [CookRunStep.cook, CookRunStep.portion]) {
        final other = await KochmodusHarness.open();
        await other.cook.start(_stored(step: step));
        final controller = await other.openPage(_recipe);

        expect(await controller.toPots(), isTrue);
        await other.settle();

        expect((await other.cook.storedRun('recipe-t1'))!.step, step);
      }
    });

    test('toPots and toPortion move the run on', () async {
      final controller = await harness.openPage(_recipe);
      await controller.assignItems('line-0', ['i1']);

      await controller.toPots();
      await controller.choosePots([utensil('pot-a')], inCans: false);
      await harness.settle();
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.cook,
      );
      expect(harness.view(_recipe)!.step, KochmodusStep.cook);

      await controller.toPortion();
      await harness.settle();
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.portion,
      );
      expect(harness.view(_recipe)!.step, KochmodusStep.portion);
    });

    test('guideTo keeps the instruction', () async {
      final controller = await harness.openPage(_recipe);

      await controller.guideTo(1);
      await harness.settle();

      expect((await harness.cook.storedRun('recipe-t1'))!.guideStep, 1);
    });
  });

  group('timers', () {
    setUp(() async {
      await harness.cook.start(_stored(step: CookRunStep.cook));
    });

    test('startTimer rings after the duration from the clock', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);

      expect(
        await timers.startTimer('Reis', const Duration(minutes: 9)),
        isTrue,
      );
      await harness.settle();

      final timer = (await harness.cook.storedRun('recipe-t1'))!.timers.single;
      expect(timer.label, 'Reis');
      expect(
        timer.endsAt.toUtc(),
        kochmodusNow.add(const Duration(minutes: 9)),
      );
      expect(timer.deviceId, await readInstallId(harness.preferences));
      expect(harness.view(_recipe)!.timers.single.id, timer.id);
    });

    test('extendTimer adds a minute, stopTimer removes the timer', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer('Reis', const Duration(minutes: 9));
      await harness.settle();
      final id = harness.view(_recipe)!.timers.single.id;

      await timers.extendTimer(id);
      await harness.settle();
      expect(
        harness.view(_recipe)!.timers.single.endsAt.toUtc(),
        kochmodusNow.add(const Duration(minutes: 10)),
      );

      await timers.stopTimer(id);
      await harness.settle();
      expect(harness.view(_recipe)!.timers, isEmpty);
      expect((await harness.cook.storedRun('recipe-t1'))!.timers, isEmpty);
    });

    test('timers come out soonest first', () async {
      await harness.openPage(_recipe);
      final timers = harness.timers(_recipe);
      await timers.startTimer('lang', const Duration(minutes: 20));
      await timers.startTimer('kurz', const Duration(minutes: 5));
      await harness.settle();

      expect(harness.view(_recipe)!.timers.map((timer) => timer.label), [
        'kurz',
        'lang',
      ]);
    });
  });

  group('ended', () {
    test('a run deleted elsewhere ends the page', () async {
      await harness.cook.start(_stored());
      final controller = await harness.openPage(_recipe);
      expect(harness.view(_recipe)!.ended, isFalse);

      await harness.cook.removeRun('recipe-t1');
      await harness.settle();

      final view = harness.view(_recipe)!;
      expect(view.ended, isTrue);
      expect(view.run.id, 'recipe-t1');
      expect(await controller.weigh('line-0', 100), isFalse);
    });

    test('a write on a run that is gone ends the page', () async {
      // The list still shows the run; the store never had it.
      harness.shownRuns = [_stored()];
      final controller = await harness.openPage(_recipe);
      expect(harness.view(_recipe)!.ended, isFalse);

      final done = await controller.weigh('line-0', 100);

      expect(done, isFalse);
      expect(harness.view(_recipe)!.ended, isTrue);
    });
  });

  group('ended after a gap', () {
    test('a run that comes back after a gap is not ended', () async {
      final runs = StreamController<List<CookRun>>();
      addTearDown(runs.close);
      harness.shownRunStream = runs.stream;
      final run = _stored();
      final pending = harness.openPage(_recipe);
      runs.add([run]);
      await pending;

      runs.add(const []);
      await harness.settle();
      expect(harness.view(_recipe)!.ended, isTrue);

      runs.add([run]);
      await harness.settle();

      expect(harness.view(_recipe)!.ended, isFalse);
      expect(harness.states.last.value!.ended, isFalse);
    });
  });

  group('finish', () {
    CookRun ready() => buildCookRun(
      step: CookRunStep.portion,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      meals: const [
        CookMealDraft(
          potId: 'pot-a',
          name: 'Eintopf',
          count: 4,
          inPieces: false,
          grossWeight: 2400,
        ),
      ],
      lines: [
        textLine('line-0', '300 g Reis', settlement: assigned({'i1': 300})),
        textLine('line-1', 'Salz', settlement: const LineIgnored()),
      ],
    );

    setUp(() => harness.stock([stockItem('i1', 800)]));

    test('puts the meals into the Vorrat and does not end the page', () async {
      await harness.cook.start(ready());
      final controller = await harness.openPage(_recipe);

      final summary = await controller.finish();
      await harness.settle();

      expect(summary, isNotNull);
      expect(summary!.meals, hasLength(1));
      expect(summary.meals.single.totalPortions, 4);
      expect(await harness.cook.storedRun('recipe-t1'), isNull);
      expect(await harness.cook.mealCount(), 1);
      expect((await harness.cook.storedItem('i1'))!.currentAmount, 500);
      final view = harness.view(_recipe)!;
      final done = view.finished!;
      final meal = summary.meals.single;
      expect(done.inCookbook, summary.inCookbook);
      expect(done.meals, hasLength(1));
      expect(done.meals.single.id, meal.id);
      expect(done.meals.single.name, meal.name);
      expect(done.meals.single.count, 4);
      expect(done.meals.single.serving, KochmodusServing.portion);
      expect(view.ended, isFalse);
      expect(view.busy, isFalse);
    });

    test('two finishes at once write once and share the summary', () async {
      await harness.cook.start(ready());
      final controller = await harness.openPage(_recipe);

      final both = await Future.wait([
        controller.finish(),
        controller.finish(),
      ]);
      await harness.settle();

      expect(both.first, isNotNull);
      expect(both.last, same(both.first));
      expect(await harness.cook.mealCount(), 1);
      expect((await harness.cook.storedItem('i1'))!.currentAmount, 500);
    });

    test('a finish after a success returns the same summary', () async {
      await harness.cook.start(ready());
      final controller = await harness.openPage(_recipe);

      final first = await controller.finish();
      final again = await controller.finish();

      await harness.settle();

      expect(again, same(first));
      expect(await harness.cook.mealCount(), 1);
    });

    test('a finish after a failure tries again', () async {
      await harness.cook.start(
        buildCookRun(
          step: CookRunStep.portion,
          pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
          lines: [textLine('line-0', '300 g Reis')],
        ),
      );
      final controller = await harness.openPage(_recipe);

      expect(await controller.finish(), isNull);
      await harness.cook.runs.mutate('recipe-t1', (run) => ready());
      await harness.settle();

      expect(await controller.finish(), isNotNull);
    });

    test('shows busy while it writes', () async {
      await harness.cook.start(ready());
      final controller = await harness.openPage(_recipe);
      harness.states.clear();

      await controller.finish();

      expect(harness.states.first.value!.busy, isTrue);
      expect(harness.states.last.value!.busy, isFalse);
    });

    test(
      'returns null and keeps the run while In Vorrat has to wait',
      () async {
        await harness.cook.start(
          buildCookRun(
            step: CookRunStep.portion,
            pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
            lines: [textLine('line-0', '300 g Reis')],
          ),
        );
        final controller = await harness.openPage(_recipe);

        expect(await controller.finish(), isNull);
        await harness.settle();

        expect(await harness.cook.storedRun('recipe-t1'), isNotNull);
        expect(await harness.cook.mealCount(), 0);
        expect(harness.view(_recipe)!.busy, isFalse);
      },
    );

    test('a draft cannot finish', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.finish(), isNull);
    });

    test('a run that is gone ends the page', () async {
      await harness.cook.start(ready());
      final controller = await harness.openPage(_recipe);
      await harness.cook.removeRun('recipe-t1');

      expect(await controller.finish(), isNull);
      await harness.settle();

      expect(harness.view(_recipe)!.ended, isTrue);
      expect(await harness.cook.mealCount(), 0);
    });
  });

  group('discard', () {
    CookRun fresh() => buildCookRun(
      lines: [
        textLine('line-0', '200 g Reis', addedItemIds: const ['new']),
      ],
    );

    setUp(() => harness.stock([stockItem('new', 500)]));

    test('deletes the run and returns it for restore', () async {
      await harness.cook.start(fresh());
      final controller = await harness.openPage(_recipe);

      final snapshot = await controller.discard();
      await harness.settle();

      expect(snapshot, fresh());
      expect(await harness.cook.storedRun('recipe-t1'), isNull);
      expect(await harness.cook.storedItem('new'), isNull);
      final view = harness.view(_recipe)!;
      expect(view.ended, isFalse);
      expect(view.busy, isFalse);
    });

    test('restore brings the run back', () async {
      await harness.cook.start(fresh());
      final controller = await harness.openPage(_recipe);
      final snapshot = (await controller.discard())!;
      await harness.settle();

      expect(await controller.restore(snapshot), isTrue);
      await harness.settle();

      expect(await harness.cook.storedRun('recipe-t1'), fresh());
    });

    test('restore fails when the recipe is being cooked again', () async {
      await harness.cook.start(fresh());
      final controller = await harness.openPage(_recipe);

      expect(await controller.restore(fresh()), isFalse);
    });

    test('a draft cannot be discarded', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.discard(), isNull);
    });
  });

  group('pause for shopping', () {
    test('puts the shopping lines on the list and pauses the run', () async {
      await harness.cook.start(
        buildCookRun(
          pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
          lines: [
            textLine('line-0', '200 g Reis', settlement: const LineShopping()),
            textLine('line-1', 'Salz', settlement: const LineIgnored()),
          ],
        ),
      );
      final controller = await harness.openPage(_recipe);

      expect(await controller.pauseForShopping(), isTrue);
      await harness.settle();

      final names = (await harness.shoppingList.readAll()).map(
        (item) => item.name,
      );
      expect(names.join(), contains('Reis'));
      expect(names.join(), isNot(contains('Salz')));
      expect(
        (await harness.cook.storedRun('recipe-t1'))!.step,
        CookRunStep.paused,
      );
      expect(harness.view(_recipe)!.paused, isTrue);
      expect(harness.view(_recipe)!.busy, isFalse);
    });

    test('a draft cannot pause', () async {
      final controller = await harness.openPage(_recipe);

      expect(await controller.pauseForShopping(), isFalse);
    });
  });

  group('inventory', () {
    test('keeps the items of the Vorrat and the utensils', () async {
      await harness.stock([stockItem('i1', 500)]);
      harness.utensils = [utensil('pot-a'), utensil('pot-b', grams: 600)];

      await harness.openPage(_recipe);

      final view = harness.view(_recipe)!;
      expect(view.items.keys, ['i1']);
      expect(view.utensils.map((u) => u.id), ['pot-a', 'pot-b']);
    });
  });
}
