import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_facade.dart';

part 'fridge_items_controller.g.dart';

const _controllerLogName = 'FridgeItemsController';

@riverpod
class FridgeItemsController extends _$FridgeItemsController {
  StreamSubscription<List<FridgeItem>>? _itemsSubscription;
  final _mutationQueue = SerializedMutationQueue();

  @override
  FutureOr<List<FridgeItem>> build() {
    // Reconnect stream when repository instance changes (for auth changes).
    ref.watch(fridgeItemRepositoryProvider);
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

  Future<List<FridgeItem>> _restartRealtimeSubscription() {
    final initialItems = Completer<List<FridgeItem>>();
    final repository = ref.read(fridgeItemRepositoryProvider);
    _disposeRealtimeSubscription();

    _itemsSubscription = repository.watchAll().listen(
      (items) {
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

  void _onRealtimeItems(List<FridgeItem> items) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(items);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  Future<bool> deleteItem(String itemId) async {
    return _runItemsMutation((currentItems) {
      final nextItems = currentItems
          .where((item) => item.id != itemId)
          .toList(growable: false);
      if (nextItems.length == currentItems.length) {
        return null;
      }
      return nextItems;
    });
  }

  Future<bool> eatItem(String itemId, int amount) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }
    return _runItemsMutation(
      (currentItems) => _buildReducedItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
      ),
    );
  }

  Future<bool> throwAwayItem(String itemId, int amount) {
    if (amount < 1) {
      return Future<bool>.value(false);
    }
    return _runItemsMutation(
      (currentItems) => _buildReducedItems(
        currentItems: currentItems,
        itemId: itemId,
        amount: amount,
      ),
    );
  }

  Future<bool> buyAgainItem(FridgeItem item) {
    return ref.read(shoppingListFacadeProvider).addInventoryItem(item);
  }

  Future<List<FridgeItem>> _currentItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return future;
  }

  List<FridgeItem>? _buildReducedItems({
    required List<FridgeItem> currentItems,
    required String itemId,
    required int amount,
  }) {
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

    final nextItems = List<FridgeItem>.from(currentItems);
    if (item.usesAmountProgress) {
      final nextCurrentAmount = item.currentAmount - reducedAmount;
      final safeCurrentAmount = nextCurrentAmount < 0 ? 0 : nextCurrentAmount;
      nextItems[itemIndex] = item.copyWith(
        currentAmount: safeCurrentAmount,
        quantity: _quantityForCurrentAmount(
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

  Future<bool> _runItemsMutation(
    List<FridgeItem>? Function(List<FridgeItem> currentItems) mutation,
  ) {
    return _runSerializedMutation(() async {
      final currentItems = await _currentItems();
      final nextItems = mutation(currentItems);
      if (nextItems == null) {
        return true;
      }
      return _saveItems(previousItems: currentItems, nextItems: nextItems);
    });
  }

  int _maxReducibleAmount(FridgeItem item) {
    if (item.usesAmountProgress) {
      final currentAmount = item.currentAmount;
      return currentAmount > 0 ? currentAmount : 0;
    }
    final quantity = item.quantity;
    return quantity > 0 ? quantity : 0;
  }

  int _quantityForCurrentAmount({
    required FridgeItem item,
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

  Future<bool> _saveItems({
    required List<FridgeItem> previousItems,
    required List<FridgeItem> nextItems,
  }) async {
    if (ref.mounted) {
      state = AsyncData(nextItems);
    }

    final repository = ref.read(fridgeItemRepositoryProvider);
    try {
      final saved = await repository.saveAll(nextItems);
      if (!saved && ref.mounted) {
        state = AsyncData(previousItems);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to persist inventory mutation.',
        name: _controllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previousItems);
      }
      return false;
    }
  }

  Future<bool> _runSerializedMutation(Future<bool> Function() mutation) {
    return _mutationQueue.run<bool>(
      operation: mutation,
      fallbackValue: false,
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
}
