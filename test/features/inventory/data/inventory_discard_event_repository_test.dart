import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

void main() {
  test('readAll skips malformed discard events', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreInventoryDiscardEventRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    final collection = firestore
        .collection('users')
        .doc('user-1')
        .collection('inventory_discard_events');

    await collection.doc('valid').set(<String, dynamic>{
      'id': 'valid',
      'source_type': 'inventoryItem',
      'source_id': 'item-1',
      'name': 'Milk',
      'reason': 'expired',
      'discarded_at': '2026-03-20T10:00:00.000',
      'discarded_amount': 1,
      'discarded_value': 1.5,
      'currency_code': 'EUR',
    });
    await collection.doc('invalid').set(<String, dynamic>{
      'id': 'invalid',
      'source_type': 'inventoryItem',
      'source_id': 'item-2',
      'name': 'Bread',
      'reason': 'spoiled',
      'discarded_at': 'not-a-date',
      'discarded_amount': 1,
      'discarded_value': 2.0,
      'currency_code': 'EUR',
    });

    final events = await repository.readAll();

    expect(events, hasLength(1));
    expect(events.single.id, 'valid');
    expect(events.single.reason, InventoryDiscardReason.expired);
  });
}
