import 'package:yamt/features/inventory/domain/inventory_item.dart';

class InventorySortedItemsCache {
  const InventorySortedItemsCache({
    required this.signature,
    required this.sortedItemIds,
  });

  factory InventorySortedItemsCache.fromItems(List<InventoryItem> items) {
    return InventorySortedItemsCache(
      signature: inventorySortSignature(items),
      sortedItemIds: sortedInventoryItemIds(items),
    );
  }

  final String signature;
  final List<String> sortedItemIds;

  InventorySortedItemsCache update(List<InventoryItem> items) {
    final nextSignature = inventorySortSignature(items);
    if (nextSignature == signature) {
      return this;
    }
    return InventorySortedItemsCache.fromItems(items);
  }

  List<InventoryItem> materialize(List<InventoryItem> items) {
    final byId = <String, InventoryItem>{
      for (final item in items) item.id: item,
    };
    final hasConsistentIds = byId.length == sortedItemIds.length;
    assert(
      hasConsistentIds,
      'InventorySortedItemsCache received inconsistent item ids.',
    );
    if (!hasConsistentIds) {
      return sortInventoryItems(items);
    }

    return sortedItemIds.map((itemId) => byId[itemId]!).toList(growable: false);
  }
}

List<InventoryItem> sortInventoryItems(List<InventoryItem> source) {
  final sorted = List<InventoryItem>.from(source)
    ..sort(compareInventoryItemSortOrder);
  return sorted;
}

List<String> sortedInventoryItemIds(List<InventoryItem> source) {
  return sortInventoryItems(
    source,
  ).map((item) => item.id).toList(growable: false);
}

int compareInventoryItemSortOrder(InventoryItem a, InventoryItem b) {
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) {
    return nameCompare;
  }

  final dateCompare = b.entryDate.compareTo(a.entryDate);
  if (dateCompare != 0) {
    return dateCompare;
  }

  return a.id.compareTo(b.id);
}

String inventorySortSignature(List<InventoryItem> items) {
  final buffer = StringBuffer()..write(items.length);

  for (final item in items) {
    buffer
      ..write('|')
      ..write(item.id)
      ..write(':')
      ..write(item.name.toLowerCase())
      ..write(':')
      ..write(item.entryDate.microsecondsSinceEpoch);
  }

  return buffer.toString();
}
