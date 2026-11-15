import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';

import '../kochmodus_fixtures.dart';

void main() {
  final grams = stockItem('g', 1000);
  final millis = stockItem('ml', 500, unit: InventoryAmountUnit.milliliter);
  // 3 pieces of 60 g, kept as a thousand per piece.
  final eggs = stockItem(
    'egg',
    3000,
    unit: InventoryAmountUnit.piece,
    scale: 1000,
    servingQuantity: 60,
    servingQuantityUnit: 'g',
  );
  final eggsNoServing = stockItem(
    'egg-none',
    3000,
    unit: InventoryAmountUnit.piece,
    scale: 1000,
  );
  final pack = packItem('pack', 2);
  final items = byId([grams, millis, eggs, eggsNoServing, pack]);

  CookLineWeight weight(
    Map<String, int> takes, {
    int? weighed,
    LineSettlement? settlement,
    CookLineAmountKind kind = CookLineAmountKind.weight,
  }) => cookLineWeight(
    textLine(
      'l',
      'text',
      settlement: settlement ?? assigned(takes),
      weighed: weighed,
    ),
    items,
    kind: kind,
  );

  group('cookLineWeight', () {
    test('an ignored line is not counted, even with a weight', () {
      expect(
        weight(const {}, settlement: const LineIgnored(), weighed: 50),
        const CookWeightNotCounted(),
      );
    });

    test('what the cook weighed wins over the takes', () {
      expect(weight({'g': 200}, weighed: 180), const CookWeightWeighed(180));
    });

    test('a weighed line needs no assignment', () {
      expect(
        weight(const {}, weighed: 90, settlement: const LineOpen()),
        const CookWeightWeighed(90),
      );
    });

    test('takes from grams and ml are exact and add up', () {
      expect(weight({'g': 200}), const CookWeightExact(200));
      expect(weight({'ml': 250}), const CookWeightExact(250));
      expect(weight({'g': 200, 'ml': 100}), const CookWeightExact(300));
    });

    test('pieces with a serving size are estimated', () {
      expect(weight({'egg': 2000}), const CookWeightEstimated(120));
    });

    test('one estimated take makes the whole line estimated', () {
      expect(weight({'g': 100, 'egg': 1000}), const CookWeightEstimated(160));
    });

    test('a line in spoons on grams is estimated, never a fact, to weigh', () {
      expect(
        weight({'g': 15}, kind: CookLineAmountKind.spoons),
        const CookWeightEstimated(15, toWeigh: true),
      );
    });

    test('a line in spoons on an item kept in pieces is not to weigh', () {
      expect(
        weight({'egg': 1000}, kind: CookLineAmountKind.spoons),
        const CookWeightEstimated(60),
      );
    });

    test('a line in pieces or without an amount on grams is to weigh', () {
      expect(
        weight({'g': 150}, kind: CookLineAmountKind.other),
        const CookWeightEstimated(150, toWeigh: true),
      );
      expect(
        weight({'ml': 150}, kind: CookLineAmountKind.other),
        const CookWeightEstimated(150, toWeigh: true),
      );
    });

    test('a line in pieces on an item kept in pieces is not to weigh', () {
      expect(
        weight({'egg': 2000}, kind: CookLineAmountKind.other),
        const CookWeightEstimated(120),
      );
    });

    test('a weighed line stays weighed whatever its kind', () {
      expect(
        weight({'g': 150}, kind: CookLineAmountKind.other, weighed: 120),
        const CookWeightWeighed(120),
      );
    });

    test('pieces without a serving size are missing', () {
      expect(weight({'egg-none': 1000}), const CookWeightMissing());
    });

    test('whole packs are missing', () {
      expect(weight({'pack': 1}), const CookWeightMissing());
    });

    test('a gone item makes the weight missing', () {
      expect(weight({'g': 100, 'gone': 5}), const CookWeightMissing());
    });

    test('an unassigned line is missing', () {
      expect(
        weight(const {}, settlement: const LineOpen()),
        const CookWeightMissing(),
      );
      expect(
        weight(const {}, settlement: const LineShopping()),
        const CookWeightMissing(),
      );
    });

    test('takes of 0 are missing, never a silent 0 g', () {
      expect(weight({'g': 0}), const CookWeightMissing());
    });
  });
}
