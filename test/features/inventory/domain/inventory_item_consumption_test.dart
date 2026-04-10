import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

InventoryItem _item({DateTime? lastConsumedAt}) {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 2,
    initialQuantity: 2,
    unitPrice: 1,
    lastConsumedAt: lastConsumedAt,
  );
}

void main() {
  test('latestConsumedAtOr returns candidate when no timestamp exists', () {
    final item = _item();
    final candidate = DateTime.parse('2026-02-20T12:00:00Z');

    expect(item.latestConsumedAtOr(candidate), candidate);
  });

  test('latestConsumedAtOr keeps newer current timestamp', () {
    final current = DateTime.parse('2026-02-21T12:00:00Z');
    final olderCandidate = DateTime.parse('2026-02-20T12:00:00Z');
    final item = _item(lastConsumedAt: current);

    expect(item.latestConsumedAtOr(olderCandidate), current);
  });

  test('latestConsumedAtOr accepts a newer candidate timestamp', () {
    final current = DateTime.parse('2026-02-20T12:00:00Z');
    final newerCandidate = DateTime.parse('2026-02-21T12:00:00Z');
    final item = _item(lastConsumedAt: current);

    expect(item.latestConsumedAtOr(newerCandidate), newerCandidate);
  });
}
