import 'dart:async';

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
    Map<String, Map<String, String>>? initialResolvedBarcodesByUser,
  }) : _documentsByUser =
           initialDocumentsByUser ??
           <String, List<InventoryFridgeItemDocument>>{},
       _resolvedBarcodesByUser =
           initialResolvedBarcodesByUser ?? <String, Map<String, String>>{};

  final Map<String, List<InventoryFridgeItemDocument>> _documentsByUser;
  final Map<String, Map<String, String>> _resolvedBarcodesByUser;
  final Map<String, StreamController<List<InventoryFridgeItemDocument>>>
  _controllersByUser =
      <String, StreamController<List<InventoryFridgeItemDocument>>>{};

  bool replaceAllShouldFail = false;
  bool upsertAllShouldFail = false;
  Duration upsertDelay = Duration.zero;

  int _activeUpserts = 0;
  int maxConcurrentUpserts = 0;

  @override
  Future<List<InventoryFridgeItemDocument>> readAll({
    required String userId,
  }) async {
    return _copyDocuments(userId);
  }

  @override
  Stream<List<InventoryFridgeItemDocument>> watchAll({
    required String userId,
  }) async* {
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

      final mergedById = <String, InventoryFridgeItemDocument>{
        for (final document in _copyDocuments(userId)) document.id: document,
      };
      for (final entry in documentsById.entries) {
        mergedById[entry.key] = InventoryFridgeItemDocument(
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

  @override
  Future<Map<String, String>> readResolvedBarcodes({
    required String userId,
    required Iterable<String> fingerprints,
  }) async {
    final resolvedByFingerprint = _resolvedBarcodesByUser[userId];
    if (resolvedByFingerprint == null || resolvedByFingerprint.isEmpty) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    for (final fingerprint in fingerprints) {
      final barcode = resolvedByFingerprint[fingerprint];
      if (barcode == null || barcode.trim().isEmpty) {
        continue;
      }
      result[fingerprint] = barcode.trim();
    }
    return result;
  }

  Future<void> dispose() async {
    for (final controller in _controllersByUser.values) {
      await controller.close();
    }
    _controllersByUser.clear();
  }

  List<InventoryFridgeItemDocument> _copyDocuments(String userId) {
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

  List<InventoryFridgeItemDocument> _documentsFromMap(
    Map<String, Map<String, dynamic>> documentsById,
  ) {
    return documentsById.entries
        .map(
          (entry) => InventoryFridgeItemDocument(
            id: entry.key,
            data: Map<String, dynamic>.from(entry.value),
          ),
        )
        .toList(growable: false);
  }

  StreamController<List<InventoryFridgeItemDocument>> _controllerFor(
    String userId,
  ) {
    return _controllersByUser.putIfAbsent(
      userId,
      () => StreamController<List<InventoryFridgeItemDocument>>.broadcast(),
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
      final store = _FakeInventoryFridgeItemStore();
      addTearDown(store.dispose);
      final repository = FirestoreFridgeItemRepository(
        session: _FakeInventoryUserSession(currentUserId: null),
        store: store,
      );

      final items = await repository.readAll();

      expect(items, isEmpty);
    },
  );

  test(
    'firestore repo watchAll emits empty when user is not signed in',
    () async {
      final store = _FakeInventoryFridgeItemStore();
      addTearDown(store.dispose);
      final repository = FirestoreFridgeItemRepository(
        session: _FakeInventoryUserSession(currentUserId: ''),
        store: store,
      );

      final items = await repository.watchAll().first;

      expect(items, isEmpty);
    },
  );

  test('firestore repo saveAll fails when user is not signed in', () async {
    final store = _FakeInventoryFridgeItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: ''),
      store: store,
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
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, hasLength(1));
    expect(items.single.id, 'doc-a');
  });

  test('firestore repo watchAll emits updates after remote writes', () async {
    final store = _FakeInventoryFridgeItemStore(
      initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
        'user-1': <InventoryFridgeItemDocument>[
          InventoryFridgeItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final emitted = <List<FridgeItem>>[];
    final subscription = repository.watchAll().listen(emitted.add);
    addTearDown(() {
      unawaited(subscription.cancel());
    });

    await Future<void>.delayed(const Duration(milliseconds: 1));
    await store.upsertAll(
      userId: 'user-1',
      documentsById: <String, Map<String, dynamic>>{'b': _item('b').toJson()},
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(emitted.length, greaterThanOrEqualTo(2));
    expect(emitted.first.map((item) => item.id), contains('a'));
    expect(
      emitted.last.map((item) => item.id),
      containsAll(<String>['a', 'b']),
    );
  });

  test('firestore repo appendAll upserts by id and appends new item', () async {
    final store = _FakeInventoryFridgeItemStore(
      initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
        'user-1': <InventoryFridgeItemDocument>[
          InventoryFridgeItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
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

  test('firestore repo serializes concurrent appendAll writes', () async {
    final store = _FakeInventoryFridgeItemStore();
    store.upsertDelay = const Duration(milliseconds: 25);
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final first = repository.appendAll(<FridgeItem>[_item('a')]);
    final second = repository.appendAll(<FridgeItem>[_item('b')]);
    final saved = await Future.wait<bool>(<Future<bool>>[first, second]);

    expect(saved, everyElement(isTrue));
    expect(store.maxConcurrentUpserts, 1);
    final items = await repository.readAll();
    expect(items.map((item) => item.id), containsAll(<String>['a', 'b']));
  });

  test('firestore repo appendAll returns false when upsert fails', () async {
    final store = _FakeInventoryFridgeItemStore();
    store.upsertAllShouldFail = true;
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.appendAll(<FridgeItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('firestore repo saveAll returns false when replace fails', () async {
    final store = _FakeInventoryFridgeItemStore();
    store.replaceAllShouldFail = true;
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.saveAll(<FridgeItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('firestore repo derives food fingerprint when missing', () async {
    final sourceItem = _item(
      'a',
    ).copyWith(name: 'Organic Milk', brand: 'Acme', foodFingerprint: null);
    final store = _FakeInventoryFridgeItemStore(
      initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
        'user-1': <InventoryFridgeItemDocument>[
          InventoryFridgeItemDocument(id: 'a', data: sourceItem.toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreFridgeItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, hasLength(1));
    expect(items.single.foodFingerprint, 'organic_milk__acme');
  });

  test(
    'firestore repo hydrates resolved barcode from request status',
    () async {
      final sourceItem = _item('a').copyWith(
        foodFingerprint: 'putenherzen__netto',
        barcodeLookupRequestedAt: DateTime.parse('2026-03-03T10:00:00Z'),
      );
      final store = _FakeInventoryFridgeItemStore(
        initialDocumentsByUser: <String, List<InventoryFridgeItemDocument>>{
          'user-1': <InventoryFridgeItemDocument>[
            InventoryFridgeItemDocument(id: 'a', data: sourceItem.toJson()),
          ],
        },
        initialResolvedBarcodesByUser: <String, Map<String, String>>{
          'user-1': <String, String>{'putenherzen__netto': '4316268659758'},
        },
      );
      addTearDown(store.dispose);
      final repository = FirestoreFridgeItemRepository(
        session: _FakeInventoryUserSession(currentUserId: 'user-1'),
        store: store,
      );

      final items = await repository.readAll();

      expect(items, hasLength(1));
      expect(items.single.normalizedBarcode, '4316268659758');
      expect(items.single.barcodeStatus, InventoryBarcodeStatus.resolved);
    },
  );
}
