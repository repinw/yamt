import 'package:yamt/features/inventory/domain/inventory_item.dart';

class InventoryConsumptionFilter {
  const InventoryConsumptionFilter({this.hideFullyConsumedItems = false});

  final bool hideFullyConsumedItems;

  InventoryConsumptionFilter copyWith({bool? hideFullyConsumedItems}) {
    return InventoryConsumptionFilter(
      hideFullyConsumedItems:
          hideFullyConsumedItems ?? this.hideFullyConsumedItems,
    );
  }

  List<InventoryItem> apply(List<InventoryItem> source) {
    return source.where(matches).toList(growable: false);
  }

  bool matches(InventoryItem item) {
    if (item.isFullyConsumed) {
      return !hideFullyConsumedItems;
    }
    return true;
  }
}
