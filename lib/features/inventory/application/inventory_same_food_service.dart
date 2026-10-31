import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';

part 'inventory_same_food_service.g.dart';

/// A diary entry eaten again from a pack, and whether the pack had less
/// stock than the entry ate.
typedef InventoryEatAgainResult = ({CalorieEntry entry, bool missedStock});

/// The same food service.
@riverpod
InventorySameFoodService inventorySameFoodService(Ref ref) {
  return InventorySameFoodService(
    items: ref.watch(inventoryItemRepositoryProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
    eatService: ref.watch(inventoryEatServiceProvider),
    saver: ref.watch(calorieEntrySaverProvider),
  );
}

/// Finds the Vorrat packs of a food eaten in the diary, so that the diary
/// can take its stock there, and eats a repeated entry from one of them.
class InventorySameFoodService {
  /// Creates the service.
  const new({
    required this._items,
    required this._pendings,
    required this._eatService,
    required this._saver,
  });

  final InventoryItemRepository _items;
  final InventoryPendingConsumptionStore _pendings;
  final InventoryEatService _eatService;
  final CalorieEntrySaver _saver;

  /// The packs with stock left that hold the product with [barcode], opened
  /// packs first, then the oldest.
  Future<List<InventoryItem>> loadPacksWithBarcode(String? barcode) async {
    if (barcode == null || barcode.trim().isEmpty) {
      return const [];
    }
    return inventoryPacksWithBarcode(barcode, await _items.readAllForChange());
  }

  /// The packs with stock left that [entry]'s food can be eaten again from:
  /// its own pack or another pack of the same food, in eating order.
  Future<List<InventoryPack>> loadPacksToRepeat(CalorieEntry entry) async {
    if (entry.isQuickEntry || entry.isBundle) {
      return const [];
    }
    final packs = inventoryPacksForPlan(entry, await _items.readAllForChange());
    // The stock the entry took is less than it ate when its pack ran empty,
    // so its own pack takes the eaten amount again where it can tell it.
    final eaten = entry.copyWith(sourceInventoryAmountToRestore: null);
    return [
      for (final pack in packs)
        if (pack.item.id == entry.sourceInventoryItemId)
          (
            item: pack.item,
            amount: inventoryAmountForPlan(eaten, pack.item) ?? pack.amount,
          )
        else
          pack,
    ];
  }

  /// Saves [repeated], a new entry for a food eaten before, with the stock
  /// of [pack] in one write. The pack gives at most the stock it has left.
  /// Returns null when nothing was saved.
  Future<InventoryEatAgainResult?> eatAgain(
    CalorieEntry repeated,
    InventoryPack pack,
  ) async {
    final pending = _pendings.stage(pack.item, pack.amount);
    if (pending == null) {
      return null;
    }
    final entry = repeated.copyWith(
      sourceInventoryItemId: pack.item.id,
      sourceInventoryAmountToRestore: pending.amount,
    );
    try {
      final saved = await _saver(
        entry,
        persistEntry: (entry) => _eatService.commit(entry, [pending]),
      );
      if (!saved) {
        await _pendings.discard(pending.id);
        return null;
      }
    } on Object {
      await _pendings.discard(pending.id);
      rethrow;
    }
    return (entry: entry, missedStock: pending.amount < pack.amount);
  }
}
