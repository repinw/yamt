import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Presentation-ready partitions of the persisted shopping records.
class ShoppingListSections {
  /// Computes the sections once. Entries in [justTicked] are in the cart
  /// already but still show among the tiles, so the grid does not move
  /// under the finger. [pendingDone] holds, by entry id, the done state of
  /// changes that are not saved yet; it wins over the stored state.
  new(
    List<ShoppingListItem> items, {
    Set<String> justTicked = const {},
    Map<String, bool> pendingDone = const {},
  }) {
    for (final stored in items) {
      final done = pendingDone[stored.id];
      final item = done == null || done == stored.isDone
          ? stored
          : stored.copyWith(isDone: done);
      if (item.isSaved) saved.add(item);
      if (item.isArchived) continue;
      entryCount++;
      if (item.isDone) doneCount++;
      if (item.isOpen || justTicked.contains(item.id)) {
        tiles.add(item);
      } else {
        cart.add(item);
      }
    }
  }

  /// Entries shown as tiles: still to buy, or ticked a moment ago.
  final tiles = <ShoppingListItem>[];

  /// Entries shown in the cart.
  final cart = <ShoppingListItem>[];

  /// Favorites and recurring items, independent of their list status.
  final saved = <ShoppingListItem>[];

  /// Entries on the list, to buy or in the cart.
  int entryCount = 0;

  /// Entries in the cart, the ones ticked a moment ago included.
  int doneCount = 0;
}
