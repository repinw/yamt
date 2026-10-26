import 'dart:async';

import 'package:yamt/features/inventory/domain/inventory_item.dart';

import 'inventory_item_whole_list_writes.dart';

/// Holds the Vorrat in memory and streams every write asynchronously, like
/// Firestore does.
class FakeInventoryItemRepository with InventoryItemWholeListWrites {
  /// Creates the Vorrat with [items].
  new(List<InventoryItem> items) : items = List.of(items);

  /// The stored Vorrat.
  List<InventoryItem> items;

  /// Whether writes succeed.
  bool saves = true;

  /// Holds each write open until completed, when set.
  Completer<void>? hold;

  final _changes = StreamController<List<InventoryItem>>.broadcast();

  @override
  Future<bool> appendAll(List<InventoryItem> items) =>
      replaceItems([...this.items, ...items]);

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    await hold?.future;
    if (!saves) return false;
    this.items = List.of(items);
    _changes.add(List.of(items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield List.of(items);
    yield* _changes.stream;
  }
}
