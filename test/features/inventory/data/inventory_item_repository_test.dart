import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  _FakeInventoryUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeInventoryItemStore
    implements InventoryItemStore, InventoryItemRecentManualStore {
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
  Exception? watchAllError;
  Duration upsertDelay = Duration.zero;
  int _activeUpserts = 0;
  int maxConcurrentUpserts = 0;

  @override
  bool get supportsLimitedRecentManualQuery => true;

  @override
  Future<List<InventoryItemDocument>> readAll({required String userId}) async {
    return _copyDocuments(userId);
  }

  @override
  Future<List<InventoryItemDocument>> readRecentManual({
    required String userId,
    required int limit,
  }) async {
    if (limit <= 0) {
      return const <InventoryItemDocument>[];
    }

    final documents =
        _copyDocuments(userId)
            .where(
              (document) =>
                  document.data['origin'] == InventoryItemOrigin.manualAdd.name,
            )
            .where((document) => document.data['is_deposit'] != true)
            .where((document) => document.data['is_discount'] != true)
            .toList(growable: false)
          ..sort(_compareEntryDateDescending);
    return documents.take(limit).toList(growable: false);
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
      StreamController<List<InventoryItemDocument>>.broadcast,
    );
  }

  void _emit(String userId) {
    final controller = _controllersByUser[userId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(_copyDocuments(userId));
  }

  int _compareEntryDateDescending(
    InventoryItemDocument left,
    InventoryItemDocument right,
  ) {
    return _entryDate(right).compareTo(_entryDate(left));
  }

  DateTime _entryDate(InventoryItemDocument document) {
    final raw = document.data['entry_date'];
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

InventoryItem _item(
  String id, {
  DateTime? entryDate,
  InventoryItemOrigin origin = InventoryItemOrigin.standard,
  bool isDeposit = false,
  bool isDiscount = false,
}) {
  return InventoryItem.create(
    id: id,
    name: 'Milk',
    entryDate: entryDate ?? DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
    origin: origin,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

void main() {
  test('readAll returns empty list when user is signed out', () async {
    final store = _FakeInventoryItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(),
      sessionShutdownSignal: SessionShutdownSignal(),
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
        sessionShutdownSignal: SessionShutdownSignal(),
        store: store,
      );

      final items = await repository.readAll();

      expect(items.single.id, 'doc-a');
    },
  );

  test(
    'readRecentManualItems returns empty list when user is signed out',
    () async {
      final store = _FakeInventoryItemStore();
      addTearDown(store.dispose);
      final repository = FirestoreInventoryItemRepository(
        session: _FakeInventoryUserSession(),
        sessionShutdownSignal: SessionShutdownSignal(),
        store: store,
      );

      final items = await repository.readRecentManualItems(limit: 6);

      expect(items, isEmpty);
    },
  );

  test('readRecentManualItems reads filtered newest limited items', () async {
    final store = _FakeInventoryItemStore(
      initialDocumentsByUser: <String, List<InventoryItemDocument>>{
        'user-1': <InventoryItemDocument>[
          InventoryItemDocument(
            id: 'standard',
            data: _item(
              'standard',
              entryDate: DateTime.utc(2026, 1, 5),
            ).toJson(),
          ),
          InventoryItemDocument(
            id: 'deposit',
            data: _item(
              'deposit',
              entryDate: DateTime.utc(2026, 1, 6),
              origin: InventoryItemOrigin.manualAdd,
              isDeposit: true,
            ).toJson(),
          ),
          InventoryItemDocument(
            id: 'manual-old',
            data: _item(
              'manual-old',
              entryDate: DateTime.utc(2026, 1, 2),
              origin: InventoryItemOrigin.manualAdd,
            ).toJson(),
          ),
          InventoryItemDocument(
            id: 'manual-new',
            data: _item(
              'manual-new',
              entryDate: DateTime.utc(2026, 1, 7),
              origin: InventoryItemOrigin.manualAdd,
            ).toJson(),
          ),
          InventoryItemDocument(
            id: 'manual-middle',
            data: _item(
              'manual-middle',
              entryDate: DateTime.utc(2026, 1, 4),
              origin: InventoryItemOrigin.manualAdd,
            ).toJson(),
          ),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    final items = await repository.readRecentManualItems(limit: 2);

    expect(items.map((item) => item.id), <String>[
      'manual-new',
      'manual-middle',
    ]);
  });

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
      sessionShutdownSignal: SessionShutdownSignal(),
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
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    final items = await repository.readAll();

    expect(items.single.origin, InventoryItemOrigin.manualAdd);
  });

  test('readAll preserves ocr name from stored documents', () async {
    final ocrItem = _item('ocr-1').copyWith(ocrName: 'MILCH 3,5%');
    final store = _FakeInventoryItemStore(
      initialDocumentsByUser: <String, List<InventoryItemDocument>>{
        'user-1': <InventoryItemDocument>[
          InventoryItemDocument(id: 'ocr-1', data: ocrItem.toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    final items = await repository.readAll();

    expect(items.single.ocrName, 'MILCH 3,5%');
  });

  test('appendAll serializes concurrent writes', () async {
    final store = _FakeInventoryItemStore()
      ..upsertDelay = const Duration(milliseconds: 25);
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
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
      sessionShutdownSignal: SessionShutdownSignal(),
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
      sessionShutdownSignal: SessionShutdownSignal(),
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

  test('watchAll returns empty list during session shutdown', () async {
    final sessionShutdownSignal = SessionShutdownSignal()..begin();
    final store = _FakeInventoryItemStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestoreInventoryItemRepository(
      session: _FakeInventoryUserSession(currentUserId: 'user-1'),
      sessionShutdownSignal: sessionShutdownSignal,
      store: store,
    );

    expect(repository.watchAll().first, completion(const <InventoryItem>[]));
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
      sessionShutdownSignal: SessionShutdownSignal(),
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
        sessionShutdownSignal: SessionShutdownSignal(),
        store: store,
      );

      expect(repository.watchAll().first, throwsA(isA<SocketException>()));
    },
  );
}
