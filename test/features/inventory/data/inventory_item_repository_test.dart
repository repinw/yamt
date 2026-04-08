import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  _FakeInventoryUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeInventoryItemStore implements InventoryItemStore {
  _FakeInventoryItemStore({
    Map<String, List<InventoryItemDocument>>? initialDocumentsByUser,
  }) : _documentsByUser =
           initialDocumentsByUser ?? <String, List<InventoryItemDocument>>{};

  final Map<String, List<InventoryItemDocument>> _documentsByUser;
  final Map<String, StreamController<List<InventoryItemDocument>>>
  _controllersByUser =
      <String, StreamController<List<InventoryItemDocument>>>{};

  bool replaceAllShouldFail = false;
  bool upsertAllShouldFail = false;
  Object? watchAllError;
  Duration upsertDelay = Duration.zero;
  int _activeUpserts = 0;
  int maxConcurrentUpserts = 0;

  @override
  Future<List<InventoryItemDocument>> readAll({required String userId}) async {
    return _copyDocuments(userId);
  }

  @override
  Stream<List<InventoryItemDocument>> watchAll({
    required String userId,
  }) async* {
    final error = watchAllError;
    if (error != null) {
      throw error;
    }
    yield _copyDocuments(userId);
    yield* _controllerFor(userId).stream;
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    if (replaceAllShouldFail) {
      return false;
    }
    _documentsByUser[userId] = _documentsFromMap(documentsById);
    _emit(userId);
    return true;
  }

  @override
  Future<bool> upsertAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    if (upsertAllShouldFail) {
      return false;
    }

    _activeUpserts++;
    if (_activeUpserts > maxConcurrentUpserts) {
      maxConcurrentUpserts = _activeUpserts;
    }

    try {
      if (upsertDelay > Duration.zero) {
        await Future<void>.delayed(upsertDelay);
      }
      final mergedById = <String, InventoryItemDocument>{
        for (final document in _copyDocuments(userId)) document.id: document,
      };
      for (final entry in documentsById.entries) {
        mergedById[entry.key] = InventoryItemDocument(
          id: entry.key,
          data: Map<String, dynamic>.from(entry.value),
        );
      }
      _documentsByUser[userId] = mergedById.values.toList(growable: false);
      _emit(userId);
      return true;
    } finally {
      _activeUpserts--;
    }
  }

  Future<void> dispose() async {
    for (final controller in _controllersByUser.values) {
      await controller.close();
    }
    _controllersByUser.clear();
  }

  List<InventoryItemDocument> _copyDocuments(String userId) {
    final documents =
        _documentsByUser[userId] ?? const <InventoryItemDocument>[];
    return documents
        .map(
          (document) => InventoryItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data),
          ),
        )
        .toList(growable: false);
  }

  List<InventoryItemDocument> _documentsFromMap(
    Map<String, Map<String, dynamic>> documentsById,
  ) {
    return documentsById.entries
        .map(
          (entry) => InventoryItemDocument(
            id: entry.key,
            data: Map<String, dynamic>.from(entry.value),
          ),
        )
        .toList(growable: false);
  }

  StreamController<List<InventoryItemDocument>> _controllerFor(String userId) {
    return _controllersByUser.putIfAbsent(
      userId,
      () => StreamController<List<InventoryItemDocument>>.broadcast(),
    );
  }

  void _emit(String userId) {
    final controller = _controllersByUser[userId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(_copyDocuments(userId));
  }
}

InventoryItem _item(String id) {
  return InventoryItem.create(
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
  test('readAll returns empty list when user is signed out', () async {
    final store = _FakeInventoryItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: null),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test(
    'readAll falls back to document id when payload id is missing',
    () async {
      final itemJson = Map<String, dynamic>.from(_item('doc-a').toJson())
        ..remove('id');
      final store = _FakeInventoryItemStore(
        initialDocumentsByUser: <String, List<InventoryItemDocument>>{
          'user-1': <InventoryItemDocument>[
            InventoryItemDocument(id: 'doc-a', data: itemJson),
          ],
        },
      );
      addTearDown(store.dispose);
      final repository = FirestoreInventoryItemRepository(
        session: _FakeInventoryUserSession(currentUserId: 'user-1'),
        store: store,
      );

      final items = await repository.readAll();

      expect(items.single.id, 'doc-a');
    },
  );

  test('appendAll upserts by id and appends new items', () async {
    final store = _FakeInventoryItemStore(
      initialDocumentsByUser: <String, List<InventoryItemDocument>>{
        'user-1': <InventoryItemDocument>[
          InventoryItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.appendAll(<InventoryItem>[
      _item('a').copyWith(quantity: 4),
      _item('b'),
    ]);
    final items = await repository.readAll();

    expect(saved, isTrue);
    expect(items, hasLength(2));
    expect(items.firstWhere((item) => item.id == 'a').quantity, 4);
    expect(items.map((item) => item.id), containsAll(<String>['a', 'b']));
  });

  test('readAll preserves manual add origin from stored documents', () async {
    final manualItem = _item(
      'manual-1',
    ).copyWith(origin: InventoryItemOrigin.manualAdd);
    final store = _FakeInventoryItemStore(
      initialDocumentsByUser: <String, List<InventoryItemDocument>>{
        'user-1': <InventoryItemDocument>[
          InventoryItemDocument(id: 'manual-1', data: manualItem.toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items.single.origin, InventoryItemOrigin.manualAdd);
  });

  test('appendAll serializes concurrent writes', () async {
    final store = _FakeInventoryItemStore()
      ..upsertDelay = const Duration(milliseconds: 25);
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final first = repository.appendAll(<InventoryItem>[_item('a')]);
    final second = repository.appendAll(<InventoryItem>[_item('b')]);
    final result = await Future.wait<bool>(<Future<bool>>[first, second]);

    expect(result, everyElement(isTrue));
    expect(store.maxConcurrentUpserts, 1);
  });

  test('saveAll returns false when replace fails', () async {
    final store = _FakeInventoryItemStore()..replaceAllShouldFail = true;
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.saveAll(<InventoryItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakeInventoryItemStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    expect(
      repository.watchAll().first,
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('watchAll rethrows non-permission firestore errors', () async {
    final store = _FakeInventoryItemStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    expect(
      repository.watchAll().first,
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'unavailable',
        ),
      ),
    );
  });

  test(
    'watchAll rethrows generic stream errors like socket exceptions',
    () async {
      final store = _FakeInventoryItemStore()
        ..watchAllError = const SocketException('network down');
      addTearDown(store.dispose);
      final repository = FirestoreInventoryItemRepository(
        session: _FakeInventoryUserSession(currentUserId: 'user-1'),
        store: store,
      );

      expect(repository.watchAll().first, throwsA(isA<SocketException>()));
    },
  );
}
