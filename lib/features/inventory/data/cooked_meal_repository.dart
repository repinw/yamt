import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
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

part 'cooked_meal_repository.g.dart';

const _logName = 'CookedMealRepository';

/// The repository that puts a cooked meal into the Vorrat.
@riverpod
CookedMealRepository cookedMealRepository(Ref ref) {
  return CookedMealRepository(
    scope: ref.watch(householdDataScopeProvider),
    actor: ref.watch(inventoryActivityActorProvider),
  );
}

/// One stock change of a cooked meal: the item before and after cooking.
typedef CookedStockChange = ({InventoryItem before, InventoryItem after});

/// Writes a cooked meal together with the stock it takes, in one batch.
class CookedMealRepository {
  /// Creates the repository for the household [_scope], or `null` while
  /// signed out.
  const new({required this._scope, required this._actor});

  final HouseholdDataScope? _scope;
  final InventoryActivityActor? _actor;

  /// Takes the stock of [changes] and adds [meal] to the Vorrat in one
  /// batch: either both are written or neither. Firestore queues batches
  /// offline, so the write does not wait for the server. Throws a
  /// [StateError] while signed out or when an item is gone.
  Future<void> addCookedMeal({
    required PreparedMeal meal,
    required List<CookedStockChange> changes,
    required DateTime happenedAt,
  }) async {
    final scope = _scope;
    if (scope == null) {
      throw StateError('No household to cook in.');
    }
    final household = scope.firestore
        .collection('households')
        .doc(scope.householdId);
    final items = SealedCollection(
      household.collection('inventory_items'),
      cipher: scope.cipher,
      plaintextFields: inventoryItemPlaintextFields,
    );
    final meals = SealedCollection(
      household.collection('prepared_meals'),
      cipher: scope.cipher,
    );
    final events = SealedCollection(
      household.collection('inventory_activity_events'),
      cipher: scope.cipher,
      plaintextFields: inventoryActivityEventPlaintextFields,
    );
    final batch = scope.firestore.batch();
    for (final change in changes) {
      await _addStockChange(batch, items, change);
      if (_actor case final actor?) {
        final event = _event(actor, change, happenedAt);
        batch.set(
          events.reference.doc(event.id),
          await events.seal(event.id, event.toJson()),
        );
      }
    }
    batch.set(
      meals.reference.doc(meal.id),
      await meals.seal(meal.id, meal.toJson()),
    );
    commitBatchInBackground(
      batch,
      failureMessage: 'Server rejected cooked meal ${meal.id}.',
      logName: _logName,
    );
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
    batch.set(
      reference,
      await items.seal(reference.id, {
        ...stored,
        'quantity': change.after.quantity,
        'current_amount': change.after.currentAmount,
        'last_consumed_at': change.after.lastConsumedAt?.toIso8601String(),
      }),
    );
  }

  InventoryActivityEvent _event(
    InventoryActivityActor actor,
    CookedStockChange change,
    DateTime happenedAt,
  ) {
    final (:before, :after) = change;
    return InventoryActivityEvent.fromStockChange(
      id: const Uuid().v4(),
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
