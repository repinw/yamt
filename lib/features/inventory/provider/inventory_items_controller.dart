import 'dart:async';
import 'dart:developer' show log;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';

part 'inventory_items_controller.g.dart';

const _controllerLogName = 'InventoryItemsController';

@visibleForTesting
List<InventoryItem>? buildReducedItems({
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
  final maxReducible = _maxReducibleAmount(item);
  if (maxReducible < 1) {
    return null;
  }
  final reducedAmount = amount > maxReducible ? maxReducible : amount;

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
    );
    return nextItems;
  }

  final nextQuantity = item.quantity - reducedAmount;
  final safeQuantity = nextQuantity < 0 ? 0 : nextQuantity;
  nextItems[itemIndex] = item.copyWith(quantity: safeQuantity);
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
    nextItems[itemIndex] = item.copyWith(
      currentAmount: safeCurrentAmount,
      quantity: quantityForCurrentAmount(
        item: item,
        currentAmount: safeCurrentAmount,
      ),
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
  nextItems[itemIndex] = item.copyWith(quantity: safeQuantity);
  return nextItems;
}

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

class PendingInventoryConsumption {
  const PendingInventoryConsumption({
    required this.id,
    required this.itemId,
    required this.amount,
  });

  final String id;
  final String itemId;
  final int amount;
}

@riverpod
class InventoryItemsController extends _$InventoryItemsController {
  static const _uuid = Uuid();

  StreamSubscription<List<InventoryItem>>? _itemsSubscription;
  final _mutationQueue = SerializedMutationQueue();
  _PendingDeletedInventoryItem? _pendingDeletedItem;
  final Map<String, PendingInventoryConsumption> _pendingConsumptionsById =
      <String, PendingInventoryConsumption>{};
  List<InventoryItem>? _persistedItems;
  int _pendingConsumptionDraftCounter = 0;

  @override
  FutureOr<List<InventoryItem>> build() {
    ref.watch(inventoryItemRepositoryProvider);
    ref.onDispose(_disposeRealtimeSubscription);
    return _restartRealtimeSubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(_restartRealtimeSubscription);
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<List<InventoryItem>> _restartRealtimeSubscription() {
    final initialItems = Completer<List<InventoryItem>>();
    final repository = ref.read(inventoryItemRepositoryProvider);
    _disposeRealtimeSubscription();

    _itemsSubscription = repository.watchAll().listen(
      (items) {
        _persistedItems = items;
        if (!initialItems.isCompleted) {
          initialItems.complete(items);
          return;
        }
        _onRealtimeItems(items);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initialItems.isCompleted) {
          initialItems.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );
    return initialItems.future;
  }

  void _disposeRealtimeSubscription() {
    final currentSubscription = _itemsSubscription;
    _itemsSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
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
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

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

  Future<bool> eatItem(String itemId, int amount) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }
    return _runItemsMutation(
      (currentItems) => buildReducedItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
      ),
    );
  }

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

  Future<bool> buyAgainItem(InventoryItem item) {
    return addInventoryItemToShoppingList(
      item: item,
      addItem: ref.read(shoppingListControllerProvider.notifier).addItem,
    );
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

  Future<PendingInventoryConsumption?> stagePendingConsumption(
    String itemId,
    int amount,
  ) {
    if (amount < 1) {
      return Future<PendingInventoryConsumption?>.value(null);
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

  PendingInventoryConsumption? pendingConsumptionById(String draftId) {
    return _pendingConsumptionsById[draftId];
  }

  bool hasPendingConsumption(String draftId) {
    return _pendingConsumptionsById.containsKey(draftId);
  }

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

  Future<bool> finalizeCommittedPendingConsumption({
    required String draftId,
    required String itemId,
    required int quantity,
    required int currentAmount,
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
    return 'pending-consumption-${_pendingConsumptionDraftCounter.toString()}';
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
