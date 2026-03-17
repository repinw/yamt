import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Persists user-specific inventory items.
abstract interface class InventoryItemRepository {
  Stream<List<InventoryItem>> watchAll();

  Future<List<InventoryItem>> readAll();

  Future<bool> saveAll(List<InventoryItem> items);

  Future<bool> appendAll(List<InventoryItem> items);
}
