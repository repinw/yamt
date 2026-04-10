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
  test('apply shows fully consumed items by default', () {
    final items = <InventoryItem>[
      _item(id: 'fresh', quantity: 2, initialQuantity: 2),
      _item(id: 'partial', quantity: 1, initialQuantity: 2),
      _item(id: 'empty', quantity: 0, initialQuantity: 2),
    ];

    const filter = InventoryConsumptionFilter();
    final result = filter.apply(items);

    expect(result.map((item) => item.id), <String>[
      'fresh',
      'partial',
      'empty',
    ]);
  });

  test('apply hides fully consumed items when enabled', () {
    final items = <InventoryItem>[
      _item(id: 'fresh', quantity: 2, initialQuantity: 2),
      _item(id: 'partial', quantity: 1, initialQuantity: 2),
      _item(id: 'empty', quantity: 0, initialQuantity: 2),
    ];

    const filter = InventoryConsumptionFilter(hideFullyConsumedItems: true);
    final result = filter.apply(items);

    expect(result.map((item) => item.id), <String>['fresh', 'partial']);
  });

  test('copyWith updates fully consumed visibility', () {
    const filter = InventoryConsumptionFilter();

    final next = filter.copyWith(hideFullyConsumedItems: true);

    expect(next.hideFullyConsumedItems, isTrue);
    expect(
      const InventoryConsumptionFilter(
        hideFullyConsumedItems: true,
      ).hideFullyConsumedItems,
      isTrue,
    );
  });
}
