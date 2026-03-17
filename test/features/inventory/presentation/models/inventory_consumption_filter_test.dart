import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_consumption_filter.dart';

InventoryItem _item({
  required String id,
  required int quantity,
  required int initialQuantity,
}) {
  return InventoryItem.create(
    id: id,
    name: id,
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: 'Store',
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: 1.0,
  );
}

void main() {
  test('apply filters by consumption flags', () {
    final items = <InventoryItem>[
      _item(id: 'fresh', quantity: 2, initialQuantity: 2),
      _item(id: 'partial', quantity: 1, initialQuantity: 2),
      _item(id: 'empty', quantity: 0, initialQuantity: 2),
    ];

    const consumedOnly = InventoryConsumptionFilter(
      showConsumed: true,
      showNotConsumed: false,
    );
    const notConsumedOnly = InventoryConsumptionFilter(
      showConsumed: false,
      showNotConsumed: true,
    );

    final consumedResult = consumedOnly.apply(items);
    final notConsumedResult = notConsumedOnly.apply(items);

    expect(consumedResult.map((item) => item.id), <String>['partial', 'empty']);
    expect(notConsumedResult.map((item) => item.id), <String>['fresh']);
  });

  test('toggleConsumed(false) keeps same instance if not-consumed is off', () {
    const filter = InventoryConsumptionFilter(
      showConsumed: true,
      showNotConsumed: false,
    );

    final next = filter.toggleConsumed(false);
    expect(identical(next, filter), isTrue);
  });

  test('toggleNotConsumed(false) keeps same instance if consumed is off', () {
    const filter = InventoryConsumptionFilter(
      showConsumed: false,
      showNotConsumed: true,
    );

    final next = filter.toggleNotConsumed(false);
    expect(identical(next, filter), isTrue);
  });
}
