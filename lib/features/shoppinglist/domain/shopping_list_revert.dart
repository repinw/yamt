import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// The entries that one change touched, by id, as they were before it.
///
/// A null value marks an entry that the change created.
typedef ShoppingListRevert = Map<String, ShoppingListItem?>;

/// Records which entries differ between [previous] and [next].
///
/// A change keeps untouched entries as the same instances, so identity tells
/// which entries it replaced.
ShoppingListRevert shoppingListRevertOf(
  List<ShoppingListItem> previous,
  List<ShoppingListItem> next,
) {
  final previousById = {for (final item in previous) item.id: item};
  final nextIds = {for (final item in next) item.id};
  return {
    for (final item in next)
      if (!identical(previousById[item.id], item))
        item.id: previousById[item.id],
    for (final item in previous)
      if (!nextIds.contains(item.id)) item.id: item,
  };
}

/// Puts the entries recorded in [revert] back into [items].
List<ShoppingListItem> applyShoppingListRevert(
  List<ShoppingListItem> items,
  ShoppingListRevert revert,
) {
  final currentIds = {for (final item in items) item.id};
  return [
    for (final item in items)
      if (!revert.containsKey(item.id)) item else ?revert[item.id],
    for (final MapEntry(key: id, value: previous) in revert.entries)
      if (!currentIds.contains(id)) ?previous,
  ];
}
