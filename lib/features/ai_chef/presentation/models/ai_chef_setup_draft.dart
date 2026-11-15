import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// What the user set up for one AI recipe suggestion. Nothing here is
/// stored; the "Bloß nicht" list lives in its own repository.
@immutable
class AiChefSetupDraft {
  /// Creates a draft.
  const new({
    this.includeInventory = true,
    this.mustUseItems = const <InventoryItem>[],
    this.wishes = const <String>[],
  });

  /// Whether the Vorrat goes with the request.
  final bool includeInventory;

  /// Vorrat items that must go into the recipe ("Unbedingt rein"). They go
  /// with the request only while [includeInventory] is on, looked up again
  /// in the Vorrat when the request goes out.
  final List<InventoryItem> mustUseItems;

  /// Wishes such as an ingredient or "schnell".
  final List<String> wishes;

  /// The draft with the Vorrat switched to [value].
  AiChefSetupDraft withInventory({required bool value}) => AiChefSetupDraft(
    includeInventory: value,
    mustUseItems: mustUseItems,
    wishes: wishes,
  );

  /// The draft with [items] as the "Unbedingt rein" picks.
  AiChefSetupDraft withMustUse(List<InventoryItem> items) => AiChefSetupDraft(
    includeInventory: includeInventory,
    mustUseItems: List<InventoryItem>.unmodifiable(items),
    wishes: wishes,
  );

  /// The draft without the pick with [id].
  AiChefSetupDraft withoutMustUse(String id) => withMustUse([
    for (final item in mustUseItems)
      if (item.id != id) item,
  ]);

  /// The draft with [wish] added. Blank and repeated wishes (regardless of
  /// case) change nothing.
  AiChefSetupDraft withWish(String wish) {
    final trimmed = wish.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || wishes.any((w) => w.toLowerCase() == key)) {
      return this;
    }
    return _withWishes([...wishes, trimmed]);
  }

  /// The draft without [wish].
  AiChefSetupDraft withoutWish(String wish) => _withWishes([
    for (final entry in wishes)
      if (entry != wish) entry,
  ]);

  AiChefSetupDraft _withWishes(List<String> next) => AiChefSetupDraft(
    includeInventory: includeInventory,
    mustUseItems: mustUseItems,
    wishes: List<String>.unmodifiable(next),
  );
}
