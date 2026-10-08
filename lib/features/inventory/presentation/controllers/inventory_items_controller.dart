import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/application/'
    'household_permission_recovery.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';

part 'inventory_items_controller.g.dart';

const _controllerLogName = 'InventoryItemsController';

/// Takes [amount] out of the item [itemId], capped at what the item holds.
///
/// Returns null when the item is missing, empty, or [amount] is below 1.
@visibleForTesting
List<InventoryItem>? buildReducedItems({
  required List<InventoryItem> currentItems,
  required String itemId,
  required int amount,
  required DateTime consumedAt,
}) {
  final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
  if (itemIndex < 0) {
    return null;
  }

  final item = currentItems[itemIndex];
  final available = item.availableAmount;
  final reducedItem = item.reducedBy(
    amount > available ? available : amount,
    consumedAt: consumedAt,
  );
  if (reducedItem == null) {
    return null;
  }
  return List<InventoryItem>.from(currentItems)..[itemIndex] = reducedItem;
}

/// Builds an edited item while preserving remaining stock for metadata edits.
@visibleForTesting
InventoryItem buildInventoryItemEditSaveItem({
  required InventoryItem currentItem,
  required InventoryItem editedItem,
}) {
  if (!_hasSameInventoryStockDefinition(
    currentItem: currentItem,
    editedItem: editedItem,
  )) {
    return editedItem;
  }

  return editedItem.copyWith(
    quantity: currentItem.quantity,
    initialQuantity: currentItem.initialQuantity,
    initialAmount: currentItem.initialAmount,
    currentAmount: currentItem.currentAmount,
    amountScale: currentItem.amountScale,
    amountUnit: currentItem.amountUnit,
    lastConsumedAt: currentItem.lastConsumedAt,
  );
}

bool _hasSameInventoryStockDefinition({
  required InventoryItem currentItem,
  required InventoryItem editedItem,
}) {
  return editedItem.quantity == currentItem.quantity &&
      editedItem.initialAmount == currentItem.initialAmount &&
      editedItem.amountScale == currentItem.amountScale &&
      editedItem.amountUnit == currentItem.amountUnit;
}

/// Build restored items.
@visibleForTesting
List<InventoryItem>? buildRestoredItems({
  required List<InventoryItem> currentItems,
  required String itemId,
  required int amount,
}) {
  if (amount < 1) {
    return null;
  }

  final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
  if (itemIndex < 0) {
    return null;
  }

  final restored = currentItems[itemIndex].restoredBy(amount);
  if (restored == null) {
    return null;
  }
  return List<InventoryItem>.from(currentItems)..[itemIndex] = restored;
}

class _PendingDeletedInventoryItem {
  const new({required this.item, required this.index});

  final InventoryItem item;
  final int index;
}

/// The result of reducing inventory item stock.
typedef InventoryItemReductionResult = ({int removedAmount});

/// The result of discarding inventory item stock.
typedef InventoryItemDiscardResult = ({
  String discardEventId,
  int removedAmount,
});

/// Defines inventory items controller.
@riverpod
class InventoryItemsController extends _$InventoryItemsController {
  static const _uuid = Uuid();

  // Subscription is cancelled by _disposeRealtimeSubscription.
  // ignore: cancel_subscriptions
  StreamSubscription<List<InventoryItem>>? _itemsSubscription;
  StreamSubscription<InventoryPendingConsumptionFinalized>?
  _pendingFinalizationSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  _PendingDeletedInventoryItem? _pendingDeletedItem;
  List<InventoryItem>? _persistedItems;
  String? _currentDataOwnerUserId;

  /// Read in [build], so a mutation that outlives the provider still has it.
  late DateTime Function() _clock;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<InventoryItem>> build() async {
    _clock = ref.watch(clockProvider);
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

  /// Delete item.
  Future<bool> deleteItem(String itemId) {
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        return false;
      }

      final nextItems = List<InventoryItem>.from(currentItems)
        ..removeAt(itemIndex);
      final saved = await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
      if (saved) {
        _pendingDeletedItem = _PendingDeletedInventoryItem(
          item: currentItems[itemIndex],
          index: itemIndex,
        );
        await _recordActivityEvent(
          _buildActivityEvent(
            type: InventoryActivityEventType.itemDeleted,
            item: currentItems[itemIndex],
            amount: currentItems[itemIndex].availableAmount,
            beforeItem: currentItems[itemIndex],
          ),
        );
      }
      return saved;
    });
  }

  /// Undo last deleted item.
  Future<bool> undoLastDeletedItem() {
    return _runSerializedMutation(() async {
      final pendingDeletedItem = _pendingDeletedItem;
      if (pendingDeletedItem == null) {
        return false;
      }

      final currentItems = await _currentPersistedItems();
      final itemAlreadyPresent = currentItems.any(
        (item) => item.id == pendingDeletedItem.item.id,
      );
      if (itemAlreadyPresent) {
        _pendingDeletedItem = null;
        return true;
      }

      final insertIndex = _safeInsertIndex(
        index: pendingDeletedItem.index,
        maxLength: currentItems.length,
      );
      final nextItems = List<InventoryItem>.from(currentItems)
        ..insert(insertIndex, pendingDeletedItem.item);
      final saved = await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
      if (saved) {
        await _recordActivityEvent(
          _buildActivityEvent(
            type: InventoryActivityEventType.itemRestored,
            item: pendingDeletedItem.item,
            amount: pendingDeletedItem.item.availableAmount,
            afterItem: pendingDeletedItem.item,
          ),
        );
        _pendingDeletedItem = null;
      }
      return saved;
    });
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

    return _runSerializedTask<InventoryItemReductionResult?>(
      operation: () async {
        final currentItems = await _currentPersistedItems();
        final removedAmount = _resolveEffectiveConsumptionAmount(
          currentItems: currentItems,
          itemId: itemId,
          requestedAmount: amount,
        );
        if (removedAmount == null) {
          return null;
        }

        final nextItems = buildReducedItems(
          currentItems: currentItems,
          itemId: itemId,
          amount: removedAmount,
          consumedAt: consumedAt ?? _clock(),
        );
        if (nextItems == null) {
          return null;
        }

        final saved = await _saveItems(
          previousItems: currentItems,
          nextItems: nextItems,
        );
        if (!saved) {
          return null;
        }

        final beforeItem = _findItem(currentItems, itemId);
        await _recordActivityEvent(
          _buildActivityEvent(
            type: InventoryActivityEventType.itemConsumed,
            item: beforeItem,
            amount: removedAmount,
            beforeItem: beforeItem,
            afterItem: _findItem(nextItems, itemId),
            happenedAt: consumedAt,
          ),
        );
        return (removedAmount: removedAmount);
      },
      fallbackValue: null,
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

    return _runSerializedTask<InventoryItemDiscardResult?>(
      operation: () async {
        final currentItems = await _currentPersistedItems();
        final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
        if (itemIndex < 0) {
          return null;
        }

        final item = currentItems[itemIndex];
        final discardedAmount = _resolveDiscardedAmount(
          item: item,
          requestedAmount: amount,
        );
        if (discardedAmount == null) {
          return null;
        }

        final nextItems = buildReducedItems(
          currentItems: currentItems,
          itemId: itemId,
          amount: discardedAmount,
          consumedAt: _clock(),
        );
        if (nextItems == null) {
          return null;
        }

        final saved = await _saveItems(
          previousItems: currentItems,
          nextItems: nextItems,
        );
        if (!saved) {
          return null;
        }

        final discardEventId = _uuid.v4();
        final discardEvent = InventoryDiscardEvent.fromInventoryItem(
          id: discardEventId,
          item: item,
          discardedAmount: discardedAmount,
          reason: reason,
        );
        final eventSaved = await ref
            .read(inventoryDiscardEventRepositoryProvider)
            .saveEvent(discardEvent);
        if (eventSaved) {
          await _recordActivityEvent(
            _buildActivityEvent(
              type: InventoryActivityEventType.itemDiscarded,
              item: item,
              amount: discardedAmount,
              beforeItem: item,
              afterItem: _findItem(nextItems, itemId),
              reason: reason.name,
            ),
          );
          return (
            discardEventId: discardEventId,
            removedAmount: discardedAmount,
          );
        }

        await _saveItems(previousItems: nextItems, nextItems: currentItems);
        return null;
      },
      fallbackValue: null,
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
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      var nextItems = currentItems;
      for (final MapEntry(key: itemId, value: amount)
          in amountsByItemId.entries) {
        final restored = buildRestoredItems(
          currentItems: nextItems,
          itemId: itemId,
          amount: amount,
        );
        if (restored == null) {
          return false;
        }
        nextItems = restored;
      }
      final saved = await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
      if (saved) {
        for (final MapEntry(key: itemId, value: amount)
            in amountsByItemId.entries) {
          final beforeItem = _findItem(currentItems, itemId);
          final afterItem = _findItem(nextItems, itemId);
          await _recordActivityEvent(
            _buildActivityEvent(
              type: InventoryActivityEventType.itemRestored,
              item: afterItem ?? beforeItem,
              amount: amount,
              beforeItem: beforeItem,
              afterItem: afterItem,
            ),
          );
        }
      }
      return saved;
    });
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

    return _runSerializedTask<bool>(
      operation: () async {
        final currentItems = await _currentPersistedItems();
        final restoredItems = buildRestoredItems(
          currentItems: currentItems,
          itemId: itemId,
          amount: amount,
        );
        if (restoredItems == null) {
          return false;
        }

        final restored = await _saveItems(
          previousItems: currentItems,
          nextItems: restoredItems,
        );
        if (!restored) {
          return false;
        }
        final beforeItem = _findItem(currentItems, itemId);
        final afterItem = _findItem(restoredItems, itemId);
        await _recordActivityEvent(
          _buildActivityEvent(
            type: InventoryActivityEventType.itemRestored,
            item: afterItem ?? beforeItem,
            amount: amount,
            beforeItem: beforeItem,
            afterItem: afterItem,
          ),
        );

        final deleted = await ref
            .read(inventoryDiscardEventRepositoryProvider)
            .deleteEvent(discardEventId);
        if (deleted) {
          return true;
        }

        final rolledBack = await _saveItems(
          previousItems: restoredItems,
          nextItems: currentItems,
        );
        if (!rolledBack) {
          log(
            'Failed to rollback thrown-away item undo after discard event '
            'delete failure (itemId=$itemId, discardEventId=$discardEventId).',
            name: _controllerLogName,
          );
        }
        return false;
      },
      fallbackValue: false,
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
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final itemIndex = currentItems.indexWhere(
        (currentItem) => currentItem.id == item.id,
      );
      if (itemIndex < 0) {
        return false;
      }
      final currentItem = currentItems[itemIndex];
      if (!currentItem.isFullyAvailable) {
        return false;
      }

      final nextItems = List<InventoryItem>.from(currentItems);
      nextItems[itemIndex] = buildInventoryItemEditSaveItem(
        currentItem: currentItem,
        editedItem: item,
      );
      return await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
    });
  }

  /// Replaces the product reference on an existing full inventory item.
  Future<bool> swapItemCandidate({
    required String itemId,
    required GlobalFoodItem resolvedProduct,
    required bool requiresGlobalPersistence,
    String? weight,
  }) {
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        return false;
      }

      final sourceItem = currentItems[itemIndex];
      if (!sourceItem.isFullyAvailable) {
        return false;
      }

      final canReferenceGlobalItem = await _persistResolvedProduct(
        resolvedProduct: resolvedProduct,
        requiresGlobalPersistence: requiresGlobalPersistence,
      );

      final nextItems = List<InventoryItem>.from(currentItems);
      nextItems[itemIndex] = _buildSwappedItem(
        sourceItem: sourceItem,
        resolvedProduct: resolvedProduct,
        weight: weight,
        canReferenceGlobalItem: canReferenceGlobalItem,
      );
      final saved = await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
      if (saved && canReferenceGlobalItem) {
        final barcode = resolvedProduct.normalizedBarcode;
        if (barcode != null && barcode.isNotEmpty) {
          await ref
              .read(globalBarcodeCandidateRepositoryProvider)
              .recordSelection(
                barcode: barcode,
                globalFoodItem: resolvedProduct,
                selectedAt: _clock(),
              );
        }
      }
      return saved;
    });
  }

  /// Adds a newly created item and publishes it immediately so follow-up
  /// flows can reference it before the realtime repository catches up.
  Future<bool> addItem(InventoryItem item) {
    return _runSerializedMutation(() async {
      final previousItems = await _currentPersistedItems();
      final nextItems = _mergePersistedItem(
        currentItems: previousItems,
        item: item,
      );
      _persistedItems = nextItems;
      _publishVisibleItems();

      final repository = ref.read(inventoryItemRepositoryProvider);
      try {
        final saved = await repository.appendAll(<InventoryItem>[item]);
        if (!saved) {
          _persistedItems = previousItems;
          _publishVisibleItems();
        } else {
          await _recordActivityEvent(
            _buildActivityEvent(
              type: InventoryActivityEventType.itemAdded,
              item: item,
              amount: item.availableAmount,
              afterItem: item,
            ),
          );
        }
        return saved;
      } on Object catch (error, stackTrace) {
        log(
          'Failed to append inventory item ${item.id}.',
          name: _controllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
        _persistedItems = previousItems;
        _publishVisibleItems();
        return false;
      }
    });
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
        final item = _findItem(await _currentVisibleItems(), itemId);
        final draft = item == null ? null : pendings.stage(item, amount);
        _publishVisibleItems();
        return draft;
      },
      fallbackValue: null,
    );
  }

  Future<bool> _saveItems({
    required List<InventoryItem> previousItems,
    required List<InventoryItem> nextItems,
  }) async {
    if (!ref.mounted) {
      return false;
    }
    _persistedItems = nextItems;
    _publishVisibleItems();

    final repository = ref.read(inventoryItemRepositoryProvider);
    try {
      final saved = await repository.saveChanges(
        previous: previousItems,
        next: nextItems,
      );
      if (!ref.mounted) {
        return saved;
      }
      if (!saved) {
        _persistedItems = previousItems;
        _publishVisibleItems();
      }
      return saved;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist inventory mutation.',
        name: _controllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      _persistedItems = previousItems;
      _publishVisibleItems();
      return false;
    }
  }

  Future<bool> _persistResolvedProduct({
    required GlobalFoodItem resolvedProduct,
    required bool requiresGlobalPersistence,
  }) async {
    if (!requiresGlobalPersistence) {
      return true;
    }

    try {
      return await ref.read(globalFoodItemRepositoryProvider).appendAll(
        <GlobalFoodItem>[resolvedProduct],
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist swapped product ${resolvedProduct.id}. '
        'Continuing with inventory-only save.',
        name: _controllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  InventoryItem _buildSwappedItem({
    required InventoryItem sourceItem,
    required GlobalFoodItem resolvedProduct,
    required String? weight,
    required bool canReferenceGlobalItem,
  }) {
    final updatedItem = sourceItem.copyWith(
      globalFoodItemId: canReferenceGlobalItem
          ? resolvedProduct.id
          : buildPendingGlobalFoodItemId(
              resolvedProduct.resolvedFoodFingerprint,
            ),
      name: resolvedProduct.name,
      brand: resolvedProduct.brand,
      category: resolvedProduct.category,
      barcode: resolvedProduct.barcode,
      imageUrl: resolvedProduct.imageUrl,
      weight: weight,
      foodFingerprint: resolvedProduct.resolvedFoodFingerprint,
      servingSize: resolvedProduct.servingSize,
      servingQuantity: resolvedProduct.servingQuantity,
      servingQuantityUnit: resolvedProduct.servingQuantityUnit,
      nutrition: resolvedProduct.nutrition,
    );
    return updatedItem.withDerivedAmount(
      weight: updatedItem.weight,
      quantity: updatedItem.quantity,
      fallbackUnit: sourceItem.amountUnit,
    );
  }

  int? _resolveDiscardedAmount({
    required InventoryItem item,
    required int requestedAmount,
  }) {
    final maxReducible = item.availableAmount;
    if (maxReducible < 1) {
      return null;
    }
    return requestedAmount > maxReducible ? maxReducible : requestedAmount;
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    return _runSerializedTask<bool>(operation: mutation, fallbackValue: false);
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

  int? _resolveEffectiveConsumptionAmount({
    required List<InventoryItem> currentItems,
    required String itemId,
    required int requestedAmount,
  }) {
    if (requestedAmount < 1) {
      return null;
    }

    final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) {
      return null;
    }

    final maxReducible = currentItems[itemIndex].availableAmount;
    if (maxReducible < 1) {
      return null;
    }
    return requestedAmount > maxReducible ? maxReducible : requestedAmount;
  }

  List<InventoryItem> _mergePersistedItem({
    required List<InventoryItem> currentItems,
    required InventoryItem item,
  }) {
    final nextItems = List<InventoryItem>.from(currentItems);
    final itemIndex = nextItems.indexWhere((current) => current.id == item.id);
    if (itemIndex < 0) {
      nextItems.add(item);
      return nextItems;
    }
    nextItems[itemIndex] = item;
    return nextItems;
  }

  InventoryActivityEvent? _buildActivityEvent({
    required InventoryActivityEventType type,
    required InventoryItem? item,
    required int amount,
    InventoryItem? beforeItem,
    InventoryItem? afterItem,
    DateTime? happenedAt,
    String? reason,
  }) {
    assert(amount >= 0, 'Amount cannot be negative');
    final actor = ref.read(inventoryActivityActorProvider);
    if (actor == null || item == null) {
      return null;
    }

    return InventoryActivityEvent.fromStockChange(
      id: _uuid.v4(),
      type: type,
      actor: actor,
      item: item,
      amount: amount < 0 ? 0 : amount,
      beforeQuantity: beforeItem?.quantity,
      afterQuantity: afterItem?.quantity,
      beforeCurrentAmount: beforeItem?.currentAmount,
      afterCurrentAmount: afterItem?.currentAmount,
      happenedAt: happenedAt,
      reason: reason,
    );
  }

  Future<void> _recordActivityEvent(InventoryActivityEvent? event) async {
    if (event == null) {
      return;
    }

    if (!ref.mounted) {
      return;
    }
    final repository = ref.read(inventoryActivityEventRepositoryProvider);
    final saved = await repository.appendAll(<InventoryActivityEvent>[event]);
    if (!ref.mounted) {
      return;
    }
    if (!saved) {
      log(
        'Failed to record inventory activity event ${event.id}.',
        name: _controllerLogName,
      );
    }
  }
}

int _safeInsertIndex({required int index, required int maxLength}) {
  if (index < 0) {
    return 0;
  }
  if (index > maxLength) {
    return maxLength;
  }
  return index;
}

InventoryItem? _findItem(List<InventoryItem> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) {
      return item;
    }
  }
  return null;
}
