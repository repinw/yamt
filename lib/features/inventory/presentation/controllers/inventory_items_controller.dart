import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/application/'
    'household_scoped_list_feed.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_discard_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_edit_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_mutation_service.dart';
import 'package:yamt/features/inventory/application/inventory_item_writer.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_stock_changes.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'inventory_items_controller.g.dart';

const _controllerLogName = 'InventoryItemsController';

/// Defines inventory items controller.
@riverpod
class InventoryItemsController extends _$InventoryItemsController {
  StreamSubscription<InventoryPendingConsumptionFinalized>?
  _pendingFinalizationSubscription;
  final _mutationQueue = SerializedMutationQueue();
  ({DeletedInventoryItem deleted, int generation})? _pendingDeletedItem;
  late final _feed = HouseholdScopedListFeed<InventoryItem>(
    ref: () => ref,
    watch: () => ref.read(inventoryItemRepositoryProvider).watchAll(),
    setState: (next) => state = next,
    logName: _controllerLogName,
    recoveryMessage:
        'Rebuilding inventory stream after household access changed.',
  );

  @override
  FutureOr<List<InventoryItem>> build() async {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(inventoryItemRepositoryProvider)
      ..onDispose(() {
        unawaited(_feed.close());
        unawaited(
          _pendingFinalizationSubscription?.cancel() ?? Future<void>.value(),
        );
      });
    _pendingFinalizationSubscription ??= ref
        .watch(inventoryPendingConsumptionStoreProvider)
        .finalizations
        .listen((event) {
          final items = _feed.items;
          final next = items == null ? null : event.applyTo(items);
          if (next != null) {
            _feed.publish(next);
          }
        });
    await waitForHouseholdDataOwnerProfile(ref);
    if (!ref.mounted) {
      return const <InventoryItem>[];
    }
    ref.watch(activeHouseholdIdProvider);
    return await _feed.start();
  }

  /// Refresh.
  Future<void> refresh() => _feed.refresh();

  InventoryItemMutationService get _mutations =>
      ref.read(inventoryItemMutationServiceProvider);

  InventoryItemDiscardService get _discards =>
      ref.read(inventoryItemDiscardServiceProvider);

  InventoryItemEditService get _edits =>
      ref.read(inventoryItemEditServiceProvider);

  /// Runs [change] on the queue with the cached list (#309) and lays the
  /// written list over the shown one unless the household or refresh moved on.
  Future<T> _mutate<T>(
    T fallback,
    Future<InventoryItemChange<T>> Function(List<InventoryItem> items) change,
  ) {
    return _mutationQueue.run<T>(
      onError: (error, stackTrace) => log(
        'Unexpected inventory mutation error.',
        name: _controllerLogName,
        error: error,
        stackTrace: stackTrace,
      ),
      operation: () async {
        final generation = _feed.generation;
        final repository = ref.read(inventoryItemRepositoryProvider);
        final items = await repository.readAllForChange();
        if (!ref.mounted) {
          return fallback;
        }
        final (:result, :written) = await change(items);
        final current = _feed.items;
        if (written != null &&
            current != null &&
            generation == _feed.generation) {
          _feed.publish(
            applyInventoryItemChanges(
              current: current,
              previous: items,
              next: written,
            ),
          );
        }
        return result;
      },
      fallbackValue: fallback,
    );
  }

  /// Delete item.
  Future<bool> deleteItem(String itemId) async {
    final deleted = await _mutate(
      null,
      (items) => _mutations.delete(items, itemId),
    );
    if (deleted != null) {
      _pendingDeletedItem = (deleted: deleted, generation: _feed.generation);
    }
    return deleted != null;
  }

  /// Undo last deleted item.
  Future<bool> undoLastDeletedItem() async {
    final pending = _pendingDeletedItem;
    // A household switch or refresh since the delete starts a new list.
    if (pending == null || pending.generation != _feed.generation) {
      return false;
    }
    final restored = await _mutate(
      false,
      (items) => _mutations.restoreDeleted(items, pending.deleted),
    );
    if (restored && identical(_pendingDeletedItem, pending)) {
      _pendingDeletedItem = null;
    }
    return restored;
  }

  /// Eat item and return the actual reduced amount.
  Future<InventoryItemReductionResult?> eatItemDetailed(
    String itemId,
    int amount, {
    DateTime? consumedAt,
  }) {
    if (amount < 1) {
      return Future<InventoryItemReductionResult?>.value();
    }
    return _mutate(
      null,
      (items) => _mutations.eat(items, itemId, amount, consumedAt: consumedAt),
    );
  }

  /// Throw away item and return the actual discarded amount.
  Future<InventoryItemDiscardResult?> throwAwayItemDetailed(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  ) {
    if (amount < 1) {
      return Future<InventoryItemDiscardResult?>.value();
    }
    return _mutate(
      null,
      (items) => _discards.throwAway(items, itemId, amount, reason),
    );
  }

  /// Restore consumed item.
  Future<bool> restoreConsumedItem(String itemId, int amount) {
    return restoreConsumedItems({itemId: amount});
  }

  /// Returns several amounts to their items in one write. Nothing changes
  /// when an item is missing or an amount is below 1.
  Future<bool> restoreConsumedItems(Map<String, int> amountsByItemId) {
    if (amountsByItemId.isEmpty || amountsByItemId.values.any((a) => a < 1)) {
      return Future<bool>.value(false);
    }
    return _mutate(
      false,
      (items) => _mutations.restore(items, amountsByItemId),
    );
  }

  /// Restore stock for a thrown-away item and delete its discard event.
  Future<bool> undoThrowAwayItem({
    required String itemId,
    required int amount,
    required String discardEventId,
  }) {
    if (amount < 1 || discardEventId.trim().isEmpty) {
      return Future<bool>.value(false);
    }
    return _mutate(
      false,
      (items) => _discards.undoThrowAway(
        items,
        itemId: itemId,
        amount: amount,
        discardEventId: discardEventId,
      ),
    );
  }

  /// Buy again item.
  Future<ShoppingListRevert?> buyAgainItem(InventoryItem item) {
    return addSourceItemToShoppingList(
      item: (
        name: item.name,
        brand: item.brand,
        initialQuantity: item.initialQuantity,
        unitPrice: item.unitPrice,
      ),
      addItem: ref
          .read(shoppingListControllerProvider.notifier)
          .addItemWithRevert,
    );
  }

  /// Undoes [buyAgainItem].
  Future<bool> undoBuyAgainItem(ShoppingListRevert revert) {
    return ref.read(shoppingListControllerProvider.notifier).revert(revert);
  }

  /// Update item.
  Future<bool> updateItem(InventoryItem item) {
    return _mutate(false, (items) => _edits.update(items, item));
  }

  /// Replaces the product reference on an existing full inventory item.
  Future<bool> swapItemCandidate({
    required String itemId,
    required GlobalFoodItem resolvedProduct,
    required bool requiresGlobalPersistence,
    String? weight,
  }) {
    return _mutate(
      false,
      (items) => _edits.swap(
        items,
        itemId: itemId,
        resolvedProduct: resolvedProduct,
        requiresGlobalPersistence: requiresGlobalPersistence,
        weight: weight,
      ),
    );
  }

  /// Adds a newly created item and shows it once it is written, so follow-up
  /// flows can reference it before the item stream catches up.
  Future<bool> addItem(InventoryItem item) {
    return _mutate(false, (items) => _mutations.add(items, item));
  }

  /// Reserves [amount] of the item [itemId] as the list shows it now, so
  /// the reservation is capped at the newest stock. Returns null when the
  /// item is missing or empty.
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) {
    if (amount < 1) {
      return Future<PendingInventoryConsumption?>.value();
    }
    return _mutate(null, (items) async {
      final pendings = ref.read(inventoryPendingConsumptionStoreProvider);
      final visible = state.asData?.value ?? items;
      final item = findInventoryItem(visible, itemId);
      final draft = item == null ? null : pendings.stage(item, amount);
      if (_feed.items case final current?) {
        _feed.publish(current);
      }
      return (result: draft, written: null);
    });
  }
}
