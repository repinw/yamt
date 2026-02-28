import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_controller.g.dart';

const _controllerLogName = 'ShoppingListController';

@riverpod
class ShoppingListController extends _$ShoppingListController {
  static const _uuid = Uuid();

  StreamSubscription<List<ShoppingListItem>>? _itemsSubscription;
  final _mutationQueue = _SerializedMutationQueue();

  @override
  FutureOr<List<ShoppingListItem>> build() {
    ref.watch(shoppingListRepositoryProvider);
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

  Future<bool> addItem({
    required String name,
    String? brand,
    int quantity = 1,
    double estimatedUnitPrice = 0.0,
  }) {
    final input = _parseAddItemInput(
      name: name,
      brand: brand,
      quantity: quantity,
      estimatedUnitPrice: estimatedUnitPrice,
    );
    if (input == null) {
      return Future<bool>.value(false);
    }

    return _runListMutation((previousItems) {
      return _mergeAddedItem(
        previousItems: previousItems,
        input: input,
        generatedId: _nextId(),
      );
    });
  }

  Future<bool> removeItem(String itemId) {
    return _runListMutation((previousItems) {
      final nextItems = previousItems
          .where((item) => item.id != itemId)
          .toList(growable: false);
      if (nextItems.length == previousItems.length) {
        return null;
      }
      return nextItems;
    });
  }

  Future<bool> incrementQuantity(String itemId) {
    return _runListMutation(_buildQuantityMutation(itemId, (q) => q + 1));
  }

  Future<bool> decrementQuantity(String itemId) {
    return _runListMutation(_buildQuantityMutation(itemId, (q) => q - 1));
  }

  Future<bool> clearCrossedOffItems() {
    return _runListMutation((previousItems) {
      final nextItems = previousItems
          .where((item) => item.quantity > 0)
          .toList(growable: false);
      if (nextItems.length == previousItems.length) {
        return null;
      }
      return nextItems;
    });
  }

  _AddShoppingListItemInput? _parseAddItemInput({
    required String name,
    String? brand,
    required int quantity,
    required double estimatedUnitPrice,
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final safePrice = estimatedUnitPrice < 0 ? 0.0 : estimatedUnitPrice;
    final trimmedName = name.trim();
    final trimmedBrand = brand?.trim();
    final safeBrand = (trimmedBrand == null || trimmedBrand.isEmpty)
        ? null
        : trimmedBrand;
    final normalizedName = _normalize(trimmedName);
    if (normalizedName.isEmpty) {
      return null;
    }

    return _AddShoppingListItemInput(
      name: trimmedName,
      brand: safeBrand,
      normalizedName: normalizedName,
      normalizedBrand: _normalize(safeBrand ?? ''),
      quantity: safeQuantity,
      estimatedUnitPrice: safePrice,
    );
  }

  List<ShoppingListItem> _mergeAddedItem({
    required List<ShoppingListItem> previousItems,
    required _AddShoppingListItemInput input,
    required String generatedId,
  }) {
    final existingIndex = previousItems.indexWhere((item) {
      return item.normalizedName == input.normalizedName &&
          item.normalizedBrand == input.normalizedBrand;
    });
    if (existingIndex < 0) {
      return <ShoppingListItem>[
        ...previousItems,
        ShoppingListItem(
          id: generatedId,
          name: input.name,
          brand: input.brand,
          normalizedName: input.normalizedName,
          normalizedBrand: input.normalizedBrand,
          quantity: input.quantity,
          estimatedUnitPrice: input.estimatedUnitPrice,
        ),
      ];
    }

    final nextItems = List<ShoppingListItem>.from(previousItems);
    final current = nextItems[existingIndex];
    nextItems[existingIndex] = current.copyWith(
      quantity: current.quantity + input.quantity,
      estimatedUnitPrice: input.estimatedUnitPrice > 0
          ? input.estimatedUnitPrice
          : current.estimatedUnitPrice,
    );
    return nextItems;
  }

  List<ShoppingListItem>? Function(List<ShoppingListItem>)
  _buildQuantityMutation(String itemId, int Function(int quantity) transform) {
    return (previousItems) {
      final index = previousItems.indexWhere((item) => item.id == itemId);
      if (index < 0) {
        return null;
      }

      final nextItems = List<ShoppingListItem>.from(previousItems);
      final item = nextItems[index];
      final nextQuantity = transform(item.quantity);
      final safeQuantity = nextQuantity < 0 ? 0 : nextQuantity;
      nextItems[index] = item.copyWith(quantity: safeQuantity);
      return nextItems;
    };
  }

  Future<bool> _runListMutation(
    List<ShoppingListItem>? Function(List<ShoppingListItem> previousItems)
    mutation,
  ) {
    return _runSerializedMutation(() => _mutateItems(mutation));
  }

  Future<bool> _mutateItems(
    List<ShoppingListItem>? Function(List<ShoppingListItem> previousItems)
    mutation,
  ) async {
    final previousItems = await _currentItems();
    final nextItems = mutation(previousItems);
    if (nextItems == null) {
      return true;
    }
    return _saveItems(previousItems: previousItems, nextItems: nextItems);
  }

  Future<List<ShoppingListItem>> _restartRealtimeSubscription() {
    final initialItems = Completer<List<ShoppingListItem>>();
    final repository = ref.read(shoppingListRepositoryProvider);
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

  void _onRealtimeItems(List<ShoppingListItem> items) {
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

  Future<List<ShoppingListItem>> _currentItems() async {
    final currentData = state.asData?.value;
    if (currentData != null) {
      return currentData;
    }
    return future;
  }

  Future<bool> _saveItems({
    required List<ShoppingListItem> previousItems,
    required List<ShoppingListItem> nextItems,
  }) async {
    if (ref.mounted) {
      state = AsyncData(nextItems);
    }

    final repository = ref.read(shoppingListRepositoryProvider);
    try {
      final saved = await repository.saveAll(nextItems);
      if (!saved && ref.mounted) {
        state = AsyncData(previousItems);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to persist shopping list mutation.',
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
          'Unexpected shopping list mutation error.',
          name: _controllerLogName,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _nextId() {
    return _uuid.v4();
  }
}

class _AddShoppingListItemInput {
  const _AddShoppingListItemInput({
    required this.name,
    required this.brand,
    required this.normalizedName,
    required this.normalizedBrand,
    required this.quantity,
    required this.estimatedUnitPrice,
  });

  final String name;
  final String? brand;
  final String normalizedName;
  final String normalizedBrand;
  final int quantity;
  final double estimatedUnitPrice;
}

class _SerializedMutationQueue {
  Future<void> _queue = Future<void>.value();

  Future<T> run<T>({
    required Future<T> Function() operation,
    required T fallbackValue,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) {
    final result = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final value = await operation();
        result.complete(value);
      } catch (error, stackTrace) {
        onError(error, stackTrace);
        result.complete(fallbackValue);
      }
    });
    return result.future;
  }
}
