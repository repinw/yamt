import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';

part 'shopping_shelf_choice_repository.g.dart';

const _householdsCollection = 'households';
const _choicesCollection = 'shopping_shelf_choices';
const _choicesDocument = 'all';

/// The shelf choices of the current household.
@riverpod
ShoppingShelfChoiceRepository shoppingShelfChoiceRepository(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ShoppingShelfChoiceRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    householdCipher: ref.watch(householdCipherProvider),
  );
}

/// Stores which shelf the household chose per product, in one document
/// encrypted with the household key.
///
/// Without a signed-in user or a ready household key it holds no choices and
/// a save throws a [StateError].
class ShoppingShelfChoiceRepository {
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
                   .collection(_choicesCollection),
               cipher: householdCipher.cipher,
             );

  final SealedCollection? _collection;

  /// Watches the choices. A missing document holds none; read errors pass
  /// on.
  Stream<ShoppingShelfChoices> watchChoices() async* {
    final collection = _collection;
    if (collection == null) {
      yield const {};
      return;
    }
    await for (final snapshot
        in collection.reference.doc(_choicesDocument).snapshots()) {
      final data = await collection.open(snapshot);
      yield data == null ? const {} : shoppingShelfChoicesFromJson(data);
    }
  }

  /// Adds [changes] to the stored choices in a transaction, so a choice
  /// another member saves at the same time stays. With [keepStored] a
  /// stored choice wins over the change, so a guess only fills gaps. Throws
  /// a [StateError]
  /// while signed out or without the household key, and passes on read and
  /// write errors.
  Future<void> addChoices(
    ShoppingShelfChoices changes, {
    bool keepStored = false,
  }) async {
    final collection = _collection;
    if (collection == null) {
      throw StateError('Shelf choices are not available while signed out.');
    }
    final document = collection.reference.doc(_choicesDocument);
    await collection.reference.firestore.runTransaction((transaction) async {
      final stored = await collection.open(await transaction.get(document));
      // Merged on the stored map as it is, so shelves of a newer app stay.
      final storedChoices = stored == null
          ? const <String, Object?>{}
          : {...?(stored['choices'] as Map?)?.cast<String, Object?>()};
      final changed = shoppingShelfChoicesToJson(changes)['choices'] as Map;
      final next = keepStored
          ? {...changed, ...storedChoices}
          : {...storedChoices, ...changed};
      transaction.set(
        document,
        await collection.seal(_choicesDocument, {'choices': next}),
      );
    });
  }
}
