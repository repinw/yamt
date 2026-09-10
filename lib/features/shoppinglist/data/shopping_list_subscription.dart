import 'dart:async';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository_contract.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Manages the initial snapshot and subsequent realtime notifications.
class ShoppingListSubscription {
  Future<void> Function()? _cancelSubscription;
  Completer<List<ShoppingListItem>>? _initial;
  int _generation = 0;

  /// Replaces the stream and returns its first snapshot.
  Future<List<ShoppingListItem>> start(
    ShoppingListRepository repository, {
    required void Function(List<ShoppingListItem>) onData,
    required void Function(Object, StackTrace) onError,
  }) async {
    final pendingCancel = cancel();
    final generation = _generation;
    await pendingCancel;
    if (generation != _generation) return [];
    final initial = _initial = Completer<List<ShoppingListItem>>();
    final subscription = repository.watchAll().listen(
      (items) {
        if (!initial.isCompleted) {
          initial.complete(items);
        } else {
          onData(items);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!initial.isCompleted) {
          initial.completeError(error, stack);
        } else {
          onError(error, stack);
        }
      },
      onDone: () {
        if (!initial.isCompleted) initial.complete([]);
      },
    );
    _cancelSubscription = subscription.cancel;
    return initial.future;
  }

  /// Releases realtime resources.
  Future<void> cancel() async {
    _generation++;
    final cancelSubscription = _cancelSubscription;
    _cancelSubscription = null;
    final initial = _initial;
    _initial = null;
    if (initial != null && !initial.isCompleted) initial.complete([]);
    await cancelSubscription?.call();
  }
}
