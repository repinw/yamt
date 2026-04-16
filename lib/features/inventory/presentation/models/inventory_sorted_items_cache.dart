import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';

/// Defines inventory sorted items cache.
class InventorySortedItemsCache {
  /// The inventory sorted items cache.
  const InventorySortedItemsCache({
    required this.signature,
    required this.sortedItemIds,
    required this.sortMode,
  });

  /// Creates a [InventorySortedItemsCache] for from items.
  factory InventorySortedItemsCache.fromItems(
    List<InventoryItem> items, {
    required InventoryItemSortMode sortMode,
  }) {
    return InventorySortedItemsCache(
      signature: _inventorySortSignature(items, sortMode: sortMode),
      sortedItemIds: _sortedInventoryItemIds(items, sortMode: sortMode),
      sortMode: sortMode,
    );
  }

  /// The signature.
  final String signature;

  /// The sorted item ids.
  final List<String> sortedItemIds;

  /// The sort mode.
  final InventoryItemSortMode sortMode;

  /// Update.
  InventorySortedItemsCache update(
    List<InventoryItem> items, {
    required InventoryItemSortMode sortMode,
  }) {
    final nextSignature = _inventorySortSignature(items, sortMode: sortMode);
    if (nextSignature == signature) {
      return this;
    }
    return InventorySortedItemsCache.fromItems(items, sortMode: sortMode);
  }

  /// Materialize.
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
      return sortInventoryItems(items, sortMode: sortMode);
    }

    return sortedItemIds.map((itemId) => byId[itemId]!).toList(growable: false);
  }
}

/// Sort inventory items.
List<InventoryItem> sortInventoryItems(
  List<InventoryItem> source, {
  required InventoryItemSortMode sortMode,
}) {
  final sorted = List<InventoryItem>.from(source)
    ..sort(
      (left, right) =>
          _compareInventoryItemSortOrder(left, right, sortMode: sortMode),
    );
  return sorted;
}

List<String> _sortedInventoryItemIds(
  List<InventoryItem> source, {
  required InventoryItemSortMode sortMode,
}) {
  return sortInventoryItems(
    source,
    sortMode: sortMode,
  ).map((item) => item.id).toList(growable: false);
}

int _compareInventoryItemSortOrder(
  InventoryItem a,
  InventoryItem b, {
  required InventoryItemSortMode sortMode,
}) {
  switch (sortMode) {
    case InventoryItemSortMode.recentlyAddedDescending:
      final dateCompare = _compareInventoryItemEntryDate(
        a,
        b,
        descending: true,
      );
      if (dateCompare != 0) {
        return dateCompare;
      }
      return _compareInventoryItemName(a, b);
    case InventoryItemSortMode.recentlyAddedAscending:
      final dateCompare = _compareInventoryItemEntryDate(
        a,
        b,
        descending: false,
      );
      if (dateCompare != 0) {
        return dateCompare;
      }
      return _compareInventoryItemName(a, b);
    case InventoryItemSortMode.recentlyEatenDescending:
      final consumedCompare = _compareNullableDate(
        a.lastConsumedAt,
        b.lastConsumedAt,
        descending: true,
      );
      if (consumedCompare != 0) {
        return consumedCompare;
      }
      final dateCompare = _compareInventoryItemEntryDate(
        a,
        b,
        descending: true,
      );
      if (dateCompare != 0) {
        return dateCompare;
      }
      return _compareInventoryItemName(a, b);
    case InventoryItemSortMode.recentlyEatenAscending:
      final consumedCompare = _compareNullableDate(
        a.lastConsumedAt,
        b.lastConsumedAt,
        descending: false,
      );
      if (consumedCompare != 0) {
        return consumedCompare;
      }
      final dateCompare = _compareInventoryItemEntryDate(
        a,
        b,
        descending: false,
      );
      if (dateCompare != 0) {
        return dateCompare;
      }
      return _compareInventoryItemName(a, b);
    case InventoryItemSortMode.alphabeticalAscending:
      final nameCompare = _compareInventoryItemName(a, b);
      if (nameCompare != 0) {
        return nameCompare;
      }
      return b.entryDate.compareTo(a.entryDate);
    case InventoryItemSortMode.alphabeticalDescending:
      final nameCompare = _compareInventoryItemName(b, a);
      if (nameCompare != 0) {
        return nameCompare;
      }
      return b.entryDate.compareTo(a.entryDate);
    case InventoryItemSortMode.availableAmountAscending:
      final ratioCompare = _availableAmountRatio(
        a,
      ).compareTo(_availableAmountRatio(b));
      if (ratioCompare != 0) {
        return ratioCompare;
      }
      return _compareInventoryItemName(a, b);
    case InventoryItemSortMode.availableAmountDescending:
      final ratioCompare = _availableAmountRatio(
        b,
      ).compareTo(_availableAmountRatio(a));
      if (ratioCompare != 0) {
        return ratioCompare;
      }
      return _compareInventoryItemName(a, b);
  }
}

String _inventorySortSignature(
  List<InventoryItem> items, {
  required InventoryItemSortMode sortMode,
}) {
  final buffer = StringBuffer()
    ..write(sortMode.name)
    ..write(':')
    ..write(items.length);

  for (final item in items) {
    buffer
      ..write('|')
      ..write(item.id)
      ..write(':')
      ..write(item.name.toLowerCase())
      ..write(':')
      ..write(item.entryDate.microsecondsSinceEpoch)
      ..write(':')
      ..write(item.quantity)
      ..write(':')
      ..write(item.initialQuantity)
      ..write(':')
      ..write(item.currentAmount)
      ..write(':')
      ..write(item.initialAmount)
      ..write(':')
      ..write(item.amountUnit?.code ?? '')
      ..write(':')
      ..write(item.lastConsumedAt?.microsecondsSinceEpoch ?? -1);
  }

  return buffer.toString();
}

int _compareInventoryItemName(InventoryItem a, InventoryItem b) {
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (nameCompare != 0) {
    return nameCompare;
  }
  return a.id.compareTo(b.id);
}

int _compareInventoryItemEntryDate(
  InventoryItem a,
  InventoryItem b, {
  required bool descending,
}) {
  if (descending) {
    return b.entryDate.compareTo(a.entryDate);
  }
  return a.entryDate.compareTo(b.entryDate);
}

int _compareNullableDate(
  DateTime? left,
  DateTime? right, {
  required bool descending,
}) {
  if (left != null && right != null) {
    if (descending) {
      return right.compareTo(left);
    }
    return left.compareTo(right);
  }
  if (left == null && right == null) {
    return 0;
  }
  return left == null ? 1 : -1;
}

double _availableAmountRatio(InventoryItem item) {
  if (item.usesAmountProgress) {
    final initialAmount = item.initialAmount;
    if (initialAmount <= 0) {
      return 0;
    }
    final remainingAmount = item.currentAmount.clamp(0, initialAmount);
    return remainingAmount / initialAmount;
  }

  final initialQuantity = item.effectiveInitialQuantity;
  if (initialQuantity <= 0) {
    return 0;
  }
  final remainingQuantity = item.quantity.clamp(0, initialQuantity);
  return remainingQuantity / initialQuantity;
}
