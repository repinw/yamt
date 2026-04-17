import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

InventoryDiscardEvent _discardEvent({String id = 'event-1'}) {
  return InventoryDiscardEvent(
    id: id,
    sourceType: InventoryDiscardSourceType.inventoryItem,
    sourceId: 'item-1',
    name: 'Milk',
    reason: InventoryDiscardReason.expired,
    discardedAt: DateTime.parse('2026-03-20T10:00:00.000Z'),
    discardedAmount: 1,
    discardedValue: 1.5,
    currencyCode: 'EUR',
  );
}

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

  test('readAll normalizes Firestore timestamp values recursively', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreInventoryDiscardEventRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    final collection = firestore
        .collection('users')
        .doc('user-1')
        .collection('inventory_discard_events');
    final discardedAt = DateTime.parse('2026-03-20T10:00:00.000Z');

    await collection.doc('timestamp').set(<String, dynamic>{
      'id': 'timestamp',
      'source_type': 'inventoryItem',
      'source_id': 'item-1',
      'name': 'Milk',
      'reason': 'expired',
      'discarded_at': Timestamp.fromDate(discardedAt),
      'discarded_amount': 1,
      'discarded_value': 1.5,
      'currency_code': 'EUR',
      'metadata': <String, dynamic>{
        'updated_at': Timestamp.fromDate(discardedAt),
        'history': <Object>[
          Timestamp.fromDate(discardedAt),
          <String, dynamic>{
            'nested_at': Timestamp.fromDate(discardedAt),
          },
        ],
      },
    });

    final events = await repository.readAll();

    expect(events, hasLength(1));
    expect(events.single.discardedAt.toUtc(), discardedAt.toUtc());
  });

  test('deleteEvent removes the stored discard event', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreInventoryDiscardEventRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    final collection = firestore
        .collection('users')
        .doc('user-1')
        .collection('inventory_discard_events');

    await collection.doc('delete-me').set(<String, dynamic>{
      'id': 'delete-me',
      'source_type': 'inventoryItem',
      'source_id': 'item-1',
      'name': 'Milk',
      'reason': 'expired',
      'discarded_at': '2026-03-20T10:00:00.000',
      'discarded_amount': 1,
      'discarded_value': 1.5,
      'currency_code': 'EUR',
    });

    final deleted = await repository.deleteEvent('delete-me');

    expect(deleted, isTrue);
    expect(await collection.doc('delete-me').get(), isNotNull);
    expect((await collection.doc('delete-me').get()).exists, isFalse);
  });

  test(
    'saveEvent and deleteEvent return false for invalid repository inputs',
    () async {
      final repositoryWithoutUser = FirestoreInventoryDiscardEventRepository(
        firestore: FakeFirebaseFirestore(),
        currentUserId: null,
      );
      final repositoryWithUser = FirestoreInventoryDiscardEventRepository(
        firestore: FakeFirebaseFirestore(),
        currentUserId: 'user-1',
      );

      expect(await repositoryWithoutUser.saveEvent(_discardEvent()), isFalse);
      expect(await repositoryWithoutUser.deleteEvent('event-1'), isFalse);
      expect(await repositoryWithUser.deleteEvent('   '), isFalse);
    },
  );

  test(
    'provider falls back to unavailable repository without firestore',
    () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(null),
          ),
          effectiveHouseholdDataOwnerUserIdProvider.overrideWith(
            (ref) => 'user-1',
          ),
          firebaseFirestoreProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(
        inventoryDiscardEventRepositoryProvider,
      );

      expect(await repository.readAll(), isEmpty);
      expect(
        await repository.saveEvent(_discardEvent(id: 'fallback')),
        isFalse,
      );
      expect(await repository.deleteEvent('fallback'), isFalse);
    },
  );
}
