import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/application/cook_refill.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

// A refill that takes each line from what [now] says, whatever the items.
CookRefill _refill(Map<String, Map<String, int>> now) =>
    (run, lineId, itemIds) => run.settle(lineId, assigned(now[lineId]!));

Map<String, int> _takes(CookRun run, String lineId) => {
  for (final take in (run.lineOf(lineId)!.settlement as LineAssigned).takes)
    take.itemId: take.amount,
};

void main() {
  group('cookRefillCut', () {
    CookRun run({int? weighed, int take = 300}) => buildCookRun(
      lines: [
        textLine(
          'a',
          '400 g Reis',
          settlement: assigned({'f': take}),
          weighed: weighed,
        ),
      ],
    );

    test('grows a take that was cut once the stock holds more', () {
      final refilled = cookRefillCut(
        run(),
        _refill({
          'a': {'f': 400},
        }),
      );

      expect(_takes(refilled, 'a'), {'f': 400});
    });

    test('never shrinks a take', () {
      final refilled = cookRefillCut(
        run(),
        _refill({
          'a': {'f': 200},
        }),
      );

      expect(_takes(refilled, 'a'), {'f': 300});
    });

    test('keeps a take that stays as it is', () {
      final before = run();

      expect(
        cookRefillCut(
          before,
          _refill({
            'a': {'f': 300},
          }),
        ),
        before,
      );
    });

    test('leaves a weighed line alone', () {
      final refilled = cookRefillCut(
        run(weighed: 280),
        _refill({
          'a': {'f': 400},
        }),
      );

      expect(_takes(refilled, 'a'), {'f': 300});
    });

    test('leaves a line that takes 0 alone: it waits for a weight', () {
      final refilled = cookRefillCut(
        run(take: 0),
        _refill({
          'a': {'f': 400},
        }),
      );

      expect(_takes(refilled, 'a'), {'f': 0});
    });

    test('leaves lines that are not assigned alone', () {
      final open = buildCookRun(lines: [textLine('a', '400 g Reis')]);

      expect(
        cookRefillCut(
          open,
          _refill({
            'a': {'f': 400},
          }),
        ),
        open,
      );
    });

    test('does not take from a food the line did not name', () {
      final refilled = cookRefillCut(
        run(),
        _refill({
          'a': {'f': 400, 'g': 50},
        }),
      );

      expect(_takes(refilled, 'a'), {'f': 300});
    });
  });

  group('cookRunOpened', () {
    test('opens the shopping lines of a paused run and refills', () {
      final paused = buildCookRun(
        step: CookRunStep.paused,
        lines: [
          textLine('a', '400 g Reis', settlement: const LineShopping()),
          textLine('b', '400 g Mehl', settlement: assigned({'f': 300})),
        ],
      );

      final opened = cookRunOpened(
        paused,
        _refill({
          'b': {'f': 400},
        }),
      );

      expect(opened.lineOf('a')!.settlement, isA<LineOpen>());
      expect(_takes(opened, 'b'), {'f': 400});
    });
  });
}
