import 'dart:convert';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/device/key_backup.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/secure_storage_provider.dart';

part 'user_data_key_repository.g.dart';

const _logName = 'UserDataKeyRepository';
const _usersCollection = 'users';
const _privateCollection = 'private';
const _backupDocumentId = 'data_key';
const _wrappedKeyField = 'wrapped_key';
const _storedFlagValue = 'true';
const _maxBatchSize = 400;

/// Stores the data key of a user: on the device in secure storage, and as a
/// backup in Firestore that only the recovery key can open.
class UserDataKeyRepository {
  /// Creates the repository.
  const new({
    required this._storage,
    required this._firestore,
    required this._keyBackup,
  });

  final FlutterSecureStorage _storage;
  final FirebaseFirestore _firestore;
  final KeyBackup _keyBackup;

  /// Loads the data key stored on this device.
  Future<SecretKey?> loadLocalDataKey(String uid) async {
    final encoded = await _storage.read(key: _dataKeyName(uid));
    return encoded == null ? null : SecretKey(base64Decode(encoded));
  }

  /// Saves the data key on this device.
  Future<void> saveLocalDataKey(String uid, SecretKey dataKey) async {
    await _storage.write(
      key: _dataKeyName(uid),
      value: base64Encode(await dataKey.extractBytes()),
    );
  }

  /// Loads the recovery key stored on this device.
  Future<RecoveryKey?> loadLocalRecoveryKey(String uid) async {
    final formatted = await _storage.read(key: _recoveryKeyName(uid));
    return formatted == null ? null : RecoveryKey.parse(formatted);
  }

  /// Saves the recovery key on this device, so Settings can show it again.
  Future<void> saveLocalRecoveryKey(String uid, RecoveryKey recoveryKey) {
    return _storage.write(
      key: _recoveryKeyName(uid),
      value: recoveryKey.formatted,
    );
  }

  /// Whether the user confirmed that the recovery key is saved.
  Future<bool> loadRecoveryKeyConfirmed(String uid) {
    return _loadFlag(_recoveryKeyConfirmedName(uid));
  }

  /// Saves whether the user confirmed that the recovery key is saved.
  Future<void> saveRecoveryKeyConfirmed(String uid, {required bool confirmed}) {
    return _saveFlag(_recoveryKeyConfirmedName(uid), value: confirmed);
  }

  /// Whether this device already encrypted the plaintext documents of [uid].
  Future<bool> loadPlaintextMigrated(String uid) {
    return _loadFlag(_plaintextMigratedName(uid));
  }

  /// Saves that this device encrypted the plaintext documents of [uid].
  Future<void> savePlaintextMigrated(String uid) {
    return _saveFlag(_plaintextMigratedName(uid), value: true);
  }

  /// Deletes everything this device and the platform backup store for [uid].
  Future<void> deleteLocalKeys(String uid) async {
    for (final name in <String>[
      _dataKeyName(uid),
      _recoveryKeyName(uid),
      _recoveryKeyConfirmedName(uid),
      _plaintextMigratedName(uid),
    ]) {
      await _storage.delete(key: name);
    }
    try {
      await _keyBackup.delete(_recoveryKeyName(uid));
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete the platform backup of the recovery key.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Backs up the recovery key with the platform (Google Block Store), so a
  /// new device restores the data key without asking the user.
  ///
  /// A failure only costs that convenience, so it is logged, not thrown.
  Future<void> backUpRecoveryKey(String uid, RecoveryKey recoveryKey) async {
    try {
      await _keyBackup.save(_recoveryKeyName(uid), recoveryKey.formatted);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to back up the recovery key with the platform.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Loads the recovery key from the platform backup, or `null` if there is
  /// none or it cannot be read.
  Future<RecoveryKey?> loadBackedUpRecoveryKey(String uid) async {
    try {
      final formatted = await _keyBackup.load(_recoveryKeyName(uid));
      return formatted == null ? null : RecoveryKey.parse(formatted);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read the platform backup of the recovery key.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Whether [saveRecoveryKeyToPasswordManager] is available.
  bool get canSaveToPasswordManager => _keyBackup.canSaveToPasswordManager;

  /// Offers to save [recoveryKey] in the password manager under
  /// [accountName]. Returns `false` when the user cancels.
  Future<bool> saveRecoveryKeyToPasswordManager({
    required String accountName,
    required RecoveryKey recoveryKey,
  }) {
    return _keyBackup.saveToPasswordManager(
      id: accountName,
      password: recoveryKey.formatted,
    );
  }

  /// Loads the wrapped data key from the backup document.
  Future<String?> loadBackup(String uid) async {
    final snapshot = await _backupDocument(uid).get();
    final wrapped = snapshot.data()?[_wrappedKeyField];
    return wrapped is String ? wrapped : null;
  }

  /// Creates the backup document unless one exists already.
  ///
  /// Returns `false` when another device created a backup first.
  Future<bool> createBackupIfMissing(String uid, String wrappedKey) {
    final reference = _backupDocument(uid);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        return false;
      }
      transaction.set(reference, <String, dynamic>{
        _wrappedKeyField: wrappedKey,
      });
      return true;
    });
  }

  /// Replaces the backup document.
  Future<void> replaceBackup(String uid, String wrappedKey) {
    return _backupDocument(uid)
        .set(<String, dynamic>{_wrappedKeyField: wrappedKey});
  }

  /// Encrypts the private documents of [uid] that are still plaintext.
  ///
  /// Temporary: remove once all accounts are migrated.
  Future<void> encryptPlaintextPrivateData(String uid, PayloadCipher cipher) {
    return encryptPlaintextDocuments(
      firestore: _firestore,
      cipher: cipher,
      collections: _privateCollections(uid),
      fields: _privateFields(uid),
    );
  }

  /// Deletes all private data of [uid] that the data key encrypts.
  Future<void> deletePrivateData(String uid) async {
    final references = <DocumentReference<Map<String, dynamic>>>[];
    for (final collection in _privateCollections(uid)) {
      final snapshot = await _firestore.collection(collection.path).get();
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
    for (final field in _privateFields(uid)) {
      await _firestore.doc(field.documentPath).set(<String, dynamic>{
        field.field: FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  DocumentReference<Map<String, dynamic>> _backupDocument(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_privateCollection)
        .doc(_backupDocumentId);
  }

  Future<bool> _loadFlag(String name) async {
    return await _storage.read(key: name) == _storedFlagValue;
  }

  Future<void> _saveFlag(String name, {required bool value}) {
    return _storage.write(key: name, value: value ? _storedFlagValue : null);
  }
}

/// The private collections of [uid] that the data key encrypts.
List<EncryptedCollection> _privateCollections(String uid) {
  final userPath = '$_usersCollection/$uid';
  return <EncryptedCollection>[
    EncryptedCollection(
      '$userPath/calorie_entries',
      plaintextFields: const <String>['logged_at'],
    ),
    EncryptedCollection('$userPath/calorie_settings'),
    EncryptedCollection('$userPath/health_weights'),
    EncryptedCollection('$userPath/calorie_product_overrides'),
  ];
}

/// The private fields of [uid] that the data key encrypts.
List<EncryptedDocumentField> _privateFields(String uid) {
  return <EncryptedDocumentField>[
    EncryptedDocumentField('$_usersCollection/$uid', 'burn_week_run_state'),
  ];
}

String _dataKeyName(String uid) => 'data_key_$uid';

String _recoveryKeyName(String uid) => 'recovery_key_$uid';

String _recoveryKeyConfirmedName(String uid) => 'recovery_key_confirmed_$uid';

String _plaintextMigratedName(String uid) => 'private_data_encrypted_$uid';

/// User data key repository, or `null` while Firestore is unavailable.
@Riverpod(keepAlive: true)
UserDataKeyRepository? userDataKeyRepository(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) {
    return null;
  }
  return UserDataKeyRepository(
    storage: ref.watch(secureStorageProvider),
    firestore: firestore,
    keyBackup: ref.watch(keyBackupProvider),
  );
}
