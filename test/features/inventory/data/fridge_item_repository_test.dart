import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  _FakeInventoryUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeInventoryFridgeItemStore implements InventoryFridgeItemStore {
  _FakeInventoryFridgeItemStore({
    Map<String, List<InventoryFridgeItemDocument>>? initialDocumentsByUser,
  }) : _documentsByUser =
           initialDocumentsByUser ??
           <String, List<InventoryFridgeItemDocument>>{};

  final Map<String, List<InventoryFridgeItemDocument>> _documentsByUser;
  bool replaceAllShouldFail = false;

  @override
  Future<List<InventoryFridgeItemDocument>> readAll({
    required String userId,
  }) async {
    final documents =
        _documentsByUser[userId] ?? const <InventoryFridgeItemDocument>[];
    return documents
        .map(
          (document) => InventoryFridgeItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    if (replaceAllShouldFail) {
      return false;
    }

    final documents = documentsById.entries
        .map(
          (entry) => InventoryFridgeItemDocument(
            id: entry.key,
            data: Map<String, dynamic>.from(entry.value),
          ),
        )
        .toList(growable: false);
    _documentsByUser[userId] = documents;
    return true;
  }
}

FridgeItem _item(String id) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

void main() {
  test(
    'firestore repo returns empty list when user is not signed in',
    () async {
      final repository = FirestoreFridgeItemRepository(
        session: _FakeInventoryUserSession(currentUserId: null),
        store: _FakeInventoryFridgeItemStore(),
      );

      final items = await repository.readAll();

      expect(items, isEmpty);
    },
  );

  test('firestore repo saveAll fails when user is not signed in', () async {
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: ''),
      store: _FakeInventoryFridgeItemStore(),
    );

    final saved = await repository.saveAll(<FridgeItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('firestore repo maps missing payload id from document id', () async {
    final itemJson = Map<String, dynamic>.from(_item('doc-a').toJson())
      ..remove('id');
    final store = _FakeInventoryFridgeItemStore(
      initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
        'user-1': <InventoryFridgeItemDocument>[
          InventoryFridgeItemDocument(id: 'doc-a', data: itemJson),
        ],
      },
    );
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, hasLength(1));
    expect(items.single.id, 'doc-a');
  });

  test('firestore repo appendAll merges by id and appends new item', () async {
    final store = _FakeInventoryFridgeItemStore(
      initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
        'user-1': <InventoryFridgeItemDocument>[
          InventoryFridgeItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final appended = await repository.appendAll(<FridgeItem>[
      _item('a').copyWith(quantity: 4),
      _item('b'),
    ]);
    final items = await repository.readAll();
    final itemA = items.firstWhere((item) => item.id == 'a');
    final itemB = items.firstWhere((item) => item.id == 'b');

    expect(appended, isTrue);
    expect(items, hasLength(2));
    expect(itemA.quantity, 4);
    expect(itemB.id, 'b');
  });

  test('firestore repo saveAll returns false when replace fails', () async {
    final store = _FakeInventoryFridgeItemStore();
    store.replaceAllShouldFail = true;
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.saveAll(<FridgeItem>[_item('a')]);

    expect(saved, isFalse);
  });
}
