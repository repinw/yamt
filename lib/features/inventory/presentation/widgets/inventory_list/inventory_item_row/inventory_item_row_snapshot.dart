import 'package:yamt/features/inventory/domain/inventory_item.dart';

class InventoryItemRowSnapshot {
  const InventoryItemRowSnapshot({
    required this.itemId,
    required this.name,
    required this.category,
    required this.barcode,
    required this.imageUrl,
    required this.initialQuantity,
    required this.quantity,
  });

  factory InventoryItemRowSnapshot.fromItem(InventoryItem item) {
    return InventoryItemRowSnapshot(
      itemId: item.id,
      name: item.name,
      category: item.category,
      barcode: item.normalizedBarcode,
      imageUrl: item.imageUrl,
      initialQuantity: item.initialQuantity,
      quantity: item.quantity,
    );
  }

  final String itemId;
  final String name;
  final String? category;
  final String? barcode;
  final String? imageUrl;
  final int initialQuantity;
  final int quantity;
}
