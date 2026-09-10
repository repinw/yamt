import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_product_matcher.dart';

/// Aggregated purchase and stock facts for one product.
class InventoryReplenishment {
  /// Creates replenishment facts.
  const InventoryReplenishment({
    required this.name,
    required this.brand,
    required this.purchaseCount,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.latest,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Distinct receipts within the history window.
  final int purchaseCount;

  /// At most a quarter of one pack remains across all batches.
  final bool isLowStock;

  /// Whether no stock remains across any batch.
  final bool isOutOfStock;

  /// Most recent purchase or consumption.
  final DateTime latest;
}

/// Evaluates stock across all batches and purchases from the last 180 days.
List<InventoryReplenishment> inventoryReplenishment(
  List<InventoryItem> items,
  DateTime now,
) {
  final groups = _groupProducts(items, now);
  final results =
      groups
          .map((group) => _summarize(group, now))
          .where((item) => item.isLowStock || item.purchaseCount >= 2)
          .toList()
        ..sort(_compare);
  return results;
}

List<List<InventoryItem>> _groupProducts(
  List<InventoryItem> items,
  DateTime now,
) {
  final groups = <List<InventoryItem>>[];
  for (final item in items) {
    if (!_canSuggest(item, now)) continue;
    _addToMatchingGroups(groups, item);
  }
  return groups;
}

bool _canSuggest(InventoryItem item, DateTime now) =>
    !item.isReviewOnly &&
    item.name.trim().isNotEmpty &&
    !item.entryDate.isAfter(now);

void _addToMatchingGroups(
  List<List<InventoryItem>> groups,
  InventoryItem item,
) {
  final matches = groups.where((group) => _matchesGroup(group, item)).toList();
  if (matches.isEmpty) {
    groups.add([item]);
    return;
  }
  matches.first.add(item);
  for (final group in matches.skip(1)) {
    matches.first.addAll(group);
    groups.remove(group);
  }
}

bool _matchesGroup(List<InventoryItem> group, InventoryItem candidate) =>
    group.any(
      (item) =>
          _sameBrand(item.brand, candidate.brand) &&
          InventoryProductMatcher.matches(item.name, candidate.name),
    );

bool _sameBrand(String? left, String? right) =>
    (left?.trim().toLowerCase() ?? '') == (right?.trim().toLowerCase() ?? '');

InventoryReplenishment _summarize(List<InventoryItem> items, DateTime now) {
  items.sort((a, b) => b.entryDate.compareTo(a.entryDate));
  final latest = items
      .map((item) => item.lastConsumedAt ?? item.entryDate)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final packs = items.fold<double>(
    0,
    (sum, item) => sum + _remainingPacks(item),
  );
  return InventoryReplenishment(
    name: items.first.name.trim(),
    brand: items.first.brand,
    purchaseCount: _receipts(items, now).length,
    isLowStock:
        packs <= 0.25 &&
        !latest.isBefore(now.subtract(const Duration(days: 60))),
    isOutOfStock: packs == 0,
    latest: latest,
  );
}

Set<String> _receipts(List<InventoryItem> items, DateTime now) => items
    .where(
      (item) =>
          (item.receiptId?.trim().isNotEmpty ?? false) &&
          !(item.receiptDate ?? item.entryDate).isAfter(now) &&
          !(item.receiptDate ?? item.entryDate).isBefore(
            now.subtract(const Duration(days: 180)),
          ),
    )
    .map((item) => item.receiptId!)
    .toSet();

double _remainingPacks(InventoryItem item) {
  if (item.usesAmountProgress) {
    return (item.currentAmount /
            item.initialAmount *
            item.effectiveInitialQuantity)
        .clamp(0, double.infinity);
  }
  return item.quantity.clamp(0, double.infinity).toDouble();
}

int _compare(InventoryReplenishment a, InventoryReplenishment b) {
  if (a.isLowStock != b.isLowStock) return a.isLowStock ? -1 : 1;
  final frequency = b.purchaseCount.compareTo(a.purchaseCount);
  if (frequency != 0) return frequency;
  final recency = b.latest.compareTo(a.latest);
  return recency != 0 ? recency : a.name.compareTo(b.name);
}
