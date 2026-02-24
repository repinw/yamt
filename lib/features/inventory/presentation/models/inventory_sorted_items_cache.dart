import 'package:yamt/features/inventory/domain/fridge_item.dart';

class InventorySortedItemsCache {
  const InventorySortedItemsCache({
    required this.signature,
    required this.sortedItemIds,
  });

  factory InventorySortedItemsCache.fromItems(List<FridgeItem> items) {
    return InventorySortedItemsCache(
      signature: inventorySortSignature(items),
      sortedItemIds: sortedInventoryItemIds(items),
    );
  }

  final String signature;
  final List<String> sortedItemIds;

  InventorySortedItemsCache update(List<FridgeItem> items) {
    final nextSignature = inventorySortSignature(items);
    if (nextSignature == signature) {
      return this;
    }
    return InventorySortedItemsCache.fromItems(items);
  }

  List<FridgeItem> materialize(List<FridgeItem> items) {
    final byId = <String, FridgeItem>{for (final item in items) item.id: item};
    final sorted = <FridgeItem>[];

    for (final itemId in sortedItemIds) {
      final item = byId.remove(itemId);
      if (item != null) {
        sorted.add(item);
      }
    }

    if (sorted.length == items.length) {
      return sorted;
    }
    return sortInventoryItems(items);
  }
}

List<FridgeItem> sortInventoryItems(List<FridgeItem> source) {
  final sorted = List<FridgeItem>.from(source)
    ..sort(compareInventoryItemSortOrder);
  return sorted;
}

List<String> sortedInventoryItemIds(List<FridgeItem> source) {
  return sortInventoryItems(
    source,
  ).map((item) => item.id).toList(growable: false);
}

int compareInventoryItemSortOrder(FridgeItem a, FridgeItem b) {
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

String inventorySortSignature(List<FridgeItem> items) {
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
