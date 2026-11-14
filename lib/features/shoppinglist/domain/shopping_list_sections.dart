import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';

/// An entry shown as a tile, with its shelf and picture.
typedef ShoppingListTile = ({
  ShoppingListItem item,
  ShoppingShelfPlacement placement,
});

/// The tiles under one shelf heading. The shelf is null when the tiles are
/// sorted by name under no heading.
typedef ShoppingListTileGroup = ({
  ShoppingShelf? shelf,
  List<ShoppingListTile> tiles,
});

/// Presentation-ready partitions of the persisted shopping records.
/// Immutable: the lists cannot be changed.
class ShoppingListSections {
  /// Computes the sections once. Entries in [justTicked] are in the cart
  /// already but still show among the tiles, so the grid does not move
  /// under the finger. [pendingDone] holds, by entry id, the done state of
  /// changes that are not saved yet; it wins over the stored state. The
  /// tiles stand [byShelf] in the order of the way through the shop, placed
  /// with the household's [choices], or else sorted by name.
  factory(
    List<ShoppingListItem> items, {
    Set<String> justTicked = const {},
    Map<String, bool> pendingDone = const {},
    bool byShelf = true,
    ShoppingShelfChoices choices = const {},
  }) {
    final tiles = <ShoppingListTile>[];
    final cart = <ShoppingListItem>[];
    final saved = <ShoppingListItem>[];
    var entryCount = 0;
    var doneCount = 0;
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
        tiles.add((
          item: item,
          placement: placeShoppingItem(item.name, choices),
        ));
      } else {
        cart.add(item);
      }
    }
    if (!byShelf) {
      tiles.sort(
        (a, b) => a.item.normalizedName.compareTo(b.item.normalizedName),
      );
    }
    return ShoppingListSections._(
      tileGroups: List.unmodifiable(<ShoppingListTileGroup>[
        if (byShelf)
          for (final group in groupByShoppingShelf(
            tiles,
            (tile) => tile.placement.shelf,
          ))
            (shelf: group.shelf, tiles: List.unmodifiable(group.items))
        else if (tiles.isNotEmpty)
          (shelf: null, tiles: List.unmodifiable(tiles)),
      ]),
      cart: List.unmodifiable(cart),
      saved: List.unmodifiable(saved),
      entryCount: entryCount,
      doneCount: doneCount,
    );
  }

  const new _({
    required this.tileGroups,
    required this.cart,
    required this.saved,
    required this.entryCount,
    required this.doneCount,
  });

  /// Entries shown as tiles, still to buy or ticked a moment ago, in their
  /// groups.
  final List<ShoppingListTileGroup> tileGroups;

  /// Entries shown in the cart.
  final List<ShoppingListItem> cart;

  /// Favorites and recurring items, independent of their list status.
  final List<ShoppingListItem> saved;

  /// Entries on the list, to buy or in the cart.
  final int entryCount;

  /// Entries in the cart, the ones ticked a moment ago included.
  final int doneCount;
}
