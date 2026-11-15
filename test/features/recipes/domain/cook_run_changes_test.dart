import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../kochmodus/kochmodus_fixtures.dart';
import '../cook_run_fixtures.dart';

final _twoPots = CookPotsChosen(
  pots: const [cookPotA, cookPotB],
  inCans: false,
);

LineAssigned _takes(Map<String, int> amounts) => LineAssigned([
  for (final MapEntry(:key, :value) in amounts.entries)
    ItemTake(itemId: key, amount: value),
]);

void main() {
  group('portions, pots, steps', () {
    test('a run below 1 portion or base portion cannot be made', () {
      expect(() => buildCookRun(portions: 0), throwsArgumentError);
    });

    test('withPots keeps lines and meals of chosen pots, resets the rest', () {
      final run = buildCookRun(
        lines: [
          cookLine('a', potId: 'pot-a'),
          cookLine('b', potId: 'pot-b'),
          cookLine('c'),
        ],
        pots: _twoPots,
        meals: const [
          CookMealDraft(
            potId: 'pot-a',
            name: 'A',
            count: 1,
            inPieces: false,
            grossWeight: null,
          ),
          CookMealDraft(
            potId: 'pot-b',
            name: 'B',
            count: 1,
            inPieces: false,
            grossWeight: null,
          ),
        ],
      );

      final changed = run.withPots(const [cookPotA], inCans: true);

      expect(
        changed.pots,
        CookPotsChosen(pots: const [cookPotA], inCans: true),
      );
      expect(changed.lines.map((l) => l.potId), ['pot-a', null, null]);
      expect(changed.meals.map((m) => m.potId), ['pot-a']);
    });

    test('withCounted drops pots of lines and meals but not the counted', () {
      final run = buildCookRun(
        lines: [cookLine('a', potId: 'pot-a')],
        pots: _twoPots,
        meals: const [
          CookMealDraft(
            potId: 'pot-a',
            name: 'A',
            count: 1,
            inPieces: false,
            grossWeight: null,
          ),
          CookMealDraft(
            potId: countedMealPotId,
            name: 'K',
            count: 3,
            inPieces: true,
            grossWeight: null,
          ),
        ],
      );

      final changed = run.withCounted();

      expect(changed.pots, const CookCounted());
      expect(changed.lines.single.potId, isNull);
      expect(changed.meals.map((m) => m.potId), [countedMealPotId]);
    });

    test('toStep changes only the step', () {
      final run = buildCookRun();

      expect(run.toStep(CookRunStep.cook).step, CookRunStep.cook);
      expect(run.toStep(CookRunStep.cook).lines, run.lines);
    });

    test('setPot needs a chosen pot and an existing line', () {
      final run = buildCookRun(pots: _twoPots);

      expect(run.setPot('line-0', 'pot-b').lineOf('line-0')!.potId, 'pot-b');
      expect(() => run.setPot('line-0', 'pot-x'), throwsStateError);
      expect(() => run.setPot('nope', 'pot-a'), throwsStateError);
      expect(() => buildCookRun().setPot('line-0', 'pot-a'), throwsStateError);
      expect(
        () => buildCookRun(pots: const CookCounted()).setPot('line-0', 'pot-a'),
        throwsStateError,
      );
    });
  });

  group('lines', () {
    test('settle replaces only the named line', () {
      final run = buildCookRun();

      final changed = run.settle('line-1', const LineShopping());

      expect(changed.lineOf('line-1')!.settlement, const LineShopping());
      expect(changed.lineOf('line-0'), run.lineOf('line-0'));
      expect(() => run.settle('nope', const LineIgnored()), throwsStateError);
    });

    test('withTakes assigns, no takes open the line, a duplicate throws', () {
      final run = buildCookRun();

      final assigned = run.withTakes('line-0', [
        const ItemTake(itemId: 'i', amount: 5),
      ]);
      expect(assigned.lineOf('line-0')!.settlement, _takes({'i': 5}));
      expect(
        assigned.withTakes('line-0', const []).lineOf('line-0')!.settlement,
        const LineOpen(),
      );
      expect(
        () => run.withTakes('line-0', const [
          ItemTake(itemId: 'i', amount: 1),
          ItemTake(itemId: 'i', amount: 1),
        ]),
        throwsArgumentError,
      );
    });

    test('withAmount sets and clears, rejects negative', () {
      final run = buildCookRun();

      final set = run.withAmount('line-0', 250);
      expect(set.lineOf('line-0')!.amount, 250);
      expect(set.lineOf('line-0')!.amountPortions, 4);
      final cleared = set.withAmount('line-0', null).lineOf('line-0')!;
      expect(cleared.amount, isNull);
      expect(cleared.amountPortions, isNull);
      expect(
        run
            .copyWith(portions: 6)
            .withAmount('line-0', 250)
            .lineOf('line-0')!
            .amountPortions,
        6,
      );
      expect(run.withAmount('line-0', 0).lineOf('line-0')!.amount, 0);
      expect(() => run.withAmount('line-0', -1), throwsArgumentError);
      expect(() => run.withAmount('nope', 1), throwsStateError);
    });

    test(
      'withAmount keeps the unit of a text without amount until cleared',
      () {
        final set = buildCookRun().withAmount(
          'line-0',
          3,
          unit: TemplateIngredientUnit.piece,
        );
        expect(set.lineOf('line-0')!.amountUnit, TemplateIngredientUnit.piece);

        final cleared = set.withAmount('line-0', null).lineOf('line-0')!;
        expect(cleared.amountUnit, isNull);
      },
    );

    test('weigh sets and clears, rejects negative', () {
      final run = buildCookRun();

      final set = run.weigh('line-0', 120);
      expect(set.lineOf('line-0')!.weighed, 120);
      expect(set.weigh('line-0', null).lineOf('line-0')!.weighed, isNull);
      expect(() => run.weigh('line-0', -5), throwsArgumentError);
      expect(() => run.weigh('nope', 5), throwsStateError);
    });

    test('addLine appends and refuses a taken id', () {
      final run = buildCookRun();

      final changed = run.addLine(
        cookLine('new', origin: CookLineOrigin.added),
      );

      expect(changed.lines.map((l) => l.id), ['line-0', 'line-1', 'new']);
      expect(() => run.addLine(cookLine('line-0')), throwsStateError);
    });

    test('removeLine drops the line and its takes', () {
      final run = buildCookRun().withTakes('line-0', [
        const ItemTake(itemId: 'i', amount: 5),
      ]);

      final changed = run.removeLine('line-0');

      expect(changed.lines.map((l) => l.id), ['line-1']);
      expect(changed.reservations, isEmpty);
      expect(() => run.removeLine('nope'), throwsStateError);
    });

    test('removeLine keeps the items the line put into the Vorrat', () {
      final run = buildCookRun(
        lines: [
          cookLine('line-0', addedItemIds: const ['a', 'b']),
          cookLine('line-1', addedItemIds: const ['c']),
        ],
      );

      final changed = run.removeLine('line-0');

      expect(changed.droppedItemIds, ['a', 'b']);
      expect(changed.addedItemIds, {'a', 'b', 'c'});
    });

    group('restoreLine', () {
      test('replaces a settled line in place, takes and weight included', () {
        final before = cookLine(
          'line-0',
          settlement: _takes({'i': 40}),
          weighed: 40,
        );
        final run = buildCookRun(lines: [before, cookLine('line-1')]);

        final changed = run
            .settle('line-0', const LineIgnored())
            .restoreLine(before, index: 0);

        expect(changed.lines, [before, run.lines[1]]);
        expect(changed.lineOf('line-0')!.weighed, 40);
      });

      test('puts a removed line back at its index', () {
        final before = cookLine('line-1', settlement: _takes({'i': 5}));
        final run = buildCookRun(
          lines: [cookLine('line-0'), before, cookLine('line-2')],
        );

        final changed = run.removeLine('line-1').restoreLine(before, index: 1);

        expect(changed.lines.map((l) => l.id), ['line-0', 'line-1', 'line-2']);
        expect(changed.lineOf('line-1'), before);
      });

      test('takes the added items out of droppedItemIds again', () {
        final before = cookLine('line-0', addedItemIds: const ['a', 'b']);
        final run = buildCookRun(
          lines: [
            before,
            cookLine('line-1', addedItemIds: const ['c']),
          ],
          droppedItemIds: const ['z'],
        );

        final changed = run.removeLine('line-0').restoreLine(before, index: 0);

        expect(changed.droppedItemIds, ['z']);
        expect(changed.addedItemIds, {'a', 'b', 'c', 'z'});
      });

      test('removes only one entry per added id', () {
        final before = cookLine('line-0', addedItemIds: const ['a']);
        final run = buildCookRun(
          lines: [before, cookLine('line-1')],
          droppedItemIds: const ['a'],
        );

        final changed = run.removeLine('line-0').restoreLine(before, index: 0);

        expect(changed.droppedItemIds, ['a']);
      });
    });

    test('reopenShopping opens shopping lines only and goes to assign', () {
      final run = buildCookRun(
        step: CookRunStep.paused,
        lines: [
          cookLine('a', settlement: const LineShopping()),
          cookLine('b', settlement: const LineIgnored()),
          cookLine('c', settlement: _takes({'i': 1})),
          cookLine('d', settlement: const LineShopping()),
        ],
      );

      final changed = run.reopenShopping();

      expect(changed.step, CookRunStep.assign);
      expect(changed.lines.map((l) => l.settlement), [
        const LineOpen(),
        const LineIgnored(),
        _takes({'i': 1}),
        const LineOpen(),
      ]);
      expect(changed.shoppingCount, 0);
    });

    test('addedItem remembers an item once', () {
      final run = buildCookRun();

      final once = run.addedItem('line-0', 'x');
      final twice = once.addedItem('line-0', 'x').addedItem('line-0', 'y');

      expect(once.lineOf('line-0')!.addedItemIds, ['x']);
      expect(twice.lineOf('line-0')!.addedItemIds, ['x', 'y']);
      expect(() => run.addedItem('nope', 'x'), throwsStateError);
    });
  });

  group('guide, timers, meals, cookbook', () {
    test('useGuide and guideTo', () {
      final run = buildCookRun();

      expect(run.useGuide(on: true).withGuide, isTrue);
      expect(run.guideTo(2).guideStep, 2);
      expect(() => run.guideTo(3), throwsRangeError);
      expect(() => run.guideTo(-1), throwsRangeError);
      expect(() => buildCookRun(steps: const []).guideTo(0), throwsRangeError);
    });

    test('addTimer, extendTimer and stopTimer', () {
      final timer = CookTimer(
        id: 't',
        label: 'Reis',
        endsAt: cookRunStart,
        deviceId: 'd',
      );
      final run = buildCookRun().addTimer(timer);

      expect(run.timers, [timer]);
      expect(() => run.addTimer(timer), throwsStateError);
      expect(
        run
            .extendTimer(
              't',
              const Duration(minutes: 2),
              now: cookRunStart.subtract(const Duration(minutes: 1)),
            )
            .timers
            .single
            .endsAt,
        cookRunStart.add(const Duration(minutes: 2)),
      );
      expect(
        run
            .extendTimer(
              't',
              const Duration(minutes: 1),
              now: cookRunStart.add(const Duration(minutes: 3)),
            )
            .timers
            .single
            .endsAt,
        cookRunStart.add(const Duration(minutes: 4)),
        reason: 'a timer that rang 3 minutes ago rings 1 minute after now',
      );
      expect(run.stopTimer('t').timers, isEmpty);
      expect(
        () => run.extendTimer('x', Duration.zero, now: cookRunStart),
        throwsStateError,
      );
      expect(() => run.stopTimer('x'), throwsStateError);
    });

    test('withMeal replaces the draft of the same pot', () {
      const first = CookMealDraft(
        potId: 'pot-a',
        name: 'Alt',
        count: 1,
        inPieces: false,
        grossWeight: null,
      );
      const second = CookMealDraft(
        potId: 'pot-b',
        name: 'Zwei',
        count: 2,
        inPieces: false,
        grossWeight: null,
      );
      const replaced = CookMealDraft(
        potId: 'pot-a',
        name: 'Neu',
        count: 4,
        inPieces: true,
        grossWeight: 100,
      );

      final run = buildCookRun()
          .withMeal(first)
          .withMeal(second)
          .withMeal(replaced);

      expect(run.meals, [second, replaced]);
    });

    test('withMeal rejects a count below 1', () {
      expect(
        () => buildCookRun().withMeal(
          const CookMealDraft(
            potId: 'pot-a',
            name: 'Leer',
            count: 0,
            inPieces: false,
            grossWeight: null,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('withToCookbook', () {
      expect(buildCookRun().withToCookbook(on: true).toCookbook, isTrue);
    });

    test('a change leaves the unrelated fields alone', () {
      final run = fullCookRun();

      final changed = run.useGuide(on: true);

      expect(changed.lines, run.lines);
      expect(changed.pots, run.pots);
      expect(changed.timers, run.timers);
      expect(changed.meals, run.meals);
      expect(changed.startedAt, run.startedAt);
    });
  });

  group('queries', () {
    final run = buildCookRun(
      lines: [
        cookLine('a'),
        cookLine('b', settlement: _takes({'i': 100, 'j': 20})),
        cookLine('c', settlement: _takes({'i': 50})),
        cookLine('d', settlement: const LineShopping()),
        cookLine('e', origin: CookLineOrigin.cooking),
        cookLine('f', origin: CookLineOrigin.added),
      ],
    );

    test('lineOf finds a line or null', () {
      expect(run.lineOf('b')!.id, 'b');
      expect(run.lineOf('zz'), isNull);
    });

    test('openCount and shoppingCount', () {
      expect(run.openCount, 3);
      expect(run.shoppingCount, 1);
    });

    group('needsAssigning', () {
      test('an open line of the recipe needs assigning', () {
        expect(buildCookRun(lines: [cookLine('a')]).needsAssigning, isTrue);
      });

      test('a line that waits for the shopping needs assigning', () {
        final run = buildCookRun(
          lines: [
            cookLine('a', settlement: _takes({'i': 1})),
            cookLine('b', settlement: const LineShopping()),
          ],
        );

        expect(run.needsAssigning, isTrue);
      });

      test('a line added while assigning counts', () {
        final run = buildCookRun(
          lines: [cookLine('a', origin: CookLineOrigin.added)],
        );

        expect(run.needsAssigning, isTrue);
      });

      test('assigned and ignored lines need nothing', () {
        final run = buildCookRun(
          lines: [
            cookLine('a', settlement: _takes({'i': 1})),
            cookLine('b', settlement: const LineIgnored()),
          ],
        );

        expect(run.needsAssigning, isFalse);
      });

      test('an open line that came in while cooking does not count', () {
        final run = buildCookRun(
          lines: [
            cookLine('a', settlement: _takes({'i': 1})),
            cookLine('b', origin: CookLineOrigin.cooking),
            cookLine(
              'c',
              origin: CookLineOrigin.cooking,
              settlement: const LineShopping(),
            ),
          ],
        );

        expect(run.needsAssigning, isFalse);
      });

      test('a run without lines needs nothing', () {
        expect(buildCookRun(lines: const []).needsAssigning, isFalse);
      });

      test('free cooking never assigns', () {
        final free = freeRun([cookLine('a'), cookLine('b')]);

        expect(free.lines.first.settlement, isA<LineOpen>());
        expect(free.needsAssigning, isFalse);
      });
    });

    test('reservations sum the takes per item', () {
      expect(run.reservations, {'i': 150, 'j': 20});
    });

    test('reservationsOf sums over runs and handles none', () {
      final other = buildCookRun(
        id: 'other',
        lines: [
          cookLine('x', settlement: _takes({'i': 5, 'k': 1})),
        ],
      );

      expect(reservationsOf([run, other]), {'i': 155, 'j': 20, 'k': 1});
      expect(reservationsOf(const []), isEmpty);
    });
  });
}
