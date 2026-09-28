import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_reset_repository.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';

part 'household_key_session.g.dart';

/// Resolves the household key of the current household data owner.
///
/// Every user owns a household key for the data under their own uid, also
/// while they are a member elsewhere, so that data stays readable after they
/// leave. A member reads the host's key from the entry the member wrote when
/// joining.
@riverpod
class HouseholdKeySession extends _$HouseholdKeySession {
  @override
  Future<HouseholdKeyState> build() async {
    final ownerUid = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
    final dataCipher = ref.watch(userDataCipherProvider);
    final repository = ref.watch(householdKeyRepositoryProvider);
    final resets = ref.watch(householdResetRepositoryProvider);
    final userKeys = ref.watch(userDataKeyRepositoryProvider);
    if (ownerUid == null ||
        dataCipher == null ||
        repository == null ||
        resets == null ||
        userKeys == null) {
      return const HouseholdKeyUnavailable();
    }

    final uid = dataCipher.uid;
    if (await userKeys.loadFreshStartPending(uid)) {
      await _cleanUpAfterFreshStart(repository, resets, uid, ownerUid);
      await userKeys.saveFreshStartPending(uid, pending: false);
    }
    final restoreRequested = await resets.loadKeyRestoreRequested(uid);
    if (ownerUid == uid) {
      if (restoreRequested) {
        return HouseholdKeyRestoreRequired(ownerUid: uid);
      }
      return HouseholdKeyReady(
        ownerUid: uid,
        key: await _ensureOwnKey(repository, dataCipher),
      );
    }

    // The own key waits for a member while a restore is requested.
    if (!restoreRequested) {
      await _ensureOwnKey(repository, dataCipher);
    }
    final hostKey = await repository.loadKey(
      ownerUid: ownerUid,
      memberUid: uid,
      dataCipher: dataCipher.cipher,
    );
    if (hostKey == null) {
      return HouseholdKeyInviteRequired(ownerUid: ownerUid);
    }
    return HouseholdKeyReady(ownerUid: ownerUid, key: hostKey);
  }

  /// Opens the household key that a member left with the restore [code] and
  /// stores it for the host again.
  ///
  /// Throws [InvalidHouseholdRestoreCodeException] for a wrong code.
  Future<void> restoreKey(String code) async {
    final current = state.value;
    final dataCipher = ref.read(userDataCipherProvider);
    final repository = ref.read(householdKeyRepositoryProvider);
    final resets = ref.read(householdResetRepositoryProvider);
    if (current is! HouseholdKeyRestoreRequired ||
        dataCipher == null ||
        dataCipher.uid != current.ownerUid ||
        repository == null ||
        resets == null) {
      throw const HouseholdKeyUnavailableException();
    }

    final RecoveryKey parsedCode;
    try {
      parsedCode = RecoveryKey.parse(code);
    } on FormatException {
      throw const InvalidHouseholdRestoreCodeException();
    }
    final householdKey = await resets.loadRestoredKey(
      ownerUid: current.ownerUid,
      code: parsedCode,
    );
    await repository.saveKey(
      ownerUid: current.ownerUid,
      memberUid: current.ownerUid,
      householdKey: householdKey,
      dataCipher: dataCipher.cipher,
    );
    await resets.deleteKeyRestore(current.ownerUid);
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }

  /// Removes the household key entries that the old data key wrapped.
  ///
  /// Members still hold the key of the own household, so its data stays and
  /// the user asks them for the key. Without members nobody can open the data
  /// any more, so it is deleted and a new key follows.
  Future<void> _cleanUpAfterFreshStart(
    HouseholdKeyRepository repository,
    HouseholdResetRepository resets,
    String uid,
    String ownerUid,
  ) async {
    if (ownerUid != uid) {
      await repository.deleteKey(ownerUid: ownerUid, memberUid: uid);
    }
    await repository.deleteKey(ownerUid: uid, memberUid: uid);
    if (await resets.loadHasMembers(uid)) {
      await resets.requestKeyRestore(uid);
    } else {
      await resets.deleteHouseholdData(uid);
    }
  }

  Future<SecretKey> _ensureOwnKey(
    HouseholdKeyRepository repository,
    UserDataCipher dataCipher,
  ) async {
    final uid = dataCipher.uid;
    var ownKey = await repository.loadKey(
      ownerUid: uid,
      memberUid: uid,
      dataCipher: dataCipher.cipher,
    );
    if (ownKey == null) {
      final newKey = await PayloadCipher.newDataKey();
      final created = await repository.saveKey(
        ownerUid: uid,
        memberUid: uid,
        householdKey: newKey,
        dataCipher: dataCipher.cipher,
        onlyIfMissing: true,
      );
      ownKey = created
          ? newKey
          : await repository.loadKey(
              ownerUid: uid,
              memberUid: uid,
              dataCipher: dataCipher.cipher,
            );
    }
    if (ownKey == null) {
      throw StateError('Household key of $uid could not be created.');
    }
    if (!await repository.loadPlaintextMigrated(uid)) {
      await repository.encryptPlaintextHouseholdData(
        uid,
        PayloadCipher(ownKey),
      );
    }
    return ownKey;
  }
}

/// Whether the host of the household that the user is a member of lost the
/// household key and waits for a restore code. Always `false` for a host.
@riverpod
Stream<bool> householdKeyRestoreRequested(Ref ref) {
  final ownerUid = ref.watch(effectiveHouseholdDataOwnerUserIdProvider);
  final uid = ref.watch(userDataCipherProvider)?.uid;
  final resets = ref.watch(householdResetRepositoryProvider);
  if (ownerUid == null || uid == null || ownerUid == uid || resets == null) {
    return Stream<bool>.value(false);
  }
  return resets.watchKeyRestoreRequested(ownerUid);
}

/// The owner of the household data and the cipher for it.
typedef HouseholdCipher = ({
  String ownerUid,
  SecretKey key,
  PayloadCipher cipher,
});

/// The cipher for the current household data, or `null` while the household
/// key is not ready.
@riverpod
HouseholdCipher? householdCipher(Ref ref) {
  final session = ref.watch(householdKeySessionProvider);
  final state = session.isLoading ? null : session.value;
  return state is HouseholdKeyReady
      ? (
          ownerUid: state.ownerUid,
          key: state.key,
          cipher: PayloadCipher(state.key),
        )
      : null;
}
