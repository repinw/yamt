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

/// The positions in [changes], newest first, to undo so that the change at
/// [index] is undone without losing a newer change: every newer change that
/// touched an entry it touched, or one of theirs, newest first, then [index].
///
/// Undoing only the change at [index] would put back the entries as they were
/// before it and drop what a newer change did to them.
List<int> shoppingListRevertChain(List<ShoppingListRevert> changes, int index) {
  final touched = {...changes[index].keys};
  final chain = [index];
  for (var newer = index - 1; newer >= 0; newer--) {
    if (changes[newer].keys.any(touched.contains)) {
      touched.addAll(changes[newer].keys);
      chain.insert(0, newer);
    }
  }
  return chain;
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
