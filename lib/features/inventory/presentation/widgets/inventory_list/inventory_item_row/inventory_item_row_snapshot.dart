import 'package:yamt/features/inventory/domain/fridge_item.dart';

class InventoryItemRowSnapshot {
  const InventoryItemRowSnapshot({
    required this.itemId,
    required this.name,
    required this.category,
    required this.initialQuantity,
    required this.quantity,
  });

  factory InventoryItemRowSnapshot.fromFridgeItem(FridgeItem item) {
    return InventoryItemRowSnapshot(
      itemId: item.id,
      name: item.name,
      category: item.category,
      initialQuantity: item.initialQuantity,
      quantity: item.quantity,
    );
  }

  final String itemId;
  final String name;
  final String? category;
  final int initialQuantity;
  final int quantity;
}
