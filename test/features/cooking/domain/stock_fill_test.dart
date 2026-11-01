import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/domain/stock_fill.dart';

void main() {
  group('fillInOrder', () {
    test('one item that has enough gives the whole amount', () {
      final takes = fillInOrder(
        needed: 300,
        offers: const [(itemId: 'a', available: 500)],
      );
      expect(takes, [(itemId: 'a', amount: 300)]);
    });

    test('items give what they have, the last one only the rest', () {
      final takes = fillInOrder(
        needed: 700,
        offers: const [
          (itemId: 'a', available: 250),
          (itemId: 'b', available: 400),
          (itemId: 'c', available: 900),
        ],
      );
      expect(takes, [
        (itemId: 'a', amount: 250),
        (itemId: 'b', amount: 400),
        (itemId: 'c', amount: 50),
      ]);
    });

    test('items that are not needed any more are left out', () {
      final takes = fillInOrder(
        needed: 100,
        offers: const [
          (itemId: 'a', available: 100),
          (itemId: 'b', available: 100),
        ],
      );
      expect(takes, [(itemId: 'a', amount: 100)]);
    });

    test('empty items are skipped', () {
      final takes = fillInOrder(
        needed: 100,
        offers: const [
          (itemId: 'a', available: 0),
          (itemId: 'b', available: 150),
        ],
      );
      expect(takes, [(itemId: 'b', amount: 100)]);
    });

    test('stock that is too small gives what exists', () {
      final takes = fillInOrder(
        needed: 500,
        offers: const [
          (itemId: 'a', available: 100),
          (itemId: 'b', available: 50),
        ],
      );
      expect(takes, [(itemId: 'a', amount: 100), (itemId: 'b', amount: 50)]);
      expect(takenAmount(takes), 150);
    });

    test('a line without amount takes the first item with nothing', () {
      final takes = fillInOrder(
        needed: 0,
        offers: const [
          (itemId: 'salt', available: 10),
          (itemId: 'other', available: 10),
        ],
      );
      expect(takes, [(itemId: 'salt', amount: 0)]);
    });

    test('no offers give no takes', () {
      expect(fillInOrder(needed: 0, offers: const []), isEmpty);
      expect(fillInOrder(needed: 10, offers: const []), isEmpty);
    });
  });

  test('takenAmount sums the takes', () {
    expect(takenAmount(const []), 0);
    expect(
      takenAmount(const [(itemId: 'a', amount: 3), (itemId: 'b', amount: 4)]),
      7,
    );
  });
}
