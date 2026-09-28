import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/'
    'firestore_shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_user_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

class _FakeShoppingListUserSession implements ShoppingListUserSession {
  new({this.householdId});

  @override
  final String? householdId;
}

class _FakeShoppingListItemStore implements ShoppingListItemStore {
  new({
    Map<String, List<ShoppingListItemDocument>>? initialDocumentsByHousehold,
  }) : _documentsByHousehold =
           initialDocumentsByHousehold ??
           <String, List<ShoppingListItemDocument>>{};

  final Map<String, List<ShoppingListItemDocument>> _documentsByHousehold;
  final Map<String, StreamController<List<ShoppingListItemDocument>>>
  _controllersByHousehold =
      <String, StreamController<List<ShoppingListItemDocument>>>{};

  bool replaceAllShouldFail = false;
  Duration replaceDelay = Duration.zero;

  int _activeReplaces = 0;
  int maxConcurrentReplaces = 0;

  @override
  Future<List<ShoppingListItemDocument>> readAll({
    required String householdId,
  }) {
    return Future<List<ShoppingListItemDocument>>.value(
      _copyDocuments(householdId),
    );
  }

  @override
  Stream<List<ShoppingListItemDocument>> watchAll({
    required String householdId,
  }) {
    return Stream<List<ShoppingListItemDocument>>.multi((controller) {
      controller.add(_copyDocuments(householdId));
      final sub = _controllerFor(householdId).stream.listen(
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
    required String householdId,
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
      _documentsByHousehold[householdId] = documentsById.entries
          .map(
            (entry) => ShoppingListItemDocument(
              id: entry.key,
              data: Map<String, dynamic>.from(entry.value),
            ),
          )
          .toList(growable: false);
      _emit(householdId);
      return true;
    } finally {
      _activeReplaces--;
    }
  }

  void emitDocuments(
    String householdId,
    List<ShoppingListItemDocument> documents,
  ) {
    _documentsByHousehold[householdId] = documents
        .map(
          (doc) => ShoppingListItemDocument(
            id: doc.id,
            data: Map<String, dynamic>.from(doc.data),
          ),
        )
        .toList(growable: false);
    _emit(householdId);
  }

  void emitError(String householdId, Object error) {
    final controller = _controllersByHousehold[householdId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.addError(error);
  }

  Future<void> dispose() async {
    for (final controller in _controllersByHousehold.values) {
      await controller.close();
    }
    _controllersByHousehold.clear();
  }

  List<ShoppingListItemDocument> _copyDocuments(String householdId) {
    final docs =
        _documentsByHousehold[householdId] ??
        const <ShoppingListItemDocument>[];
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
    String householdId,
  ) {
    return _controllersByHousehold.putIfAbsent(
      householdId,
      StreamController<List<ShoppingListItemDocument>>.broadcast,
    );
  }

  void _emit(String householdId) {
    final controller = _controllersByHousehold[householdId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(_copyDocuments(householdId));
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
  test('repository readAll returns empty list without a household', () async {
    final store = _FakeShoppingListItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test('repository watchAll emits empty list without a household', () async {
    final store = _FakeShoppingListItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(householdId: ''),
      store: store,
    );

    final items = await repository.watchAll().first;

    expect(items, isEmpty);
  });

  test('repository saveAll fails without a household', () async {
    final store = _FakeShoppingListItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(householdId: ''),
      store: store,
    );

    final saved = await repository.saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('repository skips corrupted document payload', () async {
    final payload = Map<String, dynamic>.from(_item('doc-a').toJson())
      ..remove('id');
    final store = _FakeShoppingListItemStore(
      initialDocumentsByHousehold: <String, List<ShoppingListItemDocument>>{
        'household-1': <ShoppingListItemDocument>[
          ShoppingListItemDocument(id: 'doc-a', data: payload),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(householdId: 'household-1'),
      store: store,
    );

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test('repository watchAll emits updates after remote writes', () async {
    final store = _FakeShoppingListItemStore(
      initialDocumentsByHousehold: <String, List<ShoppingListItemDocument>>{
        'household-1': <ShoppingListItemDocument>[
          ShoppingListItemDocument(id: 'a', data: _item('a').toJson()),
        ],
      },
    );
    addTearDown(store.dispose);
    final repository = FirestoreShoppingListRepository(
      session: _FakeShoppingListUserSession(householdId: 'household-1'),
      store: store,
    );

    final emitted = <List<ShoppingListItem>>[];
    final sub = repository.watchAll().listen(emitted.add);
    addTearDown(() {
      unawaited(sub.cancel());
    });

    await Future<void>.delayed(const Duration(milliseconds: 1));
    store.emitDocuments('household-1', <ShoppingListItemDocument>[
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
        initialDocumentsByHousehold: <String, List<ShoppingListItemDocument>>{
          'household-1': <ShoppingListItemDocument>[
            ShoppingListItemDocument(id: 'a', data: _item('a').toJson()),
          ],
        },
      );
      addTearDown(store.dispose);
      final repository = FirestoreShoppingListRepository(
        session: _FakeShoppingListUserSession(householdId: 'household-1'),
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
        'household-1',
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
      session: _FakeShoppingListUserSession(householdId: 'household-1'),
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
      session: _FakeShoppingListUserSession(householdId: 'household-1'),
      store: store,
    );

    final saved = await repository.saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });
}
