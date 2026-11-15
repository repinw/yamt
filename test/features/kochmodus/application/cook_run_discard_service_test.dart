import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/application/cook_run_discard_service.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'cook_services_harness.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

CookRun _run() => buildCookRun(
  lines: [
    textLine('line-0', 'Reis', addedItemIds: const ['fresh', 'cooked']),
    textLine('line-1', 'Salz', addedItemIds: const ['opened']),
  ],
);

void main() {
  late CookHarness harness;
  late CookRunDiscardService service;

  setUp(() async {
    harness = await CookHarness.open();
    service = CookRunDiscardService(
      runs: harness.runs,
      inventory: harness.inventory,
      meals: harness.meals,
      clock: () => _now,
    );
    await harness.stock([
      stockItem('fresh', 500),
      stockItem('cooked', 500).copyWith(lastConsumedAt: _now),
      stockItem('opened', 300, initial: 500),
      stockItem('own', 100),
    ]);
  });

  group('discard', () {
    test('returns the run as it was and deletes it', () async {
      await harness.start(_run());

      final snapshot = await service.discard('recipe-t1');
      await harness.settle();

      expect(snapshot, _run());
      expect(await harness.storedRun('recipe-t1'), isNull);
    });

    test('deletes the added items nobody changed, keeps the rest', () async {
      await harness.start(_run());

      await service.discard('recipe-t1');
      await harness.settle();

      expect(await harness.storedItem('fresh'), isNull);
      expect(await harness.storedItem('cooked'), isNotNull);
      expect(await harness.storedItem('opened'), isNotNull);
      expect(await harness.storedItem('own'), isNotNull);
    });

    test('never deletes a Vorrat food the line took, also with a take of '
        '0', () async {
      await harness.start(
        buildCookRun(
          lines: [
            textLine(
              'line-0',
              'Reis',
              settlement: assigned({'own': 0, 'fresh': 100}),
              addedItemIds: const ['fresh'],
            ),
          ],
        ),
      );

      await service.discard('recipe-t1');
      await harness.settle();

      expect(await harness.storedItem('own'), isNotNull);
      expect(await harness.storedItem('fresh'), isNull);
    });

    test('keeps an added item that another run takes from', () async {
      await harness.start(_run());
      await harness.start(
        buildCookRun(
          id: 'recipe-t2',
          lines: [
            textLine('line-0', 'Reis', settlement: assigned({'fresh': 100})),
          ],
        ),
      );

      await service.discard('recipe-t1');
      await harness.settle();

      expect(await harness.storedItem('fresh'), isNotNull);
    });

    test('writes no meal and no stock event', () async {
      await harness.start(_run());

      await service.discard('recipe-t1');
      await harness.settle();

      expect(await harness.mealCount(), 0);
      expect(await harness.eventCount(), 0);
    });

    test('a run that is gone throws and changes nothing', () async {
      await expectLater(
        service.discard('recipe-t1'),
        throwsA(isA<CookRunGoneException>()),
      );
      await harness.settle();

      expect(await harness.storedItem('fresh'), isNotNull);
    });
  });

  group('restore', () {
    test('brings the discarded run back as it was', () async {
      await harness.start(_run());
      final snapshot = await service.discard('recipe-t1');
      await harness.settle();

      await service.restore(snapshot);
      await harness.settle();

      expect(await harness.storedRun('recipe-t1'), _run());
    });

    test('refuses to overwrite a run that exists again', () async {
      await harness.start(_run());
      final snapshot = await service.discard('recipe-t1');
      await harness.settle();
      final newer = buildCookRun(
        startedAt: cookRunStart.add(const Duration(hours: 1)),
      );
      await harness.start(newer);

      await expectLater(service.restore(snapshot), throwsStateError);
      await harness.settle();

      expect(await harness.storedRun('recipe-t1'), newer);
    });

    test('an added item the discard deleted stays gone', () async {
      await harness.start(_run());
      final snapshot = await service.discard('recipe-t1');
      await harness.settle();

      await service.restore(snapshot);
      await harness.settle();

      expect(await harness.storedItem('fresh'), isNull);
    });
  });

  group('untouchedAddedItemIds', () {
    test('names added items whose stock nobody touched', () {
      final run = _run();

      expect(
        untouchedAddedItemIds(
          run,
          [
            stockItem('fresh', 500),
            stockItem('cooked', 500).copyWith(lastConsumedAt: _now),
            stockItem('opened', 300, initial: 500),
            stockItem('own', 100),
          ],
          used: const {},
          runs: const [],
        ),
        ['fresh'],
      );
    });

    test('a pack item is touched when its quantity changed', () {
      final run = buildCookRun(
        lines: [
          textLine('line-0', 'Reis', addedItemIds: const ['a', 'b']),
        ],
      );

      expect(
        untouchedAddedItemIds(
          run,
          [packItem('a', 2), packItem('b', 2).copyWith(quantity: 1)],
          used: const {},
          runs: const [],
        ),
        ['a'],
      );
    });

    test('leaves out the items that were used', () {
      final run = buildCookRun(
        lines: [
          textLine('line-0', 'Reis', addedItemIds: const ['a', 'b']),
        ],
      );

      expect(
        untouchedAddedItemIds(
          run,
          [stockItem('a', 500), stockItem('b', 500)],
          used: const {'a'},
          runs: const [],
        ),
        ['b'],
      );
    });

    test('leaves out the items that another run takes from', () {
      final run = buildCookRun(
        lines: [
          textLine('line-0', 'Reis', addedItemIds: const ['a', 'b']),
        ],
      );
      final other = buildCookRun(
        id: 'recipe-t2',
        lines: [
          textLine('line-0', 'Reis', settlement: assigned({'a': 0})),
        ],
      );

      expect(
        untouchedAddedItemIds(
          run,
          [stockItem('a', 500), stockItem('b', 500)],
          used: const {},
          runs: [run, other],
        ),
        ['b'],
      );
    });

    test('names the items of removed lines', () {
      final run = buildCookRun(
        lines: [
          textLine('line-0', 'Reis', addedItemIds: const ['a']),
        ],
      ).removeLine('line-0');

      expect(
        untouchedAddedItemIds(
          run,
          [stockItem('a', 500)],
          used: const {},
          runs: const [],
        ),
        ['a'],
      );
    });

    test('an added item that is no longer in the Vorrat is not named', () {
      final run = buildCookRun(
        lines: [
          textLine('line-0', 'Reis', addedItemIds: const ['gone']),
        ],
      );

      expect(
        untouchedAddedItemIds(run, const [], used: const {}, runs: const []),
        isEmpty,
      );
    });
  });
}
