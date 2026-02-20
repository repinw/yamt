import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

part 'fridge_items_controller.g.dart';

@riverpod
class FridgeItemsController extends _$FridgeItemsController {
  @override
  FutureOr<List<FridgeItem>> build() {
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

  Future<bool> throwAwayItem(String itemId) {
    // Until quantity-based removals are introduced, throwing away removes item.
    return deleteItem(itemId);
  }

  Future<List<FridgeItem>> _currentItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return _loadItems();
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
