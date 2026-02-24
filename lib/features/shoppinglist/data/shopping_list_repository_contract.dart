import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Persists shopping list items used by the shopping list feature.
abstract interface class ShoppingListRepository {
  /// Watches all stored shopping list items in realtime.
  Stream<List<ShoppingListItem>> watchAll();

  /// Loads all stored shopping list items.
  Future<List<ShoppingListItem>> readAll();

  /// Replaces all stored shopping list items.
  Future<bool> saveAll(List<ShoppingListItem> items);
}
