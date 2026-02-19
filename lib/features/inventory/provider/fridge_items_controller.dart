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
}
