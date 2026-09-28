import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';

part 'household_reset_repository.g.dart';

const _usersCollection = 'users';
const _householdIdField = 'householdId';
const _keyRestoresCollection = 'household_key_restores';
const _wrappedKeyField = 'wrapped_household_key';
const _maxBatchSize = 400;

/// Cleans up the household data of a user who started fresh, and hands the
/// household key back to a host who lost it.
///
/// A host who started fresh while members still hold the household key asks
/// for it with a restore request. A member answers with a code: the household
/// key wrapped with a one-time secret that only the code carries.
class HouseholdResetRepository {
  /// Creates the repository.
  const new({required this._firestore, required this._storage});

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Whether other users are members of the household of [ownerUid].
  Future<bool> loadHasMembers(String ownerUid) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .where(_householdIdField, isEqualTo: ownerUid)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Deletes the household documents and images of [ownerUid].
  Future<void> deleteHouseholdData(String ownerUid) async {
    final references = <DocumentReference<Map<String, dynamic>>>[];
    for (final collection in householdEncryptedCollections.keys) {
      final snapshot = await _firestore
          .collection('$_usersCollection/$ownerUid/$collection')
          .get();
      references.addAll(snapshot.docs.map((document) => document.reference));
    }
    for (final chunk in FirestoreBatchChunker.chunk(
      operations: references,
      maxChunkSize: _maxBatchSize,
    )) {
      final batch = _firestore.batch();
      chunk.forEach(batch.delete);
      await batch.commit();
    }
    for (final folder in householdImageFolders) {
      await _deleteFolder(_storage.ref('$_usersCollection/$ownerUid/$folder'));
    }
  }

  /// Asks the members of [ownerUid]'s household for the household key.
  Future<void> requestKeyRestore(String ownerUid) {
    return _restoreDocument(ownerUid).set(const <String, dynamic>{});
  }

  /// Whether the host [ownerUid] waits for the household key.
  Future<bool> loadKeyRestoreRequested(String ownerUid) async {
    return (await _restoreDocument(ownerUid).get()).exists;
  }

  /// Watches whether the host [ownerUid] waits for the household key.
  Stream<bool> watchKeyRestoreRequested(String ownerUid) {
    return _restoreDocument(ownerUid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Wraps [householdKey] for the host [ownerUid] and returns the code that
  /// opens it.
  Future<RecoveryKey> saveRestoreCode({
    required String ownerUid,
    required SecretKey householdKey,
  }) async {
    final reference = _restoreDocument(ownerUid);
    final code = RecoveryKey.generate();
    final wrapped = await code.wrapDataKey(householdKey, uid: reference.path);
    await reference.set(<String, dynamic>{_wrappedKeyField: wrapped});
    return code;
  }

  /// Opens the household key that a member left for [ownerUid] with [code].
  ///
  /// Throws [InvalidHouseholdRestoreCodeException] if no member left a key
  /// or [code] does not open it.
  Future<SecretKey> loadRestoredKey({
    required String ownerUid,
    required RecoveryKey code,
  }) async {
    final reference = _restoreDocument(ownerUid);
    final wrapped = (await reference.get()).data()?[_wrappedKeyField];
    if (wrapped is! String) {
      throw const InvalidHouseholdRestoreCodeException();
    }
    try {
      return await code.unwrapDataKey(wrapped, uid: reference.path);
    } on SecretBoxAuthenticationError {
      throw const InvalidHouseholdRestoreCodeException();
    }
  }

  /// Deletes the restore request of [ownerUid].
  Future<void> deleteKeyRestore(String ownerUid) {
    return _restoreDocument(ownerUid).delete();
  }

  Future<void> _deleteFolder(Reference folder) async {
    final result = await folder.listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  DocumentReference<Map<String, dynamic>> _restoreDocument(String ownerUid) {
    return _firestore.collection(_keyRestoresCollection).doc(ownerUid);
  }
}

/// Household reset repository, or `null` while Firebase is unavailable.
@riverpod
HouseholdResetRepository? householdResetRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final storage = ref.watch(firebaseStorageProvider);
  if (firestore == null || storage == null) {
    return null;
  }
  return HouseholdResetRepository(firestore: firestore, storage: storage);
}
