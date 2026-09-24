import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';

part 'user_data_key_session.g.dart';

typedef _Identity = ({String uid, bool isAnonymous});

/// Resolves the data key of the signed-in user.
///
/// A guest key lives only on the device. A real account also gets a key
/// backup in Firestore that only the recovery key opens. The recovery key is
/// also backed up with the platform (Google Block Store, iCloud Keychain), so
/// a new device usually restores the data key without asking.
@Riverpod(keepAlive: true)
class UserDataKeySession extends _$UserDataKeySession {
  @override
  Future<UserDataKeyState> build() async {
    final repository = ref.watch(userDataKeyRepositoryProvider);
    final identity = await ref.watch(
      authStateChangesProvider.selectAsync(
        (user) => user == null
            ? null
            : (uid: user.uid, isAnonymous: user.isAnonymous),
      ),
    );
    if (identity == null || repository == null) {
      return const UserDataKeySignedOut();
    }
    return await _resolve(repository, identity);
  }

  /// Opens the key backup with [typedRecoveryKey] and stores the key.
  ///
  /// Throws [InvalidRecoveryKeyException] if the key is malformed or wrong.
  Future<void> restore(String typedRecoveryKey) async {
    final current = state.value;
    if (current is! UserDataKeyRecoveryRequired) {
      throw StateError('No recovery is pending.');
    }
    final uid = current.uid;
    final repository = _requireRepository();
    final wrappedKey = await repository.loadBackup(uid);
    if (wrappedKey == null) {
      throw StateError('Key backup of $uid is missing.');
    }

    final RecoveryKey recoveryKey;
    try {
      recoveryKey = RecoveryKey.parse(typedRecoveryKey);
    } on FormatException {
      throw const InvalidRecoveryKeyException();
    }
    final dataKey = await _restoreKeys(
      repository,
      uid: uid,
      wrappedKey: wrappedKey,
      recoveryKey: recoveryKey,
    );
    if (dataKey == null) {
      throw const InvalidRecoveryKeyException();
    }
    await _reload();
  }

  /// Records that the user saved the recovery key.
  Future<void> confirmRecoveryKeySaved() async {
    final current = state.value;
    if (current is! UserDataKeyReady) {
      throw StateError('No data key is ready.');
    }
    await _requireRepository().saveRecoveryKeyConfirmed(
      current.uid,
      confirmed: true,
    );
    if (!ref.mounted) return;
    state = AsyncData(
      UserDataKeyReady(
        uid: current.uid,
        cipher: current.cipher,
        recoveryKey: current.recoveryKey,
        recoveryKeyConfirmed: true,
      ),
    );
  }

  /// Offers to save the recovery key in the password manager under
  /// [accountName]. Saving counts as confirmed. Returns `false` when the user
  /// cancels.
  Future<bool> saveRecoveryKeyToPasswordManager({
    required String accountName,
  }) async {
    final recoveryKey = switch (state.value) {
      UserDataKeyReady(:final recoveryKey?) => recoveryKey,
      _ => throw StateError('No recovery key to save.'),
    };
    final saved = await _requireRepository().saveRecoveryKeyToPasswordManager(
      accountName: accountName,
      recoveryKey: recoveryKey,
    );
    if (saved) {
      await confirmRecoveryKeySaved();
    }
    return saved;
  }

  /// Deletes the private data and starts over with a new data key.
  ///
  /// For a user who lost the recovery key: the old data cannot be read
  /// without it.
  Future<void> startFresh() async {
    final (uid, isAnonymous) = switch (state.value) {
      UserDataKeyRecoveryRequired(:final uid) => (uid, false),
      UserDataKeyReady(:final uid, :final recoveryKey) => (
        uid,
        recoveryKey == null,
      ),
      UserDataKeySignedOut() || null => throw StateError('No user signed in.'),
    };
    final repository = _requireRepository();
    await repository.deletePrivateData(uid);
    final dataKey = await PayloadCipher.newDataKey();
    await repository.deleteLocalKeys(uid);
    await repository.saveLocalDataKey(uid, dataKey);
    if (!isAnonymous) {
      final recoveryKey = RecoveryKey.generate();
      await repository.saveLocalRecoveryKey(uid, recoveryKey);
      await repository.replaceBackup(
        uid,
        await recoveryKey.wrapDataKey(dataKey, uid: uid),
      );
    }
    await repository.savePlaintextMigrated(uid);
    await _reload();
  }

  Future<UserDataKeyState> _resolve(
    UserDataKeyRepository repository,
    _Identity identity,
  ) async {
    final uid = identity.uid;
    var localDataKey = await repository.loadLocalDataKey(uid);
    if (localDataKey == null && !identity.isAnonymous) {
      final wrappedKey = await repository.loadBackup(uid);
      if (wrappedKey != null) {
        // A new device: the platform backup may still hold the recovery key.
        final backedUpKey = await repository.loadBackedUpRecoveryKey(uid);
        localDataKey = backedUpKey == null
            ? null
            : await _restoreKeys(
                repository,
                uid: uid,
                wrappedKey: wrappedKey,
                recoveryKey: backedUpKey,
              );
        if (localDataKey == null) {
          return UserDataKeyRecoveryRequired(uid: uid);
        }
      }
    }

    final dataKey = localDataKey ?? await PayloadCipher.newDataKey();
    if (localDataKey == null) {
      await repository.saveLocalDataKey(uid, dataKey);
    }

    RecoveryKey? recoveryKey;
    var recoveryKeyConfirmed = true;
    if (!identity.isAnonymous) {
      recoveryKey = await _ensureBackup(
        repository,
        uid: uid,
        dataKey: dataKey,
        dataKeyIsNew: localDataKey == null,
      );
      if (recoveryKey == null) {
        await repository.deleteLocalKeys(uid);
        return UserDataKeyRecoveryRequired(uid: uid);
      }
      await repository.backUpRecoveryKey(uid, recoveryKey);
      recoveryKeyConfirmed = await repository.loadRecoveryKeyConfirmed(uid);
    }

    final cipher = PayloadCipher(dataKey);
    if (!await repository.loadPlaintextMigrated(uid)) {
      await repository.encryptPlaintextPrivateData(uid, cipher);
      await repository.savePlaintextMigrated(uid);
    }

    return UserDataKeyReady(
      uid: uid,
      cipher: cipher,
      recoveryKey: recoveryKey,
      recoveryKeyConfirmed: recoveryKeyConfirmed,
    );
  }

  /// Makes sure the key backup holds [dataKey] and returns its recovery key.
  ///
  /// Returns `null` when another device created a backup with its own new key
  /// first. Then this device must restore that key instead.
  Future<RecoveryKey?> _ensureBackup(
    UserDataKeyRepository repository, {
    required String uid,
    required SecretKey dataKey,
    required bool dataKeyIsNew,
  }) async {
    final storedRecoveryKey = await repository.loadLocalRecoveryKey(uid);
    if (storedRecoveryKey != null &&
        await repository.loadRecoveryKeyConfirmed(uid)) {
      return storedRecoveryKey;
    }

    final recoveryKey = storedRecoveryKey ?? RecoveryKey.generate();
    if (storedRecoveryKey == null) {
      await repository.saveLocalRecoveryKey(uid, recoveryKey);
    }
    final wrappedKey = await recoveryKey.wrapDataKey(dataKey, uid: uid);
    if (await repository.createBackupIfMissing(uid, wrappedKey)) {
      return recoveryKey;
    }
    if (dataKeyIsNew) {
      return null;
    }
    if (storedRecoveryKey == null) {
      await repository.replaceBackup(uid, wrappedKey);
    }
    return recoveryKey;
  }

  /// Opens the key backup with [recoveryKey] and stores both keys on this
  /// device. Returns `null` if [recoveryKey] does not open the backup.
  Future<SecretKey?> _restoreKeys(
    UserDataKeyRepository repository, {
    required String uid,
    required String wrappedKey,
    required RecoveryKey recoveryKey,
  }) async {
    final SecretKey dataKey;
    try {
      dataKey = await recoveryKey.unwrapDataKey(wrappedKey, uid: uid);
    } on SecretBoxAuthenticationError {
      return null;
    }
    await repository.saveLocalDataKey(uid, dataKey);
    await repository.saveLocalRecoveryKey(uid, recoveryKey);
    await repository.saveRecoveryKeyConfirmed(uid, confirmed: true);
    return dataKey;
  }

  UserDataKeyRepository _requireRepository() {
    final repository = ref.read(userDataKeyRepositoryProvider);
    if (repository == null) {
      throw StateError('Firestore is unavailable.');
    }
    return repository;
  }

  Future<void> _reload() async {
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }
}

/// The owner of the private data and the cipher for it.
typedef UserDataCipher = ({String uid, PayloadCipher cipher});

/// The cipher for the private data of the signed-in user, or `null` while
/// the data key is not ready.
///
/// It carries the uid, so a repository never combines the key of one user with
/// the documents of another while the session switches users.
@Riverpod(keepAlive: true)
UserDataCipher? userDataCipher(Ref ref) {
  final session = ref.watch(userDataKeySessionProvider);
  final state = session.isLoading ? null : session.value;
  return state is UserDataKeyReady
      ? (uid: state.uid, cipher: state.cipher)
      : null;
}
