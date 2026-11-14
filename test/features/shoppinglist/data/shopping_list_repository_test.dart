import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
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

  test('saveAll throws without a household cipher', () async {
    final target = repository(FakeFirebaseFirestore(), withCipher: false);

    await expectLater(
      target.saveAll(<ShoppingListItem>[_item('a')]),
      throwsStateError,
    );
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

  group('documents from before the done flag', () {
    Map<String, dynamic> stored({required int quantity}) => <String, dynamic>{
      'id': 'a',
      'name': 'Milk',
      'brand': null,
      'normalized_name': 'milk',
      'normalized_brand': '',
      'quantity': quantity,
      'estimated_unit_price': 0,
    };

    test('are read in the new shape and marked for a rewrite', () async {
      final firestore = FakeFirebaseFirestore();
      await put(firestore, 'a', stored(quantity: 0));
      final target = repository(firestore);

      final items = await target.readAll();

      expect((items.single.isDone, items.single.quantity), (true, 1));
      expect(target.holdsUnmigratedItems, isTrue);
    });

    test('are stored in the new shape by the next save', () async {
      final firestore = FakeFirebaseFirestore();
      await put(firestore, 'a', stored(quantity: 2));
      final target = repository(firestore);

      await target.saveAll(await target.readAll());
      final items = await target.readAll();

      expect((items.single.isDone, items.single.quantity), (false, 2));
      expect(target.holdsUnmigratedItems, isFalse);
    });
  });

  group('the private list', () {
    late UserDataCipher userCipher;

    setUp(() async {
      userCipher = (
        uid: 'user-1',
        cipher: PayloadCipher(await PayloadCipher.newDataKey()),
      );
    });

    CollectionReference<Map<String, dynamic>> privateOf(
      FirebaseFirestore firestore,
    ) => firestore
        .collection('users')
        .doc('user-1')
        .collection('shopping_list_items');

    ShoppingListRepository both(FirebaseFirestore firestore) =>
        ShoppingListRepository(
          firestore: firestore,
          householdCipher: householdCipher,
          userCipher: userCipher,
        );

    ShoppingListItem private(String id) => ShoppingListItem(
      id: id,
      name: 'Deo',
      normalizedName: 'deo',
      normalizedBrand: '',
      quantity: 1,
      estimatedUnitPrice: 0,
      isPrivate: true,
    );

    test('saveAll stores private items under the user, the rest in the '
        'household', () async {
      final firestore = FakeFirebaseFirestore();
      final target = both(firestore);

      final saved = await target.saveAll([_item('a'), private('p')]);

      expect(saved, isTrue);
      expect((await collectionOf(firestore).get()).docs.map((d) => d.id), [
        'a',
      ]);
      expect((await privateOf(firestore).get()).docs.map((d) => d.id), ['p']);
      expect(
        (await target.readAll()).map((item) => (item.id, item.isPrivate)),
        [('a', false), ('p', true)],
      );
    });

    test('watchAll emits both lists once both arrived', () async {
      final firestore = FakeFirebaseFirestore();
      final target = both(firestore);
      await target.saveAll([_item('a'), private('p')]);

      final items = await target.watchAll().first;

      expect(items.map((item) => (item.id, item.isPrivate)), [
        ('a', false),
        ('p', true),
      ]);
    });

    test('a save without the private items empties the private list', () async {
      final firestore = FakeFirebaseFirestore();
      final target = both(firestore);
      await target.saveAll([_item('a'), private('p')]);

      await target.saveAll([_item('a')]);

      expect((await privateOf(firestore).get()).docs, isEmpty);
    });

    test(
      'a change to the private list leaves the household list alone',
      () async {
        final firestore = FakeFirebaseFirestore();
        final target = both(firestore);
        await target.saveAll([_item('a'), private('p')]);
        // Another member adds to the household list meanwhile.
        await put(firestore, 'x', _item('x').toJson());

        final saved = await target.saveAll([
          _item('a'),
          private('p').copyWith(quantity: 3),
        ]);

        expect(saved, isTrue);
        expect(
          (await collectionOf(firestore).get()).docs.map((d) => d.id),
          unorderedEquals(['a', 'x']),
        );
      },
    );

    test('an unreadable private list counts as empty', () async {
      final firestore = FakeFirebaseFirestore();
      await put(firestore, 'a', _item('a').toJson());
      // Sealed with the household key, which the user key cannot open.
      final sealed = SealedCollection(
        privateOf(firestore),
        cipher: householdCipher.cipher,
      );
      await privateOf(firestore)
          .doc('p')
          .set(await sealed.seal('p', private('p').toJson()));
      final target = both(firestore);

      expect((await target.readAll()).map((item) => item.id), ['a']);
      expect((await target.watchAll().first).map((item) => item.id), ['a']);

      // A private entry would replace what could not be read: refused.
      await expectLater(
        target.saveAll([_item('a'), private('q')]),
        throwsStateError,
      );
      expect((await privateOf(firestore).get()).docs.map((doc) => doc.id), [
        'p',
      ]);
    });

    test('a failed read of the private list keeps it until a read works, '
        'and the household list still saves', () async {
      final firestore = FakeFirebaseFirestore();
      final target = both(firestore);
      await target.saveAll([_item('a'), private('p')]);
      expect(
        (await target.watchAll().first).map((item) => item.id),
        unorderedEquals(['a', 'p']),
      );
      // A document the user key cannot open makes the next read fail.
      final wrongKey = SealedCollection(
        privateOf(firestore),
        cipher: householdCipher.cipher,
      );
      await privateOf(firestore)
          .doc('x')
          .set(await wrongKey.seal('x', private('x').toJson()));
      expect((await target.readAll()).map((item) => item.id), ['a']);

      expect(await target.saveAll([_item('a', name: 'Brot')]), isTrue);
      expect(target.privateUnreadable, isTrue);
      // The page still holds the private entries it watched: unchanged,
      // they do not block a household change.
      expect(
        await target.saveAll([_item('a', name: 'Butter'), private('p')]),
        isTrue,
      );
      await expectLater(
        target.saveAll([_item('a'), private('p').copyWith(quantity: 3)]),
        throwsStateError,
      );
      expect(
        (await privateOf(firestore).get()).docs.map((doc) => doc.id),
        unorderedEquals(['p', 'x']),
      );

      await privateOf(firestore).doc('x').delete();
      await target.readAll();
      expect(target.privateUnreadable, isFalse);
      expect(
        await target.saveAll([_item('a'), private('p').copyWith(quantity: 3)]),
        isTrue,
      );
    });

    test('a read after a failed private watch does not let a save without '
        'the private entries remove them', () async {
      final firestore = FakeFirebaseFirestore();
      await put(firestore, 'a', _item('a').toJson());
      final wrongKey = SealedCollection(
        privateOf(firestore),
        cipher: householdCipher.cipher,
      );
      await privateOf(firestore)
          .doc('x')
          .set(await wrongKey.seal('x', private('x').toJson()));
      final target = both(firestore);
      // The private watch fails, so the stream's list has no private items.
      expect((await target.watchAll().first).map((item) => item.id), ['a']);

      await privateOf(firestore).doc('x').delete();
      final ownKey = SealedCollection(
        privateOf(firestore),
        cipher: userCipher.cipher,
      );
      await privateOf(firestore)
          .doc('p')
          .set(await ownKey.seal('p', private('p').toJson()));
      // Another caller reads both lists fine.
      expect((await target.readAll()).map((item) => item.id), ['a', 'p']);

      // A save from the stream's list leaves the private list alone.
      expect(await target.saveAll([_item('a', name: 'Brot')]), isTrue);
      expect((await privateOf(firestore).get()).docs.map((doc) => doc.id), [
        'p',
      ]);
    });

    test('a failed private read leaves the private list alone at the next '
        'save', () async {
      final firestore = FakeFirebaseFirestore();
      await both(firestore).saveAll([_item('a'), private('p')]);
      final wrongKey = SealedCollection(
        privateOf(firestore),
        cipher: householdCipher.cipher,
      );
      await privateOf(firestore)
          .doc('x')
          .set(await wrongKey.seal('x', private('x').toJson()));
      // No list page is open: only a full read, as a recipe add does.
      final target = both(firestore);
      final read = await target.readAll();
      expect(read.map((item) => item.id), ['a']);

      expect(await target.saveAll([...read, _item('b')]), isTrue);
      expect(
        (await privateOf(firestore).get()).docs.map((doc) => doc.id),
        unorderedEquals(['p', 'x']),
      );
    });

    test('after a failed private watch, saving what readAll returned '
        'works and a partial private list is refused', () async {
      final firestore = FakeFirebaseFirestore();
      await put(firestore, 'a', _item('a').toJson());
      final wrongKey = SealedCollection(
        privateOf(firestore),
        cipher: householdCipher.cipher,
      );
      await privateOf(firestore)
          .doc('x')
          .set(await wrongKey.seal('x', private('x').toJson()));
      final target = both(firestore);
      expect((await target.watchAll().first).map((item) => item.id), ['a']);
      await privateOf(firestore).doc('x').delete();
      final ownKey = SealedCollection(
        privateOf(firestore),
        cipher: userCipher.cipher,
      );
      await privateOf(firestore)
          .doc('p')
          .set(await ownKey.seal('p', private('p').toJson()));

      // A recipe adds to the household list from a full read.
      final read = await target.readAll();
      expect(await target.saveAll([...read, _item('b')]), isTrue);
      expect(
        (await collectionOf(firestore).get()).docs.map((doc) => doc.id),
        unorderedEquals(['a', 'b']),
      );

      // A private list without the entries the read saw is refused.
      await expectLater(
        target.saveAll([_item('a'), private('q')]),
        throwsStateError,
      );
      expect((await privateOf(firestore).get()).docs.map((doc) => doc.id), [
        'p',
      ]);
    });

    test('a household change after readAll does not write the private '
        'list', () async {
      final firestore = FakeFirebaseFirestore();
      final target = both(firestore);
      await target.saveAll([_item('a'), private('p')]);
      final reader = both(firestore);
      final read = await reader.readAll();

      // Another device adds a private entry after the read.
      final ownKey = SealedCollection(
        privateOf(firestore),
        cipher: userCipher.cipher,
      );
      await privateOf(firestore)
          .doc('q')
          .set(await ownKey.seal('q', private('q').toJson()));

      expect(
        await reader.saveAll([
          for (final item in read)
            if (item.isPrivate) item else item.copyWith(name: 'Brot'),
        ]),
        isTrue,
      );
      expect(
        (await privateOf(firestore).get()).docs.map((doc) => doc.id),
        unorderedEquals(['p', 'q']),
      );
    });

    test('saveAll with a private item throws without the user key', () async {
      final target = repository(FakeFirebaseFirestore());

      await expectLater(target.saveAll([private('p')]), throwsStateError);
    });
  });
}
