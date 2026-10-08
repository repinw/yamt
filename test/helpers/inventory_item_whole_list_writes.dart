import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Lets a test fake that keeps the whole Vorrat as one list take single item
/// writes: [save] and [delete] change the list from [storedItems] and hand it
/// to [replaceItems].
mixin InventoryItemWholeListWrites implements InventoryItemRepository {
  /// Stores [items] as the whole Vorrat.
  Future<bool> replaceItems(List<InventoryItem> items);

  /// The whole Vorrat as stored. A fake that counts its reads overrides this,
  /// so single writes do not count as reads.
  Future<List<InventoryItem>> storedItems() => readAll();

  @override
  Future<List<InventoryItem>> readAllLocal() => storedItems();

  @override
  Future<bool> save(InventoryItem item) async {
    final items = await storedItems();
    final index = items.indexWhere((stored) => stored.id == item.id);
    return await replaceItems([
      for (final stored in items)
        if (stored.id == item.id) item else stored,
      if (index < 0) item,
    ]);
  }

  @override
  Future<bool> delete(String itemId) async {
    final items = await storedItems();
    return await replaceItems([
      for (final stored in items)
        if (stored.id != itemId) stored,
    ]);
  }
}
