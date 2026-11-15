import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

/// The foods of [items] that a recipe line can take: stock left, no deposit
/// or discount line, not one of [held], which have nothing left for the line.
/// With a [query], only those whose name or brand holds each of its words.
/// Sorted by name, then opened packs first, then the oldest.
List<InventoryItem> recipeStockFoods(
  List<InventoryItem> items,
  String query, {
  Set<String> held = const {},
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  bool matches(InventoryItem item) {
    final text = '${item.name} ${item.brand ?? ''}'.toLowerCase();
    return words.every(text.contains);
  }

  return items
      .where(
        (item) =>
            !item.isReviewOnly &&
            !held.contains(item.id) &&
            consumableInventoryAmount(item) != null &&
            matches(item),
      )
      .sorted(_byNameThenEatOrder);
}

int _byNameThenEatOrder(InventoryItem a, InventoryItem b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (byName != 0) return byName;
  if (a.isFullyAvailable != b.isFullyAvailable) {
    return a.isFullyAvailable ? 1 : -1;
  }
  return a.entryDate.compareTo(b.entryDate);
}
