import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_entry_amount_service.dart';

import '../support/inventory_entry_world.dart';

void main() {
  setUpAll(setUpInventoryEntryKeys);

  group('changeAmount', () {
    Future<(InventoryEntryAmountChange, InventoryEntryWorld)> change(
      double amount, {
      int stock = 750,
      bool withItem = true,
    }) async {
      final world = InventoryEntryWorld();
      if (withItem) {
        await world.putItem(milkItem(currentAmount: stock));
      }
      await world.diary.saveEntry(milkEntry());
      final result = await world.amounts.changeAmount(milkEntry(), amount);
      await pumpEventQueue();
      return (result, world);
    }

    test('a larger amount takes more stock in the same write', () async {
      final (result, world) = await change(400);

      expect(result.saved, isTrue);
      expect(result.stock, InventoryEntryStockChange.applied);
      final stored = await world.entry('entry-1');
      expect(stored.consumedAmount, 400);
      expect(stored.sourceInventoryAmountToRestore, 400);
      expect((await world.item('milk')).currentAmount, 600);
      expect(world.reportedStock.last.currentAmount, 600);
      expect(world.reportedStock.last.consumedAt, entryLoggedAt);
    });

    test('a smaller amount gives the difference back', () async {
      final (result, world) = await change(100);

      expect(result.stock, InventoryEntryStockChange.applied);
      final stored = await world.entry('entry-1');
      expect(stored.consumedAmount, 100);
      expect(stored.sourceInventoryAmountToRestore, 100);
      expect((await world.item('milk')).currentAmount, 900);
    });

    test('takes only the stock that is left', () async {
      final (result, world) = await change(400, stock: 50);

      expect(result.stock, InventoryEntryStockChange.stockExhausted);
      final stored = await world.entry('entry-1');
      expect(stored.consumedAmount, 400);
      expect(stored.sourceInventoryAmountToRestore, 300);
      expect((await world.item('milk')).currentAmount, 0);
    });

    test('a missing item changes only the entry', () async {
      final (result, world) = await change(400, withItem: false);

      expect(result.saved, isTrue);
      expect(result.stock, InventoryEntryStockChange.sourceMissing);
      final stored = await world.entry('entry-1');
      expect(stored.consumedAmount, 400);
      expect(stored.sourceInventoryAmountToRestore, 250);
    });

    test('a failed item read saves nothing', () async {
      final world = InventoryEntryWorld();
      await world.diary.saveEntry(milkEntry());
      world.items.readError = StateError('read failed');

      final result = await world.amounts.changeAmount(milkEntry(), 400);

      expect(result.saved, isFalse);
      expect((await world.entry('entry-1')).consumedAmount, 250);
    });
  });
}
