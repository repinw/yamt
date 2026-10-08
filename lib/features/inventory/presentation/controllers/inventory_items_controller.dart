import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/application/'
    'household_permission_recovery.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
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
  // Subscription is cancelled by _disposeRealtimeSubscription.
  // ignore: cancel_subscriptions
  StreamSubscription<List<InventoryItem>>? _itemsSubscription;
  StreamSubscription<InventoryPendingConsumptionFinalized>?
  _pendingFinalizationSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  DeletedInventoryItem? _pendingDeletedItem;
  List<InventoryItem>? _persistedItems;
  String? _currentDataOwnerUserId;

  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<InventoryItem>> build() async {
    ref
      ..watch(householdDataOwnerUserIdProvider)
      ..watch(inventoryItemRepositoryProvider)
      ..onDispose(() {
        unawaited(_disposeRealtimeSubscription());
        unawaited(
          _pendingFinalizationSubscription?.cancel() ?? Future<void>.value(),
        );
      });
    _pendingFinalizationSubscription ??= ref
        .watch(inventoryPendingConsumptionStoreProvider)
        .finalizations
        .listen(_onPendingConsumptionFinalized);
    await waitForHouseholdDataOwnerProfile(ref);
    if (!ref.mounted) {
      return const <InventoryItem>[];
    }
    _currentDataOwnerUserId = ref.watch(activeHouseholdIdProvider);
    return await _restartRealtimeSubscription();
  }

  /// Refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(_restartRealtimeSubscription);
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<List<InventoryItem>> _restartRealtimeSubscription() async {
    final initialItems = Completer<List<InventoryItem>>();
    _currentDataOwnerUserId = ref.read(activeHouseholdIdProvider);
    final repository = ref.read(inventoryItemRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeRealtimeSubscription();
    _persistedItems = null;
    _pendingDeletedItem = null;

    _itemsSubscription = repository.watchAll().listen(
      (items) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        _persistedItems = items;
        if (!initialItems.isCompleted) {
          initialItems.complete(items);
          return;
        }
        _onRealtimeItems(items);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation != _subscriptionGeneration) {
          return;
        }
        if (!initialItems.isCompleted) {
          if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
            initialItems.complete(const <InventoryItem>[]);
            unawaited(_recoverFromRevokedHouseholdAccess(showLoading: false));
            return;
          }
          initialItems.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );
    return await initialItems.future;
  }

  Future<void> _disposeRealtimeSubscription() async {
    final currentSubscription = _itemsSubscription;
    _itemsSubscription = null;
    if (currentSubscription != null) {
      await currentSubscription.cancel();
    }
  }

  void _onRealtimeItems(List<InventoryItem> items) {
    if (!ref.mounted) {
      return;
    }
    _persistedItems = items;
    state = AsyncData(items);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (_shouldRecoverFromRevokedHouseholdAccess(error)) {
      unawaited(_recoverFromRevokedHouseholdAccess());
      return;
    }
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  void _onPendingConsumptionFinalized(
    InventoryPendingConsumptionFinalized event,
  ) {
    if (!ref.mounted) {
      return;
    }
    final currentItems = _persistedItems;
    if (currentItems == null) {
      return;
    }
    final itemIndex = currentItems.indexWhere(
      (item) => item.id == event.itemId,
    );
    if (itemIndex < 0) {
      return;
    }

    final currentItem = currentItems[itemIndex];
    final nextLastConsumedAt = event.consumedAt == null
        ? currentItem.lastConsumedAt
        : currentItem.latestConsumedAtOr(event.consumedAt!);
    if (currentItem.quantity == event.quantity &&
        currentItem.currentAmount == event.currentAmount &&
        currentItem.lastConsumedAt == nextLastConsumedAt) {
      return;
    }

    final nextItems = List<InventoryItem>.from(currentItems);
    nextItems[itemIndex] = currentItem.copyWith(
      quantity: event.quantity,
      currentAmount: event.currentAmount,
      lastConsumedAt: nextLastConsumedAt,
    );
    _persistedItems = nextItems;
    _publishVisibleItems();
  }

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    final actualDataOwnerUserId = ref.read(householdDataOwnerUserIdProvider);
    final effectiveDataOwnerUserId = ref.read(activeHouseholdIdProvider);
    final shouldRecover = shouldRecoverControllerHouseholdAccess(
      ref: ref,
      error: error,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
    );
    if (error is FirebaseException && error.code == 'permission-denied') {
      _logPermissionDeniedContext(
        shouldRecover: shouldRecover,
        actualDataOwnerUserId: actualDataOwnerUserId,
        effectiveDataOwnerUserId: effectiveDataOwnerUserId,
      );
    }
    return shouldRecover;
  }

  Future<void> _recoverFromRevokedHouseholdAccess({bool showLoading = true}) {
    return recoverControllerHouseholdAccess<InventoryItem>(
      ref: ref,
      isRecoveringHouseholdAccess: _isRecoveringHouseholdAccess,
      setIsRecoveringHouseholdAccess: ({required value}) {
        _isRecoveringHouseholdAccess = value;
      },
      setState: (nextState) {
        state = nextState;
      },
      restartHouseholdScopedSubscription: _restartRealtimeSubscription,
      currentHouseholdDataOwnerUserId: _currentDataOwnerUserId,
      householdAccessRecoveryLogName: _controllerLogName,
      householdAccessRecoveryMessage:
          'Rebuilding inventory stream after household access changed.',
      showLoading: showLoading,
      onSkippedHouseholdAccessRecovery: onSkippedHouseholdAccessRecovery,
    );
  }

  void _logPermissionDeniedContext({
    required bool shouldRecover,
    required String? actualDataOwnerUserId,
    required String? effectiveDataOwnerUserId,
  }) {
    final scopeDetails = _buildScopeDebugDetails(
      actualDataOwnerUserId: actualDataOwnerUserId,
      effectiveDataOwnerUserId: effectiveDataOwnerUserId,
    );
    log(
      'Permission denied while watching inventory. '
      'shouldRecover=$shouldRecover '
      '$scopeDetails',
      name: _controllerLogName,
    );
  }

  /// On skipped household access recovery.
  void onSkippedHouseholdAccessRecovery() {
    final scopeDetails = _buildScopeDebugDetails(
      actualDataOwnerUserId: ref.read(householdDataOwnerUserIdProvider),
      effectiveDataOwnerUserId: ref.read(activeHouseholdIdProvider),
    );
    log(
      'Inventory access recovery had no owner swap candidate. '
      '$scopeDetails',
      name: _controllerLogName,
    );
  }

  String _buildScopeDebugDetails({
    required String? actualDataOwnerUserId,
    required String? effectiveDataOwnerUserId,
  }) {
    final profile = ref.read(userProfileProvider).asData?.value;
    final recoveryState = ref.read(householdDataOwnerRecoveryProvider);
    final currentUserId = signedInHouseholdRecoveryUserId(ref) ?? profile?.uid;
    return 'authUserId='
        '${normalizeHouseholdScopeValue(currentUserId) ?? '<none>'} '
        'profileHouseholdId='
        '${normalizeHouseholdScopeValue(profile?.householdId) ?? '<none>'} '
        'actualDataOwnerId='
        '${normalizeHouseholdScopeValue(actualDataOwnerUserId) ?? '<none>'} '
        'effectiveDataOwnerId='
        '${normalizeHouseholdScopeValue(effectiveDataOwnerUserId) ?? '<none>'} '
        'controllerDataOwnerId='
        '${normalizeHouseholdScopeValue(_currentDataOwnerUserId) ?? '<none>'} '
        'recoveryStaleOwnerId='
        '${recoveryState?.staleOwnerUserId ?? '<none>'} '
        'recoveryPersonalUserId='
        '${recoveryState?.personalUserId ?? '<none>'}';
  }

  InventoryItemMutationService get _mutations =>
      ref.read(inventoryItemMutationServiceProvider);

  InventoryItemDiscardService get _discards =>
      ref.read(inventoryItemDiscardServiceProvider);

  InventoryItemEditService get _edits =>
      ref.read(inventoryItemEditServiceProvider);

  /// Runs [change] on the queue with the current list, and publishes the
  /// list it wrote. When the stream delivered a list meanwhile, the change
  /// is laid over that list, so the next change in the queue starts from
  /// both (#309). A household switch or refresh meanwhile starts a new list.
  Future<T> _mutate<T>(
    T fallback,
    Future<InventoryItemChange<T>> Function(List<InventoryItem> items) change,
  ) {
    return _runSerializedTask<T>(
      operation: () async {
        final items = await _currentPersistedItems();
        final generation = _subscriptionGeneration;
        if (!ref.mounted) {
          return fallback;
        }
        final (:result, :written) = await change(items);
        final current = _persistedItems;
        if (written != null &&
            current != null &&
            ref.mounted &&
            generation == _subscriptionGeneration) {
          _persistedItems = applyInventoryItemChanges(
            current: current,
            previous: items,
            next: written,
          );
          _publishVisibleItems();
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
      _pendingDeletedItem = deleted;
    }
    return deleted != null;
  }

  /// Undo last deleted item.
  Future<bool> undoLastDeletedItem() async {
    final pendingDeletedItem = _pendingDeletedItem;
    if (pendingDeletedItem == null) {
      return false;
    }
    final restored = await _mutate(
      false,
      (items) => _mutations.restoreDeleted(items, pendingDeletedItem),
    );
    if (restored && identical(_pendingDeletedItem, pendingDeletedItem)) {
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

  /// Adds a newly created item and publishes it once it is written, so
  /// follow-up flows can reference it before the realtime repository catches
  /// up.
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
    return _runSerializedTask<PendingInventoryConsumption?>(
      operation: () async {
        final pendings = ref.read(inventoryPendingConsumptionStoreProvider);
        final item = findInventoryItem(await _currentVisibleItems(), itemId);
        final draft = item == null ? null : pendings.stage(item, amount);
        _publishVisibleItems();
        return draft;
      },
      fallbackValue: null,
    );
  }

  Future<T> _runSerializedTask<T>({
    required Future<T> Function() operation,
    required T fallbackValue,
  }) {
    return _mutationQueue.run<T>(
      operation: operation,
      fallbackValue: fallbackValue,
      onError: (error, stackTrace) {
        log(
          'Unexpected inventory mutation error.',
          name: _controllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<List<InventoryItem>> _currentPersistedItems() async {
    final persistedItems = _persistedItems;
    if (persistedItems != null) {
      return persistedItems;
    }

    if (!ref.mounted) {
      return const <InventoryItem>[];
    }
    final repository = ref.read(inventoryItemRepositoryProvider);
    final items = await repository.readAll();
    if (!ref.mounted) {
      return items;
    }
    _persistedItems = items;
    return items;
  }

  Future<List<InventoryItem>> _currentVisibleItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }

    return await _currentPersistedItems();
  }

  void _publishVisibleItems() {
    if (!ref.mounted) {
      return;
    }

    final persistedItems = _persistedItems;
    if (persistedItems == null) {
      return;
    }
    state = AsyncData(persistedItems);
  }
}
