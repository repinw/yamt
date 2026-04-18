import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/'
    'firestore_shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_user_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

class _FakeShoppingListUserSession implements ShoppingListUserSession {
  _FakeShoppingListUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakeShoppingListItemStore implements ShoppingListItemStore {
  _FakeShoppingListItemStore({
    Map<String, List<ShoppingListItemDocument>>? initialDocumentsByUser,
  }) : _documentsByUser =
           initialDocumentsByUser ?? <String, List<ShoppingListItemDocument>>{};

  final Map<String, List<ShoppingListItemDocument>> _documentsByUser;
  final Map<String, StreamController<List<ShoppingListItemDocument>>>
  _controllersByUser =
      <String, StreamController<List<ShoppingListItemDocument>>>{};

  bool replaceAllShouldFail = false;
  Duration replaceDelay = Duration.zero;

  int _activeReplaces = 0;
  int maxConcurrentReplaces = 0;

  @override
  Future<List<ShoppingListItemDocument>> readAll({required String userId}) {
    return Future<List<ShoppingListItemDocument>>.value(_copyDocuments(userId));
  }

  @override
  Stream<List<ShoppingListItemDocument>> watchAll({required String userId}) {
    return Stream<List<ShoppingListItemDocument>>.multi((controller) {
      controller.add(_copyDocuments(userId));
      final sub = _controllerFor(userId).stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        unawaited(sub.cancel());
      };
    });
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    if (replaceAllShouldFail) {
      return false;
    }

    _activeReplaces++;
    if (_activeReplaces > maxConcurrentReplaces) {
      maxConcurrentReplaces = _activeReplaces;
    }

    try {
      if (replaceDelay > Duration.zero) {
        await Future<void>.delayed(replaceDelay);
      }
      _documentsByUser[userId] = documentsById.entries
          .map(
            (entry) => ShoppingListItemDocument(
              id: entry.key,
              data: Map<String, dynamic>.from(entry.value),
            ),
          )
          .toList(growable: false);
      _emit(userId);
      return true;
    } finally {
      _activeReplaces--;
    }
  }

  void emitDocuments(String userId, List<ShoppingListItemDocument> documents) {
    _documentsByUser[userId] = documents
        .map(
          (doc) => ShoppingListItemDocument(
            id: doc.id,
            data: Map<String, dynamic>.from(doc.data),
          ),
        )
        .toList(growable: false);
    _emit(userId);
  }

  void emitError(String userId, Object error) {
    final controller = _controllersByUser[userId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.addError(error);
  }

  Future<void> dispose() async {
    for (final controller in _controllersByUser.values) {
      await controller.close();
    }
    _controllersByUser.clear();
  }

  List<ShoppingListItemDocument> _copyDocuments(String userId) {
    final docs = _documentsByUser[userId] ?? const <ShoppingListItemDocument>[];
    return docs
        .map(
          (doc) => ShoppingListItemDocument(
            id: doc.id,
            data: Map<String, dynamic>.from(doc.data),
          ),
        )
        .toList(growable: false);
  }

  StreamController<List<ShoppingListItemDocument>> _controllerFor(
    String userId,
  ) {
    return _controllersByUser.putIfAbsent(
      userId,
      StreamController<List<ShoppingListItemDocument>>.broadcast,
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

ShoppingListItem _item(
  String id, {
  String name = 'Milk',
  String? brand,
  int quantity = 1,
  double estimatedUnitPrice = 0,
}) {
  return ShoppingListItem(
    id: id,
    name: name,
    brand: brand,
    normalizedName: name.trim().toLowerCase(),
    normalizedBrand: (brand ?? '').trim().toLowerCase(),
    quantity: quantity,
    estimatedUnitPrice: estimatedUnitPrice,
  );
}

void main() {
  test(
    'repository readAll returns empty list when user is not signed in',
    () async {
      final store = _FakeShoppingListItemStore();
      addTearDown(store.dispose);
      final repository = FirestoreShoppingListRepository(
        session: _FakeShoppingListUserSession(),
        store: store,
      );

      final items = await repository.readAll();

      expect(items, isEmpty);
    },
  );

  test(
    'repository watchAll emits empty list when user is not signed in',
    () async {
      final store = _FakeShoppingListItemStore();
      addTearDown(store.dispose);
      final repository = FirestoreShoppingListRepository(
        session: _FakeShoppingListUserSession(currentUserId: ''),
        store: store,
      );

      final items = await repository.watchAll().first;

      expect(items, isEmpty);
    },
  );

  test('repository saveAll fails when user is not signed in', () async {
    final store = _FakeShoppingListItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(currentUserId: ''),
      store: store,
    );

    final saved = await repository.saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('repository skips corrupted document payload', () async {
    final payload = Map<String, dynamic>.from(_item('doc-a').toJson())
      ..remove('id');
    final store = _FakeShoppingListItemStore(
      initialDocumentsByUser: <String, List<ShoppingListItemDocument>>{
        'user-1': <ShoppingListItemDocument>[
          ShoppingListItemDocument(id: 'doc-a', data: payload),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test('repository watchAll emits updates after remote writes', () async {
    final store = _FakeShoppingListItemStore(
      initialDocumentsByUser: <String, List<ShoppingListItemDocument>>{
        'user-1': <ShoppingListItemDocument>[
          ShoppingListItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final emitted = <List<ShoppingListItem>>[];
    final sub = repository.watchAll().listen(emitted.add);
    addTearDown(() {
      unawaited(sub.cancel());
    });

    await Future<void>.delayed(const Duration(milliseconds: 1));
    store.emitDocuments('user-1', <ShoppingListItemDocument>[
      ShoppingListItemDocument(id: 'a', data: _item('a').toJson()),
      ShoppingListItemDocument(id: 'b', data: _item('b').toJson()),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(emitted.length, greaterThanOrEqualTo(2));
    expect(emitted.first.map((item) => item.id), contains('a'));
    expect(
      emitted.last.map((item) => item.id),
      containsAll(<String>['a', 'b']),
    );
  });

  test(
    'repository watchAll emits empty list when realtime watch is denied',
    () async {
      final store = _FakeShoppingListItemStore(
        initialDocumentsByUser: <String, List<ShoppingListItemDocument>>{
          'user-1': <ShoppingListItemDocument>[
            ShoppingListItemDocument(id: 'a', data: _item('a').toJson()),
          ],
        },
      );
      addTearDown(store.dispose);
      final repository = FirestoreShoppingListRepository(
        session: _FakeShoppingListUserSession(currentUserId: 'user-1'),
        store: store,
      );

      final emitted = <List<ShoppingListItem>>[];
      final errors = <Object>[];
      final sub = repository.watchAll().listen(
        emitted.add,
        onError: errors.add,
      );
      addTearDown(() {
        unawaited(sub.cancel());
      });

      await Future<void>.delayed(const Duration(milliseconds: 1));
      store.emitError(
        'user-1',
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'The caller does not have permission.',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(errors, isEmpty);
      expect(emitted, isNotEmpty);
      expect(emitted.last, isEmpty);
    },
  );

  test('repository serializes concurrent saveAll writes', () async {
    final store = _FakeShoppingListItemStore()
      ..replaceDelay = const Duration(milliseconds: 25);
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final first = repository.saveAll(<ShoppingListItem>[_item('a')]);
    final second = repository.saveAll(<ShoppingListItem>[_item('b')]);
    final saved = await Future.wait<bool>(<Future<bool>>[first, second]);

    expect(saved, everyElement(isTrue));
    expect(store.maxConcurrentReplaces, 1);
    final items = await repository.readAll();
    expect(items.single.id, 'b');
  });

  test('repository saveAll returns false when store replace fails', () async {
    final store = _FakeShoppingListItemStore()..replaceAllShouldFail = true;
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(currentUserId: 'user-1'),
      store: store,
    );

    final saved = await repository.saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });
}
