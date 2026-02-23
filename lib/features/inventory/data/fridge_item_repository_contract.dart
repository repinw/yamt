import 'package:yamt/features/inventory/domain/fridge_item.dart';

/// Persists fridge items used by the inventory feature.
abstract interface class FridgeItemRepository {
  /// Watches all stored items in realtime.
  Stream<List<FridgeItem>> watchAll();

  /// Loads all stored items. Returns an empty list if no data exists.
  Future<List<FridgeItem>> readAll();

  /// Replaces all stored items.
  Future<bool> saveAll(List<FridgeItem> items);

  /// Appends items to the existing list.
  Future<bool> appendAll(List<FridgeItem> items);
}
