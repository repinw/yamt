import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

part 'cooked_meal_repository.g.dart';

const _logName = 'CookedMealRepository';

/// The repository that puts a cooked meal into the Vorrat.
@riverpod
CookedMealRepository cookedMealRepository(Ref ref) {
  return CookedMealRepository(
    scope: ref.watch(householdDataScopeProvider),
    actor: ref.watch(inventoryActivityActorProvider),
    cookRuns: ref.watch(cookRunRepositoryProvider),
  );
}

/// One stock change of a cooked meal: the item before and after cooking.
typedef CookedStockChange = ({InventoryItem before, InventoryItem after});

typedef _Collections = ({
  SealedCollection items,
  SealedCollection meals,
  SealedCollection events,
});

/// Writes cooked meals together with the stock they take, in one batch.
class CookedMealRepository {
  /// Creates the repository for the household [_scope], or `null` while
  /// signed out. [_cookRuns] deletes the cook run that a finish ends.
  const new({
    required this._scope,
    required this._actor,
    required this._cookRuns,
  });

  final HouseholdDataScope? _scope;
  final InventoryActivityActor? _actor;
  final CookRunRepository _cookRuns;

  /// Ends the cook run [endedRun] in one batch: takes the stock of
  /// [changes] (one per item), writes an event per change with the id
  /// `<cookingId>-<itemId>` ([CookRun.cookingId]), adds [meals] under their
  /// own ids, deletes the items [deleteItemIds], and deletes the run. Either
  /// all of it is written or nothing. Events are never overwritten, so the
  /// ids are new for every cooking, yet the same when a finish is retried.
  /// Firestore queues the batch offline.
  ///
  /// Throws a [StateError] while signed out, when an item is gone or its
  /// stock changed since the cook read it, or when the batch would exceed
  /// Firestore's write limit; then nothing is written. Throws an
  /// [ArgumentError] when [changes] name an item twice.
  Future<void> addCookedMeals({
    required List<PreparedMeal> meals,
    required List<CookedStockChange> changes,
    required List<String> deleteItemIds,
    required DateTime happenedAt,
    required CookRun endedRun,
  }) async {
    final scope = _requireScope();
    final itemIds = {for (final change in changes) change.after.id};
    if (itemIds.length != changes.length) {
      throw ArgumentError.value(changes, 'changes', 'names an item twice');
    }
    final writes =
        changes.length * (_actor == null ? 1 : 2) +
        meals.length +
        deleteItemIds.length +
        1;
    if (writes > defaultMaxFirestoreBatchOperations) {
      throw StateError('Cook run ${endedRun.id} needs $writes writes.');
    }
    final collections = _collectionsOf(scope);
    final batch = scope.firestore.batch();
    await _stageStockChanges(
      batch,
      collections,
      changes,
      happenedAt,
      cookingId: endedRun.cookingId,
    );
    for (final meal in meals) {
      batch.set(
        collections.meals.reference.doc(meal.id),
        await collections.meals.seal(meal.id, meal.toJson()),
      );
    }
    for (final itemId in deleteItemIds) {
      batch.delete(collections.items.reference.doc(itemId));
    }
    await _cookRuns.stageDelete(batch, endedRun.id);
    commitBatchInBackground(
      batch,
      failureMessage: 'Server rejected the end of cook run ${endedRun.id}.',
      logName: _logName,
    );
  }

  HouseholdDataScope _requireScope() {
    final scope = _scope;
    if (scope == null) {
      throw StateError('No household to cook in.');
    }
    return scope;
  }

  _Collections _collectionsOf(HouseholdDataScope scope) {
    final household = scope.firestore
        .collection('households')
        .doc(scope.householdId);
    return (
      items: SealedCollection(
        household.collection('inventory_items'),
        cipher: scope.cipher,
        plaintextFields: inventoryItemPlaintextFields,
      ),
      meals: SealedCollection(
        household.collection('prepared_meals'),
        cipher: scope.cipher,
      ),
      events: SealedCollection(
        household.collection('inventory_activity_events'),
        cipher: scope.cipher,
        plaintextFields: inventoryActivityEventPlaintextFields,
      ),
    );
  }

  Future<void> _stageStockChanges(
    WriteBatch batch,
    _Collections collections,
    List<CookedStockChange> changes,
    DateTime happenedAt, {
    required String cookingId,
  }) async {
    for (final change in changes) {
      await _addStockChange(batch, collections.items, change);
      if (_actor case final actor?) {
        final event = _event(
          '$cookingId-${change.after.id}',
          actor,
          change,
          happenedAt,
        );
        batch.set(
          collections.events.reference.doc(event.id),
          await collections.events.seal(event.id, event.toJson()),
        );
      }
    }
  }

  // The item is encrypted as a whole, so the batch writes the stored
  // document with the new stock instead of single fields.
  Future<void> _addStockChange(
    WriteBatch batch,
    SealedCollection items,
    CookedStockChange change,
  ) async {
    final reference = items.reference.doc(change.after.id);
    final stored = await items.open(await readDocumentLocalFirst(reference));
    if (stored == null) {
      throw StateError('Item ${change.after.id} is gone.');
    }
    // A stock change since the cook's read would be overwritten.
    final now = InventoryItem.fromJson(withDocumentId(reference.id, stored));
    if (now.quantity != change.before.quantity ||
        now.availableAmount != change.before.availableAmount) {
      throw StateError('Item ${change.after.id} changed meanwhile.');
    }
    // The scale goes with the scaled amounts: an old piece item stored
    // without one would read 1000 times too high (InventoryItem.fromJson).
    batch.set(
      reference,
      await items.seal(reference.id, {
        ...stored,
        'quantity': change.after.quantity,
        'initial_amount': now.initialAmount,
        'current_amount': change.after.currentAmount,
        'amount_scale': now.amountScale,
        'last_consumed_at': change.after.lastConsumedAt?.toIso8601String(),
      }),
    );
  }

  InventoryActivityEvent _event(
    String id,
    InventoryActivityActor actor,
    CookedStockChange change,
    DateTime happenedAt,
  ) {
    final (:before, :after) = change;
    return InventoryActivityEvent.fromStockChange(
      id: id,
      type: InventoryActivityEventType.itemUsedInPreparedMeal,
      actor: actor,
      item: before,
      amount: before.availableAmount - after.availableAmount,
      beforeQuantity: before.quantity,
      afterQuantity: after.quantity,
      beforeCurrentAmount: before.currentAmount,
      afterCurrentAmount: after.currentAmount,
      happenedAt: happenedAt,
    );
  }
}
