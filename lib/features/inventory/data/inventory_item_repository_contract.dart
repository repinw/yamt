import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Persists user-specific inventory items.
abstract interface class InventoryItemRepository {
  /// Watch all.
  Stream<List<InventoryItem>> watchAll();

  /// Read all.
  Future<List<InventoryItem>> readAll();

  /// Save all.
  Future<bool> saveAll(List<InventoryItem> items);

  /// Append all.
  Future<bool> appendAll(List<InventoryItem> items);
}

/// Reads limited recent manual inventory items.
abstract interface class InventoryItemRecentManualReader {
  /// Whether recent manual reads are handled without loading all items.
  bool get supportsLimitedRecentManualReads;

  /// Reads recent manual items, newest first.
  Future<List<InventoryItem>> readRecentManualItems({required int limit});
}
