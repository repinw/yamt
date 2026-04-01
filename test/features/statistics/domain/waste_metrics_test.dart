import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/statistics/domain/waste_metrics.dart';

InventoryDiscardEvent _event({
  required String id,
  required String name,
  required InventoryDiscardReason reason,
  required DateTime discardedAt,
  required double discardedValue,
  String? currencyCode = 'EUR',
}) {
  return InventoryDiscardEvent(
    id: id,
    sourceType: InventoryDiscardSourceType.inventoryItem,
    sourceId: 'source-$id',
    name: name,
    reason: reason,
    discardedAt: discardedAt,
    discardedAmount: 1,
    discardedValue: discardedValue,
    currencyCode: currencyCode,
  );
}

void main() {
  test('buildStatisticsWasteSnapshot returns empty snapshot for no events', () {
    final snapshot = buildStatisticsWasteSnapshot(
      events: const <InventoryDiscardEvent>[],
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 21),
    );

    expect(snapshot.hasData, isFalse);
    expect(snapshot.totalEvents, 0);
    expect(snapshot.totalDiscardedValue, 0);
    expect(snapshot.currencyCode, isNull);
    expect(snapshot.topReason, isNull);
    expect(snapshot.topItemName, isNull);
  });

  test('aggregates valid events within the inclusive date window', () {
    final snapshot = buildStatisticsWasteSnapshot(
      events: [
        _event(
          id: 'start',
          name: 'Bananas',
          reason: InventoryDiscardReason.expired,
          discardedAt: DateTime(2026, 3, 20, 0, 1),
          discardedValue: 2.5,
        ),
        _event(
          id: 'middle',
          name: 'Bananas',
          reason: InventoryDiscardReason.expired,
          discardedAt: DateTime(2026, 3, 20, 23, 59),
          discardedValue: 1.5,
        ),
        _event(
          id: 'end',
          name: 'Bread',
          reason: InventoryDiscardReason.spoiled,
          discardedAt: DateTime(2026, 3, 21, 22),
          discardedValue: 3,
        ),
      ],
      startDate: DateTime(2026, 3, 20, 12),
      endDate: DateTime(2026, 3, 21),
    );

    expect(snapshot.hasData, isTrue);
    expect(snapshot.totalEvents, 3);
    expect(snapshot.totalDiscardedValue, 7);
    expect(snapshot.currencyCode, 'EUR');
    expect(snapshot.topReason, InventoryDiscardReason.expired);
    expect(snapshot.topReasonCount, 2);
    expect(snapshot.topItemName, 'Bananas');
    expect(snapshot.topItemCount, 2);
  });

  test('excludes out-of-range events but keeps zero-value events counted', () {
    final snapshot = buildStatisticsWasteSnapshot(
      events: [
        _event(
          id: 'before',
          name: 'Milk',
          reason: InventoryDiscardReason.expired,
          discardedAt: DateTime(2026, 3, 19, 23, 59),
          discardedValue: 4,
        ),
        _event(
          id: 'inside',
          name: 'Herbs',
          reason: InventoryDiscardReason.other,
          discardedAt: DateTime(2026, 3, 20, 8),
          discardedValue: 0,
        ),
        _event(
          id: 'after',
          name: 'Rice',
          reason: InventoryDiscardReason.spoiled,
          discardedAt: DateTime(2026, 3, 22),
          discardedValue: 5,
        ),
      ],
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 21),
    );

    expect(snapshot.hasData, isTrue);
    expect(snapshot.totalEvents, 1);
    expect(snapshot.totalDiscardedValue, 0);
    expect(snapshot.topReason, InventoryDiscardReason.other);
    expect(snapshot.topItemName, 'Herbs');
  });

  test('keeps the first seen entry when top counts are tied', () {
    final snapshot = buildStatisticsWasteSnapshot(
      events: [
        _event(
          id: 'first-reason',
          name: 'Apples',
          reason: InventoryDiscardReason.expired,
          discardedAt: DateTime(2026, 3, 20, 8),
          discardedValue: 1,
        ),
        _event(
          id: 'first-item',
          name: 'Bread',
          reason: InventoryDiscardReason.spoiled,
          discardedAt: DateTime(2026, 3, 20, 9),
          discardedValue: 1,
        ),
        _event(
          id: 'second-reason',
          name: 'Bread',
          reason: InventoryDiscardReason.expired,
          discardedAt: DateTime(2026, 3, 20, 10),
          discardedValue: 1,
        ),
        _event(
          id: 'second-item',
          name: 'Apples',
          reason: InventoryDiscardReason.spoiled,
          discardedAt: DateTime(2026, 3, 20, 11),
          discardedValue: 1,
        ),
      ],
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 20),
    );

    expect(snapshot.topReason, InventoryDiscardReason.expired);
    expect(snapshot.topReasonCount, 2);
    expect(snapshot.topItemName, 'Apples');
    expect(snapshot.topItemCount, 2);
  });
}
