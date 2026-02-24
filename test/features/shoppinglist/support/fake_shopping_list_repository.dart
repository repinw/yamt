import 'dart:async';
import 'dart:collection';

import 'package:yamt/features/shoppinglist/data/shopping_list_repository_contract.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

class FakeShoppingListRepository implements ShoppingListRepository {
  FakeShoppingListRepository({
    List<ShoppingListItem>? initialItems,
    this.onReadAll,
  }) : _items = List<ShoppingListItem>.from(initialItems ?? const []);

  final Future<List<ShoppingListItem>> Function()? onReadAll;
  final StreamController<List<ShoppingListItem>> _watchController =
      StreamController<List<ShoppingListItem>>.broadcast();
  final Queue<bool> _saveResults = Queue<bool>();
  final Queue<Object> _saveErrors = Queue<Object>();

  List<ShoppingListItem> _items;
  List<ShoppingListItem> savedItems = const <ShoppingListItem>[];
  Duration saveDelay = Duration.zero;
  bool saveAllShouldFail = false;
  bool saveAllShouldThrow = false;
  bool emitRealtimeOnSave = true;

  @override
  Future<List<ShoppingListItem>> readAll() async {
    if (onReadAll != null) {
      return onReadAll!();
    }
    return _copyItems();
  }

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    return Stream<List<ShoppingListItem>>.multi((controller) {
      final watchSubscription = _watchController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      readAll().then(controller.add, onError: controller.addError);
      controller.onCancel = () {
        unawaited(watchSubscription.cancel());
      };
    });
  }

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }
    savedItems = List<ShoppingListItem>.from(items);

    if (_saveErrors.isNotEmpty) {
      throw _saveErrors.removeFirst();
    }
    if (saveAllShouldThrow) {
      throw StateError('saveAll failed');
    }
    if (_saveResults.isNotEmpty) {
      final result = _saveResults.removeFirst();
      if (result) {
        _items = List<ShoppingListItem>.from(items);
        if (emitRealtimeOnSave) {
          _watchController.add(_copyItems());
        }
      }
      return result;
    }
    if (saveAllShouldFail) {
      return false;
    }

    _items = List<ShoppingListItem>.from(items);
    if (emitRealtimeOnSave) {
      _watchController.add(_copyItems());
    }
    return true;
  }

  void emitWatchItems(List<ShoppingListItem> items) {
    _items = List<ShoppingListItem>.from(items);
    _watchController.add(_copyItems());
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _watchController.addError(error, stackTrace);
  }

  void enqueueSaveResult(bool result) {
    _saveResults.add(result);
  }

  void enqueueSaveError(Object error) {
    _saveErrors.add(error);
  }

  Future<void> dispose() {
    return _watchController.close();
  }

  List<ShoppingListItem> _copyItems() {
    return List<ShoppingListItem>.from(_items);
  }
}
