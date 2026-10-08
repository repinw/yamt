import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_bridge_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/inventory_plan_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_serving_suggestion_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/domain/inventory_eat_outcome.dart';
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
    planner: ref.watch(inventoryPlanServiceProvider),
    servings: ref.watch(inventoryServingSuggestionServiceProvider),
    userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
    clock: ref.watch(clockProvider),
  );
}

/// Eats from the Vorrat into the diary: saves each diary entry together
/// with the stock it takes, in one write.
class InventoryEatService {
  /// Creates the service.
  const new({
    required this._saver,
    required this._commitStore,
    required this._pendings,
    required this._planner,
    required this._servings,
    required this._userId,
    required this._clock,
  });

  static const _uuid = Uuid();

  final CalorieEntrySaver _saver;
  final InventoryCalorieEntryCommitStore _commitStore;
  final InventoryPendingConsumptionStore _pendings;
  final InventoryPlanService _planner;
  final InventoryServingSuggestionService _servings;
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

  /// Logs [request] of [item] with its reserved [pending] stock, or plans
  /// it through [InventoryPlanService] when its day lies after today.
  ///
  /// Releases [pending] when the eat fails or throws, and after a plan. Keeps
  /// it reserved when the calorie editor has to finish the eat.
  Future<InventoryEatOutcome> log({
    required InventoryItem item,
    required InventoryItemEatRequest request,
    required PendingInventoryConsumption pending,
  }) => _releasingOnFailure(pending, () => _log(item, request, pending));

  /// Logs [entry] as the calorie editor returned it, after [log] handed the
  /// eat to the editor, with the [pending] stock reserved for it.
  ///
  /// Adds the Vorrat source of [inventoryContext] to [entry]. Fails when
  /// [pending] is no longer reserved. Releases [pending] when the save fails
  /// or throws.
  Future<InventoryEatOutcome> logEdited({
    required CalorieEntry entry,
    required PendingInventoryConsumption pending,
    required CalorieInventoryCreateContext inventoryContext,
    CalorieScannedSourceRef? scannedSourceRef,
  }) async {
    if (_pendings.pendingConsumptionById(pending.id) == null) {
      return const InventoryEatFailed(InventoryEatFailure.notSaved);
    }
    return await _releasingOnFailure(
      pending,
      () => _save(
        InventoryCalorieBridgeFlow.withCountedPortion(
          entry.copyWith(
            sourceInventoryItemId: inventoryContext.inventoryItemId,
            sourceInventoryAmountToRestore:
                inventoryContext.inventoryAmountToRestore,
          ),
          inventoryContext,
        ),
        pending: pending,
        inventoryContext: inventoryContext,
        scannedSourceRef: scannedSourceRef,
      ),
    );
  }

  Future<InventoryEatOutcome> _releasingOnFailure(
    PendingInventoryConsumption pending,
    Future<InventoryEatOutcome> Function() eat,
  ) async {
    try {
      final outcome = await eat();
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
    if (_planner.isPlan(request)) {
      return await _planner.plan(item: item, request: request);
    }
    final profile = InventoryCalorieBridgeFlow.buildProfileFromInventoryItem(
      item,
    );
    if (profile == null) {
      return const InventoryEatFailed(InventoryEatFailure.noNutrition);
    }
    final inventoryContext = InventoryCalorieBridgeFlow.buildInventoryContext(
      item: item,
      request: request,
      stagedAmount: pending.amount,
    );
    final scannedSourceRef = InventoryCalorieBridgeFlow.buildScannedSourceRef(
      item: item,
      profile: profile,
    );
    if (!canDirectlySaveInventoryItemEatRequest(item, request)) {
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
    final entry = InventoryCalorieBridgeFlow.buildCalorieEntry(
      id: _uuid.v4(),
      userId: userId,
      profile: profile,
      inventoryContext: inventoryContext,
      request: request,
      now: _clock(),
    );
    return await _save(
      entry,
      pending: pending,
      inventoryContext: inventoryContext,
      scannedSourceRef: scannedSourceRef,
    );
  }

  Future<InventoryEatOutcome> _save(
    CalorieEntry entry, {
    required PendingInventoryConsumption pending,
    required CalorieInventoryCreateContext inventoryContext,
    required CalorieScannedSourceRef? scannedSourceRef,
  }) async {
    final saved = await _saver(
      entry,
      scannedSourceRef: scannedSourceRef,
      persistEntry: (entry) => commit(entry, [pending]),
    );
    if (!saved) {
      return const InventoryEatFailed(InventoryEatFailure.notSaved);
    }
    _recordServing(entry, inventoryContext);
    return InventoryEatLogged(entry);
  }

  /// Remembers the eaten amount as the food's next suggested serving, in the
  /// background. A failure is logged and never fails the eat.
  void _recordServing(
    CalorieEntry entry,
    CalorieInventoryCreateContext inventoryContext,
  ) {
    if (entry.consumedAmount <= 0) {
      return;
    }
    final serving = _learnedServing(entry, inventoryContext);
    unawaited(
      _servings.recordSelection(
        foodFingerprint: inventoryContext.foodFingerprint,
        globalFoodItemId: inventoryContext.globalFoodItemId,
        amount: serving.amount,
        unit: serving.unit,
        label: serving.label,
        selectedAt: entry.updatedAt,
      ),
    );
  }
}

/// The serving to suggest next time: the portion the user picked, or the
/// amount of [entry] when the user changed it.
({double amount, ConsumedUnit unit, String? label}) _learnedServing(
  CalorieEntry entry,
  CalorieInventoryCreateContext inventoryContext,
) {
  final baseAmount = inventoryContext.portionAmountFor(
    entry.consumedAmount,
    entry.consumedUnit,
  );
  if (baseAmount == null) {
    return (
      amount: entry.consumedAmount,
      unit: entry.consumedUnit,
      label: null,
    );
  }
  return (
    amount: baseAmount,
    unit: entry.consumedUnit,
    label: inventoryContext.portionLabel,
  );
}
