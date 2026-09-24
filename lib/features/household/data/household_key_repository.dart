import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/secure_storage_provider.dart';

part 'household_key_repository.g.dart';

const _usersCollection = 'users';
const _householdKeysCollection = 'household_keys';
const _wrappedKeyField = 'wrapped_key';
const _keyJsonField = 'key';
const _migratedFlagValue = 'true';

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

/// The household collections that the household key encrypts, with the fields
/// that stay readable for queries.
const householdEncryptedCollections = <String, List<String>>{
  'inventory_items': inventoryItemPlaintextFields,
  'shopping_list_items': <String>[],
  'prepared_meals': <String>[],
  'prepared_meal_templates': <String>[],
  'kitchen_utensils': <String>[],
  'inventory_discard_events': inventoryDiscardEventPlaintextFields,
  'inventory_activity_events': inventoryActivityEventPlaintextFields,
};

/// Stores the household key of a data owner, wrapped separately for every
/// member with that member's own data key.
class HouseholdKeyRepository {
  /// Creates the repository.
  const new({required this._firestore, required this._storage});

  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;

  /// Loads the household key of [ownerUid] for [memberUid], opened with the
  /// member's [dataCipher]. Returns `null` when the member has no entry.
  Future<SecretKey?> loadKey({
    required String ownerUid,
    required String memberUid,
    required PayloadCipher dataCipher,
  }) async {
    final reference = _keyDocument(ownerUid, memberUid);
    final snapshot = await reference.get();
    final wrapped = snapshot.data()?[_wrappedKeyField];
    if (wrapped is! String) {
      return null;
    }
    final json = await dataCipher.decryptJson(wrapped, aad: reference.path);
    return SecretKey(base64Decode(json[_keyJsonField] as String));
  }

  /// Saves [householdKey] for [memberUid], wrapped with the member's
  /// [dataCipher]. With [onlyIfMissing], an existing entry wins and `false`
  /// is returned.
  Future<bool> saveKey({
    required String ownerUid,
    required String memberUid,
    required SecretKey householdKey,
    required PayloadCipher dataCipher,
    bool onlyIfMissing = false,
  }) async {
    final reference = _keyDocument(ownerUid, memberUid);
    final wrapped = await dataCipher.encryptJson(<String, dynamic>{
      _keyJsonField: base64Encode(await householdKey.extractBytes()),
    }, aad: reference.path);
    final data = <String, dynamic>{_wrappedKeyField: wrapped};
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

  /// Deletes the key entry of [memberUid] in the household of [ownerUid].
  Future<void> deleteKey({
    required String ownerUid,
    required String memberUid,
  }) {
    return _keyDocument(ownerUid, memberUid).delete();
  }

  /// Whether this device already encrypted the plaintext household data of
  /// [ownerUid].
  Future<bool> loadPlaintextMigrated(String ownerUid) async {
    return await _storage.read(key: _migratedName(ownerUid)) ==
        _migratedFlagValue;
  }

  /// Encrypts the plaintext household data of [ownerUid] once.
  ///
  /// Temporary: remove once all accounts are migrated.
  Future<void> encryptPlaintextHouseholdData(
    String ownerUid,
    PayloadCipher householdCipher,
  ) async {
    await encryptPlaintextDocuments(
      firestore: _firestore,
      cipher: householdCipher,
      collections: <EncryptedCollection>[
        for (final entry in householdEncryptedCollections.entries)
          EncryptedCollection(
            '$_usersCollection/$ownerUid/${entry.key}',
            plaintextFields: entry.value,
          ),
      ],
      fields: const <EncryptedDocumentField>[],
    );
    await _storage.write(
      key: _migratedName(ownerUid),
      value: _migratedFlagValue,
    );
  }

  DocumentReference<Map<String, dynamic>> _keyDocument(
    String ownerUid,
    String memberUid,
  ) {
    return _firestore
        .collection(_usersCollection)
        .doc(ownerUid)
        .collection(_householdKeysCollection)
        .doc(memberUid);
  }
}

String _migratedName(String ownerUid) => 'household_data_encrypted_$ownerUid';

/// Household key repository, or `null` while Firestore is unavailable.
@riverpod
HouseholdKeyRepository? householdKeyRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return null;
  }
  return HouseholdKeyRepository(
    firestore: firestore,
    storage: ref.watch(secureStorageProvider),
  );
}
