import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_repository.g.dart';

const _logName = 'ShoppingListRepository';
const _householdsCollection = 'households';
const _shoppingListCollection = 'shopping_list_items';

/// The shopping list repository of the current household.
@riverpod
ShoppingListRepository shoppingListRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ShoppingListRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    householdCipher: ref.watch(householdCipherProvider),
  );
}

/// Stores the shopping list items of a household, encrypted with its key.
///
/// Firestore and the household cipher are `null` while the user is signed out
/// or the household key is not ready. Reads then return no items and writes
/// throw a [StateError].
class ShoppingListRepository {
  /// Creates an instance.
  new({
    required FirebaseFirestore? firestore,
    required HouseholdCipher? householdCipher,
  }) : _collection = firestore == null || householdCipher == null
           ? null
           : SealedCollection(
               firestore
                   .collection(_householdsCollection)
                   .doc(householdCipher.householdId)
                   .collection(_shoppingListCollection),
               cipher: householdCipher.cipher,
             );

  final SealedCollection? _collection;
  Future<void> _writeBarrier = Future<void>.value();

  /// Watches all shopping list items in realtime.
  ///
  /// A watch that Firestore rules deny emits no items and ends.
  Stream<List<ShoppingListItem>> watchAll() {
    final collection = _collection;
    if (collection == null) {
      return Stream<List<ShoppingListItem>>.value(const <ShoppingListItem>[]);
    }
    return _watch(collection);
  }

  /// Loads all shopping list items.
  Future<List<ShoppingListItem>> readAll() async {
    final collection = _collection;
    if (collection == null) {
      return const <ShoppingListItem>[];
    }
    try {
      final snapshot = await collection.reference.get();
      return _decode(await collection.openAll(snapshot));
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read shopping list items.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <ShoppingListItem>[];
    }
  }

  /// Replaces all stored shopping list items with [items].
  ///
  /// Writes run one after another. Returns `false` when the write fails.
  /// Throws a [StateError] while the user is signed out or the household key
  /// is not ready.
  Future<bool> saveAll(List<ShoppingListItem> items) {
    final collection = _collection;
    if (collection == null) {
      return Future<bool>.error(
        StateError('Shopping list is not available while signed out.'),
      );
    }
    final write = _writeBarrier.then((_) => _replaceAll(collection, items));
    _writeBarrier = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }

  Stream<List<ShoppingListItem>> _watch(SealedCollection collection) async* {
    try {
      await for (final snapshot in collection.reference.snapshots()) {
        yield _decode(await collection.openAll(snapshot));
      }
    } on Object catch (error, stackTrace) {
      final denied =
          error is FirebaseException && error.code == 'permission-denied';
      log(
        denied
            ? 'Shopping list watch denied by Firestore rules.'
            : 'Failed to watch shopping list items.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      if (!denied) {
        rethrow;
      }
      yield const <ShoppingListItem>[];
    }
  }

  Future<bool> _replaceAll(
    SealedCollection collection,
    List<ShoppingListItem> items,
  ) async {
    try {
      await collection.ensureAllSealed();
      final replace = FirestoreAtomicReplaceService(
        firestore: collection.reference.firestore,
      );
      await replace.replaceAll(
        collection: collection.reference,
        documentsById: await collection.sealAll(<String, Map<String, dynamic>>{
          for (final item in items) item.id: item.toJson(),
        }),
      );
      return true;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to replace shopping list items.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  List<ShoppingListItem> _decode(List<OpenedDocument> documents) {
    final items = <ShoppingListItem>[];
    for (final document in documents) {
      try {
        items.add(ShoppingListItem.fromJson(document.data));
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted shopping list item ${document.id}.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }
}
