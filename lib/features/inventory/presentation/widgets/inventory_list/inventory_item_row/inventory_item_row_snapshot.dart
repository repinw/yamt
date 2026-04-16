import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory item row snapshot.
class InventoryItemRowSnapshot {
  /// The inventory item row snapshot.
  const InventoryItemRowSnapshot({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.initialQuantity,
    required this.quantity,
  });

  /// Creates a [InventoryItemRowSnapshot] for from item.
  factory InventoryItemRowSnapshot.fromItem(InventoryItem item) {
    return InventoryItemRowSnapshot(
      itemId: item.id,
      name: item.name,
      imageUrl: item.imageUrl,
      initialQuantity: item.initialQuantity,
      quantity: item.quantity,
    );
  }

  /// The item id.
  final String itemId;

  /// The name.
  final String name;

  /// The image url.
  final String? imageUrl;

  /// The initial quantity.
  final int initialQuantity;

  /// The quantity.
  final int quantity;
}
