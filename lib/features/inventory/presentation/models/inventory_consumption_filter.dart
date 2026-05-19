import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory consumption filter.
class InventoryConsumptionFilter {
  /// The inventory consumption filter.
  const InventoryConsumptionFilter({this.hideFullyConsumedItems = true});

  /// The hide fully consumed items.
  final bool hideFullyConsumedItems;

  /// Copy with.
  InventoryConsumptionFilter copyWith({bool? hideFullyConsumedItems}) {
    return InventoryConsumptionFilter(
      hideFullyConsumedItems:
          hideFullyConsumedItems ?? this.hideFullyConsumedItems,
    );
  }

  /// Apply.
  List<InventoryItem> apply(List<InventoryItem> source) {
    return source.where(matches).toList(growable: false);
  }

  /// Matches.
  bool matches(InventoryItem item) {
    if (item.isFullyConsumed) {
      return !hideFullyConsumedItems;
    }
    return true;
  }
}
