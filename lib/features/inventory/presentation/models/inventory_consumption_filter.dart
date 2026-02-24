import 'package:yamt/features/inventory/domain/fridge_item.dart';

class InventoryConsumptionFilter {
  const InventoryConsumptionFilter({
    this.showConsumed = true,
    this.showNotConsumed = true,
  });

  final bool showConsumed;
  final bool showNotConsumed;

  InventoryConsumptionFilter toggleConsumed(bool value) {
    if (!value && !showNotConsumed) {
      return this;
    }
    return InventoryConsumptionFilter(
      showConsumed: value,
      showNotConsumed: showNotConsumed,
    );
  }

  InventoryConsumptionFilter toggleNotConsumed(bool value) {
    if (!value && !showConsumed) {
      return this;
    }
    return InventoryConsumptionFilter(
      showConsumed: showConsumed,
      showNotConsumed: value,
    );
  }

  List<FridgeItem> apply(List<FridgeItem> source) {
    return source.where(matches).toList(growable: false);
  }

  bool matches(FridgeItem item) {
    if (item.isConsumed) {
      return showConsumed;
    }
    return showNotConsumed;
  }
}
