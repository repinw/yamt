import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

void main() {
  test('fromJson throws for an invalid discarded_at value', () {
    expect(
      () => InventoryDiscardEvent.fromJson(<String, dynamic>{
        'id': 'event-1',
        'source_type': 'inventoryItem',
        'source_id': 'item-1',
        'name': 'Milk',
        'reason': 'expired',
        'discarded_at': 'not-a-date',
        'discarded_amount': 1,
        'discarded_value': 1.5,
        'currency_code': 'EUR',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
