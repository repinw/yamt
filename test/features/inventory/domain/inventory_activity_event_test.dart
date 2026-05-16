import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  test('activity event json roundtrips stable fields', () {
    final event = InventoryActivityEvent(
      id: 'event-1',
      type: InventoryActivityEventType.itemConsumed,
      actorUserId: 'user-1',
      actorDisplayName: 'Alex',
      happenedAt: DateTime.parse('2026-04-07T12:00:00Z'),
      itemId: 'item-1',
      itemName: 'Milk',
      itemBrand: 'Dairy',
      itemImageUrl: 'https://example.com/milk.png',
      amount: 250,
      amountScale: 1,
      itemAmountUnit: InventoryAmountUnit.milliliter,
      beforeQuantity: 1,
      afterQuantity: 1,
      beforeCurrentAmount: 750,
      afterCurrentAmount: 500,
      reason: 'other',
    );

    final decoded = InventoryActivityEvent.fromJson(event.toJson());

    expect(decoded.id, event.id);
    expect(decoded.type, event.type);
    expect(decoded.actorUserId, event.actorUserId);
    expect(decoded.actorDisplayName, event.actorDisplayName);
    expect(decoded.happenedAt, event.happenedAt);
    expect(decoded.itemId, event.itemId);
    expect(decoded.itemName, event.itemName);
    expect(decoded.amount, event.amount);
    expect(decoded.itemAmountUnit, event.itemAmountUnit);
    expect(decoded.beforeCurrentAmount, event.beforeCurrentAmount);
    expect(decoded.afterCurrentAmount, event.afterCurrentAmount);
    expect(decoded.reason, event.reason);
  });
}
