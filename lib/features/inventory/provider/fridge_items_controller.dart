import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

part 'fridge_items_controller.g.dart';

@riverpod
class FridgeItemsController extends _$FridgeItemsController {
  StreamSubscription<List<FridgeItem>>? _itemsSubscription;

  @override
  FutureOr<List<FridgeItem>> build() {
    _subscribeToRealtimeUpdates();
    return _loadItems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(_loadItems);
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<List<FridgeItem>> _loadItems() {
    final repository = ref.read(fridgeItemRepositoryProvider);
    return repository.readAll();
  }

  void _subscribeToRealtimeUpdates() {
    final repository = ref.read(fridgeItemRepositoryProvider);
    final existingSubscription = _itemsSubscription;
    if (existingSubscription != null) {
      unawaited(existingSubscription.cancel());
    }

    _itemsSubscription = repository.watchAll().listen(
      _onRealtimeItems,
      onError: _onRealtimeError,
    );

    ref.onDispose(() {
      final currentSubscription = _itemsSubscription;
      _itemsSubscription = null;
      if (currentSubscription != null) {
        unawaited(currentSubscription.cancel());
      }
    });
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
    final currentItems = await _currentItems();
    final nextItems = currentItems
        .where((item) => item.id != itemId)
        .toList(growable: false);
    if (nextItems.length == currentItems.length) {
      return true;
    }
    return _saveItems(nextItems);
  }

  Future<bool> eatItem(String itemId, int amount) {
    return _reduceItem(itemId: itemId, amount: amount);
  }

  Future<bool> throwAwayItem(String itemId, int amount) {
    return _reduceItem(itemId: itemId, amount: amount);
  }

  Future<List<FridgeItem>> _currentItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return _loadItems();
  }

  Future<bool> _reduceItem({
    required String itemId,
    required int amount,
  }) async {
    if (amount < 1) {
      return false;
    }

    final currentItems = await _currentItems();
    final itemIndex = currentItems.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) {
      return true;
    }

    final item = currentItems[itemIndex];
    final maxReducible = _maxReducibleAmount(item);
    if (maxReducible < 1) {
      return true;
    }
    final reducedAmount = amount > maxReducible ? maxReducible : amount;

    final nextItems = List<FridgeItem>.from(currentItems);
    if (_usesAmountProgress(item)) {
      final nextCurrentAmount = item.currentAmount - reducedAmount;
      if (nextCurrentAmount <= 0) {
        nextItems.removeAt(itemIndex);
      } else {
        nextItems[itemIndex] = item.copyWith(
          currentAmount: nextCurrentAmount,
          quantity: _quantityForCurrentAmount(
            item: item,
            currentAmount: nextCurrentAmount,
          ),
        );
      }
      return _saveItems(nextItems);
    }

    final nextQuantity = item.quantity - reducedAmount;
    if (nextQuantity <= 0) {
      nextItems.removeAt(itemIndex);
    } else {
      nextItems[itemIndex] = item.copyWith(quantity: nextQuantity);
    }
    return _saveItems(nextItems);
  }

  bool _usesAmountProgress(FridgeItem item) {
    return item.amountUnit != null && item.initialAmount > 0;
  }

  int _maxReducibleAmount(FridgeItem item) {
    if (_usesAmountProgress(item)) {
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

  Future<bool> _saveItems(List<FridgeItem> items) async {
    final repository = ref.read(fridgeItemRepositoryProvider);
    final saved = await repository.saveAll(items);
    if (!ref.mounted || !saved) {
      return saved;
    }
    state = AsyncData(items);
    return true;
  }
}
