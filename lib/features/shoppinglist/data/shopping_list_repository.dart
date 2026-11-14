import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_atomic_replace_service.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/utils/combine_latest_pair.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_migration.dart';
import 'package:yamt/features/shoppinglist/data/shopping_private_list_state.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_repository.g.dart';

const _logName = 'ShoppingListRepository';
const _householdsCollection = 'households';
const _usersCollection = 'users';
const _shoppingListCollection = 'shopping_list_items';

/// The shopping list repository of the current household and user.
@riverpod
ShoppingListRepository shoppingListRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ShoppingListRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    householdCipher: ref.watch(householdCipherProvider),
    userCipher: ref.watch(userDataCipherProvider),
  );
}

/// Stores the shopping list items of a household, encrypted with its key,
/// and the private items of the user, encrypted with the user's key. Callers
/// see one list; [ShoppingListItem.isPrivate] tells the two apart.
///
/// Firestore and the household cipher are `null` while the user is signed out
/// or the household key is not ready. Reads then return no items and writes
/// throw a [StateError]. Without the user's key there are no private items,
/// and a write that holds one throws a [StateError].
class ShoppingListRepository {
  /// Creates an instance.
  new({
    required FirebaseFirestore? firestore,
    required HouseholdCipher? householdCipher,
    UserDataCipher? userCipher,
  }) : _collection = firestore == null || householdCipher == null
           ? null
           : SealedCollection(
               firestore
                   .collection(_householdsCollection)
                   .doc(householdCipher.householdId)
                   .collection(_shoppingListCollection),
               cipher: householdCipher.cipher,
             ),
       _privateCollection = firestore == null || userCipher == null
           ? null
           : SealedCollection(
               firestore
                   .collection(_usersCollection)
                   .doc(userCipher.uid)
                   .collection(_shoppingListCollection),
               cipher: userCipher.cipher,
             );

  final SealedCollection? _collection;
  final SealedCollection? _privateCollection;
  // What each list held at the last read or write, so a save writes only
  // the list that changed. Null while unknown.
  String? _sharedStored;
  final _privateState = ShoppingPrivateListState();
  Future<void> _writeBarrier = Future<void>.value();
  bool _holdsUnmigratedItems = false;

  /// Whether the private list failed at the last read. The household list
  /// still works; private entries are hidden and cannot be saved.
  bool get privateUnreadable => _privateState.isUnreadable;

  /// Temporary migration, added in 3.11.0: removed in 3.14.0. Whether the
  /// last read held a document from before `is_done`. Reads hand such
  /// documents out in the new shape; [saveAll] stores them in it.
  bool get holdsUnmigratedItems => _holdsUnmigratedItems;

  /// Watches all shopping list items in realtime.
  ///
  /// A watch that Firestore rules deny emits no items and ends.
  Stream<List<ShoppingListItem>> watchAll() {
    final collection = _collection;
    if (collection == null) {
      return Stream<List<ShoppingListItem>>.value(const <ShoppingListItem>[]);
    }
    final private = _privateCollection;
    if (private == null) return _watch(collection, isPrivate: false);
    // The household items with the private ones after them.
    return combineLatestPair(
      _watch(collection, isPrivate: false),
      _watch(private, isPrivate: true),
      (shared, own) => [...shared, ...own],
    );
  }

  /// Loads all shopping list items. Throws when the household list cannot
  /// be read. A private list that fails is left out and logged, and no save
  /// writes it until a read succeeds. After a failed watch, saving what this
  /// returned writes the private list.
  Future<List<ShoppingListItem>> readAll() async {
    final collection = _collection;
    if (collection == null) {
      return const <ShoppingListItem>[];
    }
    final snapshot = await collection.reference.get();
    final shared = _decode(
      await collection.openAll(snapshot),
      isPrivate: false,
    );
    final private = _privateCollection;
    if (private == null) return shared;
    try {
      // Records what is stored, so an unchanged save skips it.
      final own = _decode(
        await private.openAll(await private.reference.get()),
        isPrivate: true,
        tracksPrivate: false,
      );
      return [...shared, ...own];
    } on Object catch (error, stackTrace) {
      _privateState.markReadFailed();
      _logPrivateReadFailure(error, stackTrace);
      return shared;
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
    final private = _privateCollection;
    final own = [
      for (final item in items)
        if (item.isPrivate) item,
    ];
    final writesPrivate = private != null && _privateState.mayWrite(own);
    // Only a change to private entries that cannot be written fails.
    if (!writesPrivate && own.isNotEmpty && _privateState.differs(own)) {
      return Future<bool>.error(
        StateError('The private shopping list is not readable.'),
      );
    }
    final shared = [
      for (final item in items)
        if (!item.isPrivate) item,
    ];
    // The two lists are written one after the other, not together: when the
    // second write fails, the first one stays.
    final write = _writeBarrier.then((_) async {
      final sharedNext = shoppingListSignature(shared);
      if (sharedNext != _sharedStored || _holdsUnmigratedItems) {
        if (!await _replaceAll(collection, shared)) return false;
        _sharedStored = sharedNext;
        _holdsUnmigratedItems = false;
      }
      // A save that may not write the private list leaves it alone.
      if (!writesPrivate || !_privateState.differs(own)) return true;
      if (!await _replaceAll(private, own)) return false;
      _privateState.recordWrite(own);
      return true;
    });
    _writeBarrier = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }

  Stream<List<ShoppingListItem>> _watch(
    SealedCollection collection, {
    required bool isPrivate,
  }) async* {
    try {
      await for (final snapshot in collection.reference.snapshots()) {
        yield _decode(await collection.openAll(snapshot), isPrivate: isPrivate);
      }
    } on Object catch (error, stackTrace) {
      if (isPrivate) {
        // The household list stays usable when the private one fails.
        _privateUnreadable(error, stackTrace);
        yield const <ShoppingListItem>[];
        return;
      }
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

  /// An unreadable private list counts as empty; saves leave it alone.
  void _privateUnreadable(Object error, StackTrace stackTrace) {
    _privateState.markUnreadable();
    _logPrivateReadFailure(error, stackTrace);
  }

  void _logPrivateReadFailure(Object error, StackTrace stack) => log(
    'Private list unreadable.',
    name: _logName,
    error: error,
    stackTrace: stack,
  );

  List<ShoppingListItem> _decode(
    List<OpenedDocument> documents, {
    required bool isPrivate,
    bool tracksPrivate = true,
  }) {
    final items = <ShoppingListItem>[];
    if (!isPrivate) {
      _holdsUnmigratedItems = documents.any(
        (document) => !document.data.containsKey('is_done'),
      );
    }
    for (final document in documents) {
      try {
        items.add(
          ShoppingListItem.fromJson(
            migrateStoredShoppingListItem(document.data),
            isPrivate: isPrivate,
          ),
        );
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted shopping list item ${document.id}.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (isPrivate) {
      _privateState.recordRead(items, fromWatch: tracksPrivate);
    } else {
      _sharedStored = shoppingListSignature(items);
    }
    return items;
  }
}
