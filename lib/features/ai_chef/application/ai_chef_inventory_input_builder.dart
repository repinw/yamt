import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

const _maxInventoryIngredients = 40;

/// Builds pantry inventory entries for the AI Chef prompt.
class AiChefInventoryInputBuilder {
  /// Creates the builder.
  const new();

  /// Returns active inventory entries formatted for prompt input.
  List<String> build(List<InventoryItem> items) {
    return items
        .where(_canUseInventoryItem)
        .map(_formatInventoryItem)
        .where((ingredient) => ingredient.isNotEmpty)
        .take(_maxInventoryIngredients)
        .toList(growable: false);
  }

  /// Returns [items] without the stock that open plans and running cook runs
  /// keep, [reservedOf] an item id in the pack's stored unit ("verplant"): a
  /// pack kept in full is left out, a pack kept in part counts with what is
  /// left.
  List<InventoryItem> freeStock(
    List<InventoryItem> items,
    int Function(String itemId) reservedOf,
  ) {
    return [for (final item in items) ?_free(item, reservedOf(item.id))];
  }

  InventoryItem? _free(InventoryItem item, int reserved) {
    if (reserved < 1) {
      return item;
    }
    if (reserved >= item.availableAmount) {
      return null;
    }
    return item.reducedBy(reserved);
  }

  /// Returns the items the user can pick to use up, the longest in stock
  /// first.
  List<InventoryItem> pickableOldestFirst(List<InventoryItem> items) {
    return items.where(_canUseInventoryItem).toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  /// Full calendar days that [item] has been in stock on [today].
  int daysInStock(InventoryItem item, DateTime today) {
    final entry = item.entryDate.toLocal();
    final start = DateTime.utc(entry.year, entry.month, entry.day);
    final end = DateTime.utc(today.year, today.month, today.day);
    final days = end.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  bool _canUseInventoryItem(InventoryItem item) {
    return item.canBeSavedToInventory &&
        !item.isFullyConsumed &&
        item.name.trim().isNotEmpty;
  }

  String _formatInventoryItem(InventoryItem item) {
    final name = item.name.trim();
    final details = <String>[];
    final amount = _formatInventoryAmount(item);
    if (amount != null) {
      details.add('available: $amount');
    }
    final brand = item.brand?.trim();
    if (brand != null && brand.isNotEmpty) {
      details.add('brand: $brand');
    }
    final category = item.category?.trim();
    if (category != null && category.isNotEmpty) {
      details.add('category: $category');
    }
    if (details.isEmpty) {
      return name;
    }
    return '$name (${details.join(', ')})';
  }

  String? _formatInventoryAmount(InventoryItem item) {
    if (item.usesAmountProgress) {
      return _formatProgressAmount(item);
    }
    final weight = item.weight?.trim();
    if (item.quantity > 1 && weight != null && weight.isNotEmpty) {
      return '${item.quantity} x $weight';
    }
    if (weight != null && weight.isNotEmpty) {
      return weight;
    }
    if (item.quantity > 0) {
      return '${item.quantity} x';
    }
    return null;
  }

  String? _formatProgressAmount(InventoryItem item) {
    final unit = item.amountUnit;
    if (unit == null || item.currentAmount <= 0) {
      return null;
    }
    final amount = formatInventoryAmountValue(
      amount: item.currentAmount,
      unit: unit,
      scale: item.amountScale,
    );
    return '$amount ${unit.code}';
  }
}
