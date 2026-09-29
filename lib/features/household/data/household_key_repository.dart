import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';

part 'household_key_repository.g.dart';

const _householdsCollection = 'households';
const _keysCollection = 'keys';
const _keyRestoresCollection = 'key_restores';
const _wrappedKeyField = 'wrapped_key';
const _restoreWrappedKeyField = 'wrapped_household_key';
const _keyJsonField = 'key';

/// Fields of an inventory item that stay readable for the recent manual
/// items query.
const inventoryItemPlaintextFields = <String>[
  'entry_date',
  'origin',
  'is_deposit',
  'is_discount',
];

/// Field of a discard event that stays readable for ordering.
const inventoryDiscardEventPlaintextFields = <String>['discarded_at'];

/// Field of an activity event that stays readable for ordering.
const inventoryActivityEventPlaintextFields = <String>['happened_at'];

/// The household collections that the household key encrypts.
const householdEncryptedCollections = <String>[
  'inventory_items',
  'shopping_list_items',
  'prepared_meals',
  'prepared_meal_templates',
  'kitchen_utensils',
  'inventory_discard_events',
  'inventory_activity_events',
];

/// Storage folders under `households/{householdId}` that hold household
/// images.
const householdImageFolders = <String>['kitchen_utensils', 'recipes'];

/// Stores the household key, wrapped separately for every member with that
/// member's own data key, and hands it back to a member who lost it.
///
/// A member who started fresh asks for the key with a restore request.
/// Another member answers with an unlock code: the household key wrapped with
/// a one-time secret that only the code carries.
class HouseholdKeyRepository {
  /// Creates the repository.
  const new({required this._firestore});

  final FirebaseFirestore _firestore;

  /// The key entry of [memberUid] in [householdId].
  DocumentReference<Map<String, dynamic>> keyDocument(
    String householdId,
    String memberUid,
  ) {
    return _household(householdId).collection(_keysCollection).doc(memberUid);
  }

  /// The restore request of [memberUid] in [householdId].
  DocumentReference<Map<String, dynamic>> restoreDocument(
    String householdId,
    String memberUid,
  ) {
    return _household(householdId)
        .collection(_keyRestoresCollection)
        .doc(memberUid);
  }

  /// The stored form of [householdKey] for the key entry [reference], wrapped
  /// with the member's [dataCipher].
  Future<Map<String, dynamic>> wrapKey(
    DocumentReference<Map<String, dynamic>> reference,
    SecretKey householdKey,
    PayloadCipher dataCipher,
  ) async {
    final wrapped = await dataCipher.encryptJson(<String, dynamic>{
      _keyJsonField: base64Encode(await householdKey.extractBytes()),
    }, aad: reference.path);
    return <String, dynamic>{_wrappedKeyField: wrapped};
  }

  /// Loads the household key of [householdId] for [memberUid], opened with
  /// the member's [dataCipher]. Returns `null` when the member has no entry.
  Future<SecretKey?> loadKey({
    required String householdId,
    required String memberUid,
    required PayloadCipher dataCipher,
  }) async {
    final reference = keyDocument(householdId, memberUid);
    final wrapped = (await reference.get()).data()?[_wrappedKeyField];
    if (wrapped is! String) {
      return null;
    }
    final json = await dataCipher.decryptJson(wrapped, aad: reference.path);
    return SecretKey(base64Decode(json[_keyJsonField] as String));
  }

  /// Saves [householdKey] for [memberUid]. With [onlyIfMissing], an existing
  /// entry wins and `false` is returned.
  Future<bool> saveKey({
    required String householdId,
    required String memberUid,
    required SecretKey householdKey,
    required PayloadCipher dataCipher,
    bool onlyIfMissing = false,
  }) async {
    final reference = keyDocument(householdId, memberUid);
    final data = await wrapKey(reference, householdKey, dataCipher);
    if (!onlyIfMissing) {
      await reference.set(data);
      return true;
    }
    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        return false;
      }
      transaction.set(reference, data);
      return true;
    });
  }

  /// Deletes the key entry of [memberUid] in [householdId].
  Future<void> deleteKey({
    required String householdId,
    required String memberUid,
  }) {
    return keyDocument(householdId, memberUid).delete();
  }

  /// Asks the other members of [householdId] to hand the key back to
  /// [memberUid].
  Future<void> requestKeyRestore({
    required String householdId,
    required String memberUid,
  }) {
    return restoreDocument(householdId, memberUid).set(<String, dynamic>{});
  }

  /// Whether [memberUid] waits for the key of [householdId].
  Future<bool> loadKeyRestoreRequested({
    required String householdId,
    required String memberUid,
  }) async {
    return (await restoreDocument(householdId, memberUid).get()).exists;
  }

  /// Watches the members of [householdId] who wait for the key.
  Stream<List<String>> watchKeyRestoreRequests(String householdId) {
    return _household(householdId)
        .collection(_keyRestoresCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => document.id)
              .toList(growable: false),
        );
  }

  /// Wraps [householdKey] for [memberUid] and returns the code that opens it.
  Future<RecoveryKey> saveRestoreCode({
    required String householdId,
    required String memberUid,
    required SecretKey householdKey,
  }) async {
    final reference = restoreDocument(householdId, memberUid);
    final code = RecoveryKey.generate();
    final wrapped = await code.wrapDataKey(householdKey, uid: reference.path);
    await reference.set(<String, dynamic>{_restoreWrappedKeyField: wrapped});
    return code;
  }

  /// Opens the household key that a member left for [memberUid] with [code].
  ///
  /// Throws [InvalidHouseholdRestoreCodeException] if no member left a key or
  /// [code] does not open it.
  Future<SecretKey> loadRestoredKey({
    required String householdId,
    required String memberUid,
    required RecoveryKey code,
  }) async {
    final reference = restoreDocument(householdId, memberUid);
    final wrapped = (await reference.get()).data()?[_restoreWrappedKeyField];
    if (wrapped is! String) {
      throw const InvalidHouseholdRestoreCodeException();
    }
    try {
      return await code.unwrapDataKey(wrapped, uid: reference.path);
    } on SecretBoxAuthenticationError {
      throw const InvalidHouseholdRestoreCodeException();
    }
  }

  /// Deletes the restore request of [memberUid] in [householdId].
  Future<void> deleteKeyRestore({
    required String householdId,
    required String memberUid,
  }) {
    return restoreDocument(householdId, memberUid).delete();
  }

  DocumentReference<Map<String, dynamic>> _household(String householdId) {
    return _firestore.collection(_householdsCollection).doc(householdId);
  }
}

/// Household key repository, or `null` while Firestore is unavailable.
@riverpod
HouseholdKeyRepository? householdKeyRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return null;
  }
  return HouseholdKeyRepository(firestore: firestore);
}
