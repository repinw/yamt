import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/'
    'household_access_recovery_utils.dart';
import 'package:yamt/features/household/provider/'
    'household_permission_recovery.dart';
import 'package:yamt/features/household/provider/household_scope_provider.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

part 'inventory_items_controller.g.dart';

const _controllerLogName = 'InventoryItemsController';

/// Build reduced items.
@visibleForTesting
List<InventoryItem>? buildReducedItems({
  required List<InventoryItem> currentItems,
  required String itemId,
  required int amount,
  DateTime? consumedAt,
}) {
  if (amount < 1) {
    return null;
  }

  final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
  if (itemIndex < 0) {
    return null;
  }

  final item = currentItems[itemIndex];
  final maxReducible = _maxReducibleAmount(item);
  if (maxReducible < 1) {
    return null;
  }
  final reducedAmount = amount > maxReducible ? maxReducible : amount;
  final effectiveConsumedAt = item.latestConsumedAtOr(
    consumedAt ?? DateTime.now(),
  );

  final nextItems = List<InventoryItem>.from(currentItems);
  if (item.usesAmountProgress) {
    final nextCurrentAmount = item.currentAmount - reducedAmount;
    final safeCurrentAmount = nextCurrentAmount < 0 ? 0 : nextCurrentAmount;
    nextItems[itemIndex] = item.copyWith(
      currentAmount: safeCurrentAmount,
      quantity: quantityForCurrentAmount(
        item: item,
        currentAmount: safeCurrentAmount,
      ),
      lastConsumedAt: effectiveConsumedAt,
    );
    return nextItems;
  }

  final nextQuantity = item.quantity - reducedAmount;
  final safeQuantity = nextQuantity < 0 ? 0 : nextQuantity;
  nextItems[itemIndex] = item.copyWith(
    quantity: safeQuantity,
    lastConsumedAt: effectiveConsumedAt,
  );
  return nextItems;
}

int _maxReducibleAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    final currentAmount = item.currentAmount;
    return currentAmount > 0 ? currentAmount : 0;
  }
  final quantity = item.quantity;
  return quantity > 0 ? quantity : 0;
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

  final item = currentItems[itemIndex];
  final nextItems = List<InventoryItem>.from(currentItems);
  if (item.usesAmountProgress) {
    final restoredCurrentAmount = item.currentAmount + amount;
    final maxAmount = item.initialAmount > 0
        ? item.initialAmount
        : restoredCurrentAmount;
    final safeCurrentAmount = restoredCurrentAmount > maxAmount
        ? maxAmount
        : restoredCurrentAmount;
    final restoredItem = item.copyWith(
      currentAmount: safeCurrentAmount,
      quantity: quantityForCurrentAmount(
        item: item,
        currentAmount: safeCurrentAmount,
      ),
    );
    nextItems[itemIndex] = restoredItem.copyWith(
      lastConsumedAt: restoredItem.isFullyAvailable
          ? null
          : restoredItem.lastConsumedAt,
    );
    return nextItems;
  }

  final restoredQuantity = item.quantity + amount;
  final maxQuantity = item.initialQuantity > 0
      ? item.initialQuantity
      : restoredQuantity;
  final safeQuantity = restoredQuantity > maxQuantity
      ? maxQuantity
      : restoredQuantity;
  final restoredItem = item.copyWith(quantity: safeQuantity);
  nextItems[itemIndex] = restoredItem.copyWith(
    lastConsumedAt: restoredItem.isFullyAvailable
        ? null
        : restoredItem.lastConsumedAt,
  );
  return nextItems;
}

/// Quantity for current amount.
@visibleForTesting
int quantityForCurrentAmount({
  required InventoryItem item,
  required int currentAmount,
}) {
  final initialAmount = item.initialAmount;
  final initialQuantity = item.initialQuantity;
  if (initialAmount < 1 || initialQuantity < 1) {
    return item.quantity;
  }

  final ratio = currentAmount / initialAmount;
  final projectedQuantity = (initialQuantity * ratio).ceil();
  if (projectedQuantity < 0) {
    return 0;
  }
  if (projectedQuantity > initialQuantity) {
    return initialQuantity;
  }
  return projectedQuantity;
}

class _PendingDeletedInventoryItem {
  const _PendingDeletedInventoryItem({required this.item, required this.index});

  final InventoryItem item;
  final int index;
}

/// Defines pending inventory consumption.
class PendingInventoryConsumption {
  /// The pending inventory consumption.
  const PendingInventoryConsumption({
    required this.id,
    required this.itemId,
    required this.amount,
  });

  /// The id.
  final String id;

  /// The item id.
  final String itemId;

  /// The amount.
  final int amount;
}

/// Defines inventory items controller.
@Riverpod(dependencies: [inventoryItemRepository])
class InventoryItemsController extends _$InventoryItemsController {
  static const _uuid = Uuid();

  StreamSubscription<List<InventoryItem>>? _itemsSubscription;
  int _subscriptionGeneration = 0;
  final _mutationQueue = SerializedMutationQueue();
  _PendingDeletedInventoryItem? _pendingDeletedItem;
  final Map<String, PendingInventoryConsumption> _pendingConsumptionsById =
      <String, PendingInventoryConsumption>{};
  List<InventoryItem>? _persistedItems;
  int _pendingConsumptionDraftCounter = 0;
  String? _currentDataOwnerUserId;
  bool _isRecoveringHouseholdAccess = false;

  @override
  FutureOr<List<InventoryItem>> build() {
    ref.watch(householdDataOwnerUserIdProvider);
    _currentDataOwnerUserId = ref.watch(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    ref.watch(inventoryItemRepositoryProvider);
    ref.onDispose(() {
      unawaited(_disposeRealtimeSubscription());
    });
    return _restartRealtimeSubscription();
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
    _currentDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
    final repository = ref.read(inventoryItemRepositoryProvider);
    final generation = ++_subscriptionGeneration;
    await _disposeRealtimeSubscription();
    _persistedItems = null;
    _pendingDeletedItem = null;
    _pendingConsumptionsById.clear();

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
    return initialItems.future;
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

  bool _shouldRecoverFromRevokedHouseholdAccess(Object error) {
    final actualDataOwnerUserId = ref.read(householdDataOwnerUserIdProvider);
    final effectiveDataOwnerUserId = ref.read(
      effectiveHouseholdDataOwnerUserIdProvider,
    );
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
      setIsRecoveringHouseholdAccess: (value) {
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
    log(
      'Permission denied while watching inventory. '
      'shouldRecover=$shouldRecover '
      '${_buildScopeDebugDetails(actualDataOwnerUserId: actualDataOwnerUserId, effectiveDataOwnerUserId: effectiveDataOwnerUserId)}',
      name: _controllerLogName,
    );
  }

  /// On skipped household access recovery.
  void onSkippedHouseholdAccessRecovery() {
    log(
      'Inventory access recovery had no owner swap candidate. '
      '${_buildScopeDebugDetails(actualDataOwnerUserId: ref.read(householdDataOwnerUserIdProvider), effectiveDataOwnerUserId: ref.read(effectiveHouseholdDataOwnerUserIdProvider))}',
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
        _pendingDeletedItem = null;
      }
      return saved;
    });
  }

  /// Eat item.
  Future<bool> eatItem(String itemId, int amount, {DateTime? consumedAt}) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }
    return _runItemsMutation(
      (currentItems) => buildReducedItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
        consumedAt: consumedAt,
      ),
    );
  }

  /// Throw away item.
  Future<bool> throwAwayItem(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  ) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }

    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        return false;
      }

      final item = currentItems[itemIndex];
      final discardedAmount = _resolveDiscardedAmount(
        item: item,
        requestedAmount: amount,
      );
      if (discardedAmount == null) {
        return false;
      }

      final nextItems = buildReducedItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
      );
      if (nextItems == null) {
        return false;
      }

      final saved = await _saveItems(
        previousItems: currentItems,
        nextItems: nextItems,
      );
      if (!saved) {
        return false;
      }

      final discardEvent = InventoryDiscardEvent.fromInventoryItem(
        id: _uuid.v4(),
        item: item,
        discardedAmount: discardedAmount,
        reason: reason,
      );
      final eventSaved = await ref
          .read(inventoryDiscardEventRepositoryProvider)
          .saveEvent(discardEvent);
      if (eventSaved) {
        return true;
      }

      await _saveItems(previousItems: nextItems, nextItems: currentItems);
      return false;
    });
  }

  /// Restore consumed item.
  Future<bool> restoreConsumedItem(String itemId, int amount) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final nextItems = buildRestoredItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
      );
      if (nextItems == null) {
        return false;
      }
      return _saveItems(previousItems: currentItems, nextItems: nextItems);
    });
  }

  /// Mark barcode lookup requested.
  Future<bool> markBarcodeLookupRequested(String itemId) {
    return _runItemsMutation((currentItems) {
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        return null;
      }

      final current = currentItems[itemIndex];
      final now = DateTime.now();
      final updated = current.copyWith(
        barcodeLookupRequestedAt: now,
        barcodeCandidates: const <String>[],
        barcodeLookupUncertain: false,
      );
      final nextItems = List<InventoryItem>.from(currentItems);
      nextItems[itemIndex] = updated;
      return nextItems;
    });
  }

  /// Set item barcode.
  Future<bool> setItemBarcode({
    required String itemId,
    required String barcode,
  }) {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      return Future<bool>.value(false);
    }

    return _runItemsMutation((currentItems) {
      final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        return null;
      }

      final current = currentItems[itemIndex];
      final now = DateTime.now();
      final updated = current.copyWith(
        barcode: normalized,
        barcodeCandidates: <String>[normalized],
        barcodeResolvedAt: now,
        barcodeLookupUncertain: false,
      );
      final nextItems = List<InventoryItem>.from(currentItems);
      nextItems[itemIndex] = updated;
      return nextItems;
    });
  }

  /// Buy again item.
  Future<bool> buyAgainItem(InventoryItem item) {
    return addInventoryItemToShoppingList(
      item: item,
      addItem: ref.read(shoppingListControllerProvider.notifier).addItem,
    );
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
                selectedAt: DateTime.now(),
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
        }
        return saved;
      } catch (error, stackTrace) {
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

  /// Stage pending consumption.
  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) {
    if (amount < 1) {
      return Future<PendingInventoryConsumption?>.value();
    }
    return _runSerializedTask<PendingInventoryConsumption?>(
      operation: () async {
        final visibleItems = await _currentVisibleItems();
        final draft = _createPendingConsumption(
          currentItems: visibleItems,
          itemId: itemId,
          requestedAmount: amount,
        );
        _publishVisibleItems();
        return draft;
      },
      fallbackValue: null,
    );
  }

  /// Pending consumption by id.
  PendingInventoryConsumption? pendingConsumptionById(String draftId) {
    return _pendingConsumptionsById[draftId];
  }

  /// Has pending consumption.
  bool hasPendingConsumption(String draftId) {
    return _pendingConsumptionsById.containsKey(draftId);
  }

  /// Discard pending consumption.
  Future<bool> discardPendingConsumption(String draftId) {
    return _runSerializedTask<bool>(
      operation: () async {
        final removed = _pendingConsumptionsById.remove(draftId);
        if (removed == null) {
          return false;
        }
        _publishVisibleItems();
        return true;
      },
      fallbackValue: false,
    );
  }

  /// Finalize committed pending consumption.
  Future<bool> finalizeCommittedPendingConsumption({
    required String draftId,
    required String itemId,
    required int quantity,
    required int currentAmount,
    DateTime? consumedAt,
  }) {
    return _runSerializedTask<bool>(
      operation: () async {
        final draft = _pendingConsumptionsById.remove(draftId);
        if (draft == null) {
          return false;
        }

        final currentItems = _persistedItems;
        if (currentItems == null) {
          _publishVisibleItems();
          return false;
        }

        final nextItems = List<InventoryItem>.from(currentItems);
        final itemIndex = nextItems.indexWhere((item) => item.id == itemId);
        if (itemIndex < 0) {
          _publishVisibleItems();
          return false;
        }

        final currentItem = nextItems[itemIndex];
        nextItems[itemIndex] = currentItem.copyWith(
          quantity: quantity,
          currentAmount: currentAmount,
          lastConsumedAt: consumedAt == null
              ? currentItem.lastConsumedAt
              : currentItem.latestConsumedAtOr(consumedAt),
        );
        _persistedItems = nextItems;
        _publishVisibleItems();
        return true;
      },
      fallbackValue: false,
    );
  }

  Future<bool> _runItemsMutation(
    List<InventoryItem>? Function(List<InventoryItem> currentItems) mutation,
  ) {
    return _runSerializedMutation(() async {
      final currentItems = await _currentPersistedItems();
      final nextItems = mutation(currentItems);
      if (nextItems == null) {
        return true;
      }
      return _saveItems(previousItems: currentItems, nextItems: nextItems);
    });
  }

  Future<bool> _saveItems({
    required List<InventoryItem> previousItems,
    required List<InventoryItem> nextItems,
  }) async {
    _persistedItems = nextItems;
    _publishVisibleItems();

    final repository = ref.read(inventoryItemRepositoryProvider);
    try {
      final saved = await repository.saveAll(nextItems);
      if (!saved) {
        _persistedItems = previousItems;
        _publishVisibleItems();
      }
      return saved;
    } catch (error, stackTrace) {
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
    } catch (error, stackTrace) {
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
    final maxReducible = _maxReducibleAmount(item);
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

    final items = await ref.read(inventoryItemRepositoryProvider).readAll();
    _persistedItems = items;
    return items;
  }

  Future<List<InventoryItem>> _currentVisibleItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }

    return _currentPersistedItems();
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

    final maxReducible = _maxReducibleAmount(currentItems[itemIndex]);
    if (maxReducible < 1) {
      return null;
    }
    return requestedAmount > maxReducible ? maxReducible : requestedAmount;
  }

  PendingInventoryConsumption? _createPendingConsumption({
    required List<InventoryItem> currentItems,
    required String itemId,
    required int requestedAmount,
  }) {
    final effectiveAmount = _resolveEffectiveConsumptionAmount(
      currentItems: currentItems,
      itemId: itemId,
      requestedAmount: requestedAmount,
    );
    if (effectiveAmount == null) {
      return null;
    }

    final draft = PendingInventoryConsumption(
      id: _nextPendingConsumptionId(),
      itemId: itemId,
      amount: effectiveAmount,
    );
    _pendingConsumptionsById[draft.id] = draft;
    return draft;
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

  String _nextPendingConsumptionId() {
    _pendingConsumptionDraftCounter += 1;
    return 'pending-consumption-$_pendingConsumptionDraftCounter';
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
