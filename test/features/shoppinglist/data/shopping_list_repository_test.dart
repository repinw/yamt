import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

class _HookedFakeFirebaseFirestore extends FakeFirebaseFirestore {
  new({this.transactionDelay = Duration.zero, this.transactionError});

  final Duration transactionDelay;
  final FirebaseException? transactionError;
  int _activeTransactions = 0;
  int maxConcurrentTransactions = 0;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (transactionError case final error?) {
      throw error;
    }
    _activeTransactions += 1;
    maxConcurrentTransactions = max(
      maxConcurrentTransactions,
      _activeTransactions,
    );
    try {
      await Future<void>.delayed(transactionDelay);
      return await super.runTransaction(
        transactionHandler,
        timeout: timeout,
        maxAttempts: maxAttempts,
      );
    } finally {
      _activeTransactions -= 1;
    }
  }
}

ShoppingListItem _item(String id, {String name = 'Milk'}) {
  return ShoppingListItem(
    id: id,
    name: name,
    normalizedName: name.toLowerCase(),
    normalizedBrand: '',
    quantity: 1,
    estimatedUnitPrice: 0,
  );
}

Future<void> _waitForEmissions(List<Object> emitted, int count) {
  return Future.doWhile(() async {
    if (emitted.length >= count) {
      return false;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 5));
}

void main() {
  late HouseholdCipher householdCipher;

  setUp(() async {
    final key = await PayloadCipher.newDataKey();
    householdCipher = (
      householdId: 'household-1',
      key: key,
      cipher: PayloadCipher(key),
    );
  });

  CollectionReference<Map<String, dynamic>> collectionOf(
    FirebaseFirestore firestore,
  ) {
    return firestore
        .collection('households')
        .doc('household-1')
        .collection('shopping_list_items');
  }

  Future<void> put(
    FirebaseFirestore firestore,
    String id,
    Map<String, dynamic> data,
  ) async {
    final collection = collectionOf(firestore);
    final sealed = SealedCollection(collection, cipher: householdCipher.cipher);
    await collection.doc(id).set(await sealed.seal(id, data));
  }

  ShoppingListRepository repository(
    FirebaseFirestore? firestore, {
    bool withCipher = true,
  }) {
    return ShoppingListRepository(
      firestore: firestore,
      householdCipher: withCipher ? householdCipher : null,
    );
  }

  test('readAll returns no items without a household cipher', () async {
    final items = await repository(
      FakeFirebaseFirestore(),
      withCipher: false,
    ).readAll();

    expect(items, isEmpty);
  });

  test('watchAll emits no items without Firestore', () async {
    final items = await repository(null).watchAll().first;

    expect(items, isEmpty);
  });

  test('saveAll fails without a household cipher', () async {
    final saved = await repository(
      FakeFirebaseFirestore(),
      withCipher: false,
    ).saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });

  test('readAll skips a corrupted document', () async {
    final firestore = FakeFirebaseFirestore();
    await put(firestore, 'a', _item('a').toJson()..remove('id'));
    await put(firestore, 'b', _item('b').toJson());

    final items = await repository(firestore).readAll();

    expect(items.map((item) => item.id), <String>['b']);
  });

  test('watchAll emits updates after remote writes', () async {
    final firestore = FakeFirebaseFirestore();
    await put(firestore, 'a', _item('a').toJson());
    final emitted = <List<ShoppingListItem>>[];
    final subscription = repository(firestore).watchAll().listen(emitted.add);
    addTearDown(() => unawaited(subscription.cancel()));

    await _waitForEmissions(emitted, 1);
    await put(firestore, 'b', _item('b').toJson());
    await _waitForEmissions(emitted, 2);

    expect(emitted.first.map((item) => item.id), <String>['a']);
    expect(
      emitted.last.map((item) => item.id),
      unorderedEquals(<String>['a', 'b']),
    );
  });

  test('saveAll replaces the stored items and removes stale ones', () async {
    final firestore = FakeFirebaseFirestore();
    await put(firestore, 'a', _item('a').toJson());
    await put(firestore, 'b', _item('b').toJson());
    final target = repository(firestore);

    final saved = await target.saveAll(<ShoppingListItem>[
      _item('b', name: 'Bread'),
      _item('c'),
    ]);

    final documents = (await collectionOf(firestore).get()).docs;
    expect(saved, isTrue);
    expect(
      documents.map((document) => document.id),
      unorderedEquals(<String>['b', 'c']),
    );
    expect(
      documents.map((document) => document.data().containsKey('name')),
      everyElement(isFalse),
    );
    expect(
      (await target.readAll()).map((item) => (item.id, item.name)),
      unorderedEquals(<(String, String)>[('b', 'Bread'), ('c', 'Milk')]),
    );
  });

  test('saveAll writes more than 500 items', () async {
    final firestore = FakeFirebaseFirestore();
    final items = <ShoppingListItem>[
      for (var index = 0; index < 501; index++) _item('item-$index'),
    ];

    final saved = await repository(firestore).saveAll(items);

    expect(saved, isTrue);
    expect((await collectionOf(firestore).get()).docs, hasLength(501));
  });

  test('saveAll runs writes one after another', () async {
    final firestore = _HookedFakeFirebaseFirestore(
      transactionDelay: const Duration(milliseconds: 25),
    );
    final target = repository(firestore);

    final saved = await Future.wait<bool>(<Future<bool>>[
      target.saveAll(<ShoppingListItem>[_item('a')]),
      target.saveAll(<ShoppingListItem>[_item('b')]),
    ]);

    expect(saved, everyElement(isTrue));
    expect(firestore.maxConcurrentTransactions, 1);
    expect((await target.readAll()).single.id, 'b');
  });

  test('saveAll fails when the Firestore write fails', () async {
    final firestore = _HookedFakeFirebaseFirestore(
      transactionError: FirebaseException(
        plugin: 'cloud_firestore',
        code: 'aborted',
        message: 'transaction failed',
      ),
    );

    final saved = await repository(firestore)
        .saveAll(<ShoppingListItem>[_item('a')]);

    expect(saved, isFalse);
  });
}
