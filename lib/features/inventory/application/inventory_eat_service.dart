import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

part 'inventory_eat_service.g.dart';

/// The inventory eat service.
@riverpod
InventoryEatService inventoryEatService(Ref ref) {
  return InventoryEatService(
    saver: ref.watch(calorieEntrySaverProvider),
    commitStore: ref.watch(inventoryCalorieEntryCommitStoreProvider),
    pendings: ref.watch(inventoryPendingConsumptionStoreProvider),
    plans: ref.watch(plannedEntryRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
    userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
    clock: ref.watch(clockProvider),
  );
}

/// Why an eat from the Vorrat was not logged.
enum InventoryEatFailure {
  /// The item has no nutrition values to log.
  noNutrition,

  /// The diary entry and the stock change were not saved.
  notSaved,

  /// The amount needs the calorie editor, which saves eaten food, not plans.
  cannotPlan,
}

/// What happened to an eat from the Vorrat.
sealed class InventoryEatOutcome {
  const new();
}

/// The diary entry and the stock change were saved together.
final class InventoryEatLogged extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.entry);

  /// The saved diary entry.
  final CalorieEntry entry;
}

/// The day lies after today, so [entry] was saved as a plan. A plan takes
/// no stock; the reserved stock was released.
final class InventoryEatPlanned extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.entry);

  /// The saved plan.
  final CalorieEntry entry;
}

/// The amount cannot be logged without the calorie editor. The stock stays
/// reserved; the editor saves or discards it.
final class InventoryEatNeedsEditor extends InventoryEatOutcome {
  /// Creates the outcome.
  const new({
    required this.profile,
    required this.scannedSourceRef,
    required this.inventoryContext,
  });

  /// The item's nutrition as a calorie product.
  final CalorieProductProfile profile;

  /// The barcode source of the item, if it has one.
  final CalorieScannedSourceRef? scannedSourceRef;

  /// The amounts and the reserved stock for the editor.
  final CalorieInventoryCreateContext inventoryContext;
}

/// Nothing was saved and the reserved stock was released.
final class InventoryEatFailed extends InventoryEatOutcome {
  /// Creates the outcome.
  const new(this.failure);

  /// Why it failed.
  final InventoryEatFailure failure;
}

/// Eats from the Vorrat into the diary: saves each diary entry together
/// with the stock it takes, in one write.
class InventoryEatService {
  /// Creates the service.
  const new({
    required this._saver,
    required this._commitStore,
    required this._pendings,
    required this._plans,
    required this._overviewRevision,
    required this._userId,
    required this._clock,
  });

  static const _uuid = Uuid();

  final CalorieEntrySaver _saver;
  final InventoryCalorieEntryCommitStore _commitStore;
  final InventoryPendingConsumptionStore _pendings;
  final PlannedEntryRepository _plans;
  final CalorieOverviewRevision _overviewRevision;
  final String? _userId;
  final DateTime Function() _clock;

  /// Saves [entry] and the stock of [pendings] in one write, then finalizes
  /// them. Every diary entry that takes stock is persisted here. Returns
  /// false when nothing was saved; [pendings] then stay reserved.
  Future<bool> commit(
    CalorieEntry entry,
    List<PendingInventoryConsumption> pendings,
  ) async {
    final results = await _commitStore.commitEntryAndInventoryItems(
      entry: entry,
      pendingConsumptions: pendings,
    );
    if (results == null) {
      return false;
    }
    for (final (index, result) in results.indexed) {
      _pendings.finalize(
        id: pendings[index].id,
        itemId: result.itemId,
        quantity: result.quantity,
        currentAmount: result.currentAmount,
        consumedAt: entry.loggedAt,
      );
    }
    return true;
  }

  /// Commits [entry] with the stock reserved under [pendingConsumptionId],
  /// for the calorie editor. Returns false when nothing is reserved under
  /// that id any more.
  Future<bool> commitStaged({
    required CalorieEntry entry,
    required String pendingConsumptionId,
  }) async {
    final pending = _pendings.pendingConsumptionById(pendingConsumptionId);
    if (pending == null) {
      return false;
    }
    return await commit(entry, [pending]);
  }

  /// Logs [request] of [item] with its reserved [pending] stock, or plans
  /// it when its day lies after today.
  ///
  /// Releases [pending] when the eat fails or throws, and after a plan. Keeps
  /// it reserved when the calorie editor has to finish the eat.
  Future<InventoryEatOutcome> log({
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required PendingInventoryConsumption pending,
  }) async {
    try {
      final outcome = await _log(item, request, pending);
      if (outcome is InventoryEatFailed || outcome is InventoryEatPlanned) {
        await _pendings.discard(pending.id);
      }
      return outcome;
    } on Object {
      await _pendings.discard(pending.id);
      rethrow;
    }
  }

  Future<InventoryEatOutcome> _log(
    InventoryItem item,
    InventoryItemEatRequest request,
    PendingInventoryConsumption pending,
  ) async {
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    );
    if (profile == null) {
      return const InventoryEatFailed(InventoryEatFailure.noNutrition);
    }
    final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      pendingConsumptionId: pending.id,
      request: request,
      stagedAmount: pending.amount,
    );
    final scannedSourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );
    final isPlan = isDiaryFutureDay(day: request.loggedAt, today: _clock());
    if (!canDirectlySaveInventoryItemEatRequest(item, request)) {
      if (isPlan) {
        return const InventoryEatFailed(InventoryEatFailure.cannotPlan);
      }
      return InventoryEatNeedsEditor(
        profile: profile,
        scannedSourceRef: scannedSourceRef,
        inventoryContext: inventoryContext,
      );
    }

    final userId = _userId;
    if (userId == null) {
      return const InventoryEatFailed(InventoryEatFailure.notSaved);
    }
    final now = _clock();
    final entry = CalorieEntry.create(
      id: _uuid.v4(),
      userId: userId,
      name: profile.name,
      brand: profile.brand,
      imageUrl: profile.imageUrl,
      mealType: request.mealType,
      consumedAmount: inventoryContext.consumedAmount,
      consumedUnit: inventoryContext.consumedUnit,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
      sourceInventoryItemId: inventoryContext.inventoryItemId,
      // A plan takes no stock, so a delete has nothing to give back.
      sourceInventoryAmountToRestore: isPlan
          ? null
          : inventoryContext.inventoryAmountToRestore,
      nutrientDetails: profile.nutrientDetails,
      loggedAt: request.loggedAt,
      createdAt: now,
      updatedAt: now,
    );
    if (isPlan) {
      await _plans.savePlannedEntry(entry);
      _overviewRevision.markChanged();
      return InventoryEatPlanned(entry);
    }
    final saved = await _saver(
      entry,
      isNewEntry: true,
      inventoryContext: inventoryContext,
      scannedSourceRef: scannedSourceRef,
      persistEntry: (entry) => commit(entry, [pending]),
    );
    if (!saved) {
      return const InventoryEatFailed(InventoryEatFailure.notSaved);
    }
    return InventoryEatLogged(entry);
  }
}
