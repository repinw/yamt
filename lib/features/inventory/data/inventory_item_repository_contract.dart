import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Persists user-specific inventory items.
abstract interface class InventoryItemRepository {
  /// Watch all.
  Stream<List<InventoryItem>> watchAll();

  /// Read all.
  Future<List<InventoryItem>> readAll();

  /// Writes [item] alone; the other items of the household stay untouched.
  Future<bool> save(InventoryItem item);

  /// Deletes the item [itemId] alone.
  Future<bool> delete(String itemId);

  /// Append all.
  Future<bool> appendAll(List<InventoryItem> items);
}

/// Writes a list change one item at a time.
extension InventoryItemListChanges on InventoryItemRepository {
  /// Saves the items of [next] that differ from [previous] and deletes the
  /// ones that [next] leaves out. Items in neither list stay untouched.
  Future<bool> saveChanges({
    required List<InventoryItem> previous,
    required List<InventoryItem> next,
  }) async {
    final before = {for (final item in previous) item.id: item};
    final nextIds = {for (final item in next) item.id};
    var saved = true;
    for (final item in next) {
      if (before[item.id] != item) {
        saved = await save(item) && saved;
      }
    }
    for (final id in before.keys) {
      if (!nextIds.contains(id)) {
        saved = await delete(id) && saved;
      }
    }
    return saved;
  }
}

/// Reads limited recent manual inventory items.
abstract interface class InventoryItemRecentManualReader {
  /// Whether recent manual reads are handled without loading all items.
  bool get supportsLimitedRecentManualReads;

  /// Reads recent manual items, newest first.
  Future<List<InventoryItem>> readRecentManualItems({required int limit});
}
