import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

part 'cook_run_discard_service.g.dart';

/// The discard of the household's cook runs.
@riverpod
CookRunDiscardService cookRunDiscardService(Ref ref) => CookRunDiscardService(
  runs: ref.watch(cookRunRepositoryProvider),
  inventory: ref.watch(inventoryItemRepositoryProvider),
  meals: ref.watch(cookedMealRepositoryProvider),
  clock: ref.watch(clockProvider),
);

/// Discards a cook run and brings it back on undo.
class CookRunDiscardService {
  /// Creates the service.
  const new({
    required this._runs,
    required this._inventory,
    required this._meals,
    required this._clock,
  });

  final CookRunRepository _runs;
  final InventoryItemRepository _inventory;
  final CookedMealRepository _meals;
  final DateTime Function() _clock;

  /// Discards the run [runId] and returns it as it was, for [restore]. One
  /// batch deletes the run and the items that search, barcode or AI put
  /// into the Vorrat for it, that nobody changed since and that no other
  /// run takes from. Throws a [CookRunGoneException] when the run is gone;
  /// a failed write propagates and changes nothing.
  Future<CookRun> discard(String runId) async {
    await _runs.pending;
    final run = await _runs.load(runId);
    if (run == null) {
      throw CookRunGoneException(runId);
    }
    final items = await _inventory.readAllForChange();
    await _meals.addCookedMeals(
      meals: const [],
      changes: const [],
      deleteItemIds: untouchedAddedItemIds(
        run,
        items,
        used: const {},
        runs: await _runs.watchAll().first,
      ),
      happenedAt: _clock(),
      endedRun: run,
    );
    return run;
  }

  /// Brings back the discarded [run] ("Rückgängig"). An item it added and
  /// the discard deleted stays gone; its line then shows "Eintrag fehlt".
  /// Throws a [StateError] when a run with its id exists again, such as a
  /// new cooking of the same recipe, which the restore must not overwrite.
  Future<void> restore(CookRun run) async {
    await _runs.pending;
    if (await _runs.load(run.id) != null) {
      throw StateError('Cook run ${run.id} exists again.');
    }
    await _runs.create(run);
  }
}

/// The items of [items] that search, barcode or AI put into the Vorrat for
/// [run] ([CookRun.addedItemIds]), that neither [used] names nor another
/// run of [runs] takes from, and whose stock nobody touched since: they
/// would stay behind as stock that nobody bought.
List<String> untouchedAddedItemIds(
  CookRun run,
  List<InventoryItem> items, {
  required Set<String> used,
  required List<CookRun> runs,
}) {
  final added = run.addedItemIds.difference({
    ...used,
    ...reservationsOf(runs.where((other) => other.id != run.id)).keys,
  });
  return [
    for (final item in items)
      if (added.contains(item.id) &&
          item.quantity == item.initialQuantity &&
          item.currentAmount == item.initialAmount &&
          item.lastConsumedAt == null)
        item.id,
  ];
}
