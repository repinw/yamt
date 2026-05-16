import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';

void main() {
  test('repository appends and watches recent events newest first', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreInventoryActivityEventRepository(
      firestore: firestore,
      currentUserId: 'owner-1',
    );
    final older = _event(
      id: 'event-1',
      happenedAt: DateTime.parse('2026-04-07T10:00:00Z'),
    );
    final newer = _event(
      id: 'event-2',
      happenedAt: DateTime.parse('2026-04-07T11:00:00Z'),
    );

    final saved = await repository.appendAll(<InventoryActivityEvent>[
      older,
      newer,
    ]);

    expect(saved, isTrue);
    await expectLater(
      repository.watchRecent(limit: 10),
      emits(
        predicate<List<InventoryActivityEvent>>(
          (events) =>
              events.length == 2 &&
              events[0].id == 'event-2' &&
              events[1].id == 'event-1',
        ),
      ),
    );
  });

  test('repository chunks appends beyond Firestore batch limit', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreInventoryActivityEventRepository(
      firestore: firestore,
      currentUserId: 'owner-1',
    );
    final events = List<InventoryActivityEvent>.generate(501, (index) {
      return _event(
        id: 'event-$index',
        happenedAt: DateTime.utc(
          2026,
          4,
          7,
          10,
        ).add(Duration(minutes: index)),
      );
    });

    final saved = await repository.appendAll(events);

    expect(saved, isTrue);
    final watchedEvents = await repository.watchRecent(limit: 501).first;
    expect(watchedEvents, hasLength(501));
    expect(watchedEvents.first.id, 'event-500');
    expect(watchedEvents.last.id, 'event-0');
  });
}

InventoryActivityEvent _event({
  required String id,
  required DateTime happenedAt,
}) {
  return InventoryActivityEvent(
    id: id,
    type: InventoryActivityEventType.itemAdded,
    actorUserId: 'user-1',
    actorDisplayName: 'Alex',
    happenedAt: happenedAt,
    itemId: 'item-1',
    itemName: 'Milk',
    amount: 1,
    amountScale: 1,
    beforeQuantity: null,
    afterQuantity: 1,
    beforeCurrentAmount: null,
    afterCurrentAmount: 0,
  );
}
