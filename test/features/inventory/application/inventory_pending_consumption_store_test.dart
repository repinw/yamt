import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

final DateTime _now = DateTime.parse('2026-10-05T12:00:00Z');

InventoryItem _gramItem() {
  return InventoryItem.create(
    id: 'waffles',
    name: 'Waffles',
    entryDate: _now,
    storeName: 'Aldi',
    quantity: 2,
    initialQuantity: 2,
    initialAmount: 1000,
    currentAmount: 750,
    amountUnit: InventoryAmountUnit.gram,
  );
}

InventoryItem _pieceItem({int quantity = 6}) {
  return InventoryItem.create(
    id: 'eggs',
    name: 'Eggs',
    entryDate: _now,
    storeName: 'Aldi',
    quantity: quantity,
  );
}

InventoryPendingConsumptionStore _store() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(inventoryPendingConsumptionStoreProvider);
}

void main() {
  test('stage caps the amount at the stock and gives each its own id', () {
    final pendings = _store();

    final first = pendings.stage(_gramItem(), 900);
    final second = pendings.stage(_gramItem(), 100);

    expect(first?.itemId, 'waffles');
    expect(first?.amount, 750);
    expect(second?.amount, 100);
    expect(first?.id, isNot(second?.id));
    expect(pendings.pendingConsumptionById(first!.id), isNotNull);
  });

  test('stage reserves nothing from an empty item or below one', () {
    final pendings = _store();

    expect(pendings.stage(_pieceItem(quantity: 0), 1), isNull);
    expect(pendings.stage(_pieceItem(), 0), isNull);
  });
}
