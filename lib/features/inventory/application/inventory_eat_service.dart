import 'dart:async';

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
    plans: ref.watch(plannedEntryRepositoryProvider),
    overviewRevision: ref.watch(calorieOverviewRevisionProvider.notifier),
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
    required this._plans,
    required this._overviewRevision,
    required this._servings,
    required this._userId,
    required this._clock,
  });

  static const _uuid = Uuid();

  final CalorieEntrySaver _saver;
  final InventoryCalorieEntryCommitStore _commitStore;
  final InventoryPendingConsumptionStore _pendings;
  final PlannedEntryRepository _plans;
  final CalorieOverviewRevision _overviewRevision;
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
  /// it when its day lies after today.
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
        entry.copyWith(
          sourceInventoryItemId: inventoryContext.inventoryItemId,
          sourceInventoryAmountToRestore:
              inventoryContext.inventoryAmountToRestore,
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
      isNewEntry: true,
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
  final baseAmount = inventoryContext.portionBaseAmount;
  final baseUnit = inventoryContext.portionBaseUnit;
  final count = inventoryContext.portionCount;
  if (baseAmount == null ||
      baseUnit == null ||
      count == null ||
      entry.consumedUnit != baseUnit ||
      (entry.consumedAmount - baseAmount * count).abs() > 0.001) {
    return (
      amount: entry.consumedAmount,
      unit: entry.consumedUnit,
      label: null,
    );
  }
  return (
    amount: baseAmount,
    unit: baseUnit,
    label: inventoryContext.portionLabel,
  );
}
