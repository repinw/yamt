import 'dart:developer' show log;

import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Inventory repository that remembers the items of its last successful write,
/// so a prepared meal mutation can record the stock it used or returned.
class PreparedMealStockTrackingRepository implements InventoryItemRepository {
  /// Creates a tracking repository that starts from [initialItems].
  new({required this._delegate, required List<InventoryItem> initialItems})
    : _latestItems = List<InventoryItem>.from(initialItems);

  final InventoryItemRepository _delegate;
  List<InventoryItem> _latestItems;

  /// The items after the last successful write.
  List<InventoryItem> get latestItems => List<InventoryItem>.from(_latestItems);

  @override
  Stream<List<InventoryItem>> watchAll() {
    return _delegate.watchAll();
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return latestItems;
  }

  @override
  Future<List<InventoryItem>> readAllLocal() async {
    return latestItems;
  }

  @override
  Future<bool> save(InventoryItem item) async {
    final saved = await _delegate.save(item);
    if (saved) {
      _latestItems = _upsertItems(_latestItems, [item]);
    }
    return saved;
  }

  @override
  Future<bool> delete(String itemId) async {
    final saved = await _delegate.delete(itemId);
    if (saved) {
      _latestItems = [
        for (final item in _latestItems)
          if (item.id != itemId) item,
      ];
    }
    return saved;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    final saved = await _delegate.appendAll(items);
    if (saved) {
      _latestItems = _upsertItems(_latestItems, items);
    }
    return saved;
  }
}

/// Appends one activity event per item whose stock changed between
/// [beforeItems] and [afterItems] during a prepared meal mutation.
Future<void> recordPreparedMealStockActivity({
  required InventoryActivityActor? actor,
  required InventoryActivityEventRepository activityRepository,
  required List<InventoryItem> beforeItems,
  required List<InventoryItem> afterItems,
  required String Function() buildId,
  required String logName,
}) async {
  if (actor == null) {
    return;
  }

  final events = _buildPreparedMealInventoryDiffEvents(
    actor: actor,
    beforeItems: beforeItems,
    afterItems: afterItems,
    buildId: buildId,
  );
  if (events.isEmpty) {
    return;
  }

  final saved = await activityRepository.appendAll(events);
  if (!saved) {
    log(
      'Failed to record prepared meal inventory activity events.',
      name: logName,
    );
  }
}

List<InventoryItem> _upsertItems(
  List<InventoryItem> currentItems,
  List<InventoryItem> items,
) {
  if (items.isEmpty) {
    return List<InventoryItem>.from(currentItems);
  }

  final itemsById = <String, InventoryItem>{
    for (final item in currentItems) item.id: item,
  };
  for (final item in items) {
    itemsById[item.id] = item;
  }
  return itemsById.values.toList(growable: false);
}

List<InventoryActivityEvent> _buildPreparedMealInventoryDiffEvents({
  required InventoryActivityActor actor,
  required List<InventoryItem> beforeItems,
  required List<InventoryItem> afterItems,
  required String Function() buildId,
}) {
  final beforeById = <String, InventoryItem>{
    for (final item in beforeItems) item.id: item,
  };
  final afterById = <String, InventoryItem>{
    for (final item in afterItems) item.id: item,
  };
  final itemIds = <String>{...beforeById.keys, ...afterById.keys};
  final events = <InventoryActivityEvent>[];

  for (final itemId in itemIds) {
    final beforeItem = beforeById[itemId];
    final afterItem = afterById[itemId];
    final beforeAmount = beforeItem == null ? 0 : _stockAmount(beforeItem);
    final afterAmount = afterItem == null ? 0 : _stockAmount(afterItem);
    final delta = afterAmount - beforeAmount;
    if (delta == 0) {
      continue;
    }

    final eventItem = delta < 0 ? beforeItem : afterItem;
    if (eventItem == null) {
      continue;
    }

    events.add(
      InventoryActivityEvent.fromStockChange(
        id: buildId(),
        type: delta < 0
            ? InventoryActivityEventType.itemUsedInPreparedMeal
            : InventoryActivityEventType.itemReturnedFromPreparedMeal,
        actor: actor,
        item: eventItem,
        amount: delta.abs(),
        beforeQuantity: beforeItem?.quantity,
        afterQuantity: afterItem?.quantity,
        beforeCurrentAmount: beforeItem?.currentAmount,
        afterCurrentAmount: afterItem?.currentAmount,
      ),
    );
  }

  return events;
}

int _stockAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    return item.currentAmount;
  }
  return item.quantity;
}
