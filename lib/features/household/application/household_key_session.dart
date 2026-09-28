import 'dart:async';
import 'dart:developer' show log;

import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_data_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';

part 'household_key_session.g.dart';

const _logName = 'HouseholdKeySession';

/// Resolves the household key of the active household.
///
/// Creates the own household when the user has none yet. Each member holds
/// the household key wrapped with their own data key. A member who started
/// fresh lost that entry: with other members left, they ask them for the key;
/// alone, the household data is wiped and a new key follows.
@riverpod
class HouseholdKeySession extends _$HouseholdKeySession {
  @override
  Future<HouseholdKeyState> build() async {
    // A rebuild hands `ref` to the next build. This build checks its own ref,
    // so that it stops once it is replaced.
    final buildRef = ref;
    final dataCipher = ref.watch(userDataCipherProvider);
    final keys = ref.watch(householdKeyRepositoryProvider);
    final members = ref.watch(householdMemberRepositoryProvider);
    final households = ref.watch(householdRepositoryProvider);
    final data = ref.watch(householdDataRepositoryProvider);
    final userKeys = ref.watch(userDataKeyRepositoryProvider);
    final householdId = ref.watch(activeHouseholdIdProvider);
    final ownHouseholdFuture = ref.watch(
      userProfileProvider.selectAsync(
        (profile) => profile == null ? null : (id: profile.ownHouseholdId),
      ),
    );
    if (dataCipher == null ||
        keys == null ||
        members == null ||
        households == null ||
        data == null ||
        userKeys == null) {
      return const HouseholdKeyUnavailable();
    }

    final ownHousehold = await ownHouseholdFuture;
    if (!buildRef.mounted || ownHousehold == null) {
      return const HouseholdKeyUnavailable();
    }
    final ownHouseholdId = ownHousehold.id;
    if (ownHouseholdId == null) {
      // The profile then names the new household and builds this again.
      await households.createOwnHousehold();
      return const HouseholdKeyUnavailable();
    }
    if (householdId == null) {
      return const HouseholdKeyUnavailable();
    }
    _leaveWhenMembershipEnds(
      members,
      households,
      householdId: householdId,
      ownHouseholdId: ownHouseholdId,
    );

    final uid = dataCipher.uid;
    if (await userKeys.loadFreshStartPending(uid)) {
      for (final id in <String>{ownHouseholdId, householdId}) {
        if (!buildRef.mounted) return const HouseholdKeyUnavailable();
        await _cleanUpAfterFreshStart(buildRef, keys, members, data, id, uid);
      }
      if (!buildRef.mounted) return const HouseholdKeyUnavailable();
      await userKeys.saveFreshStartPending(uid, pending: false);
    }
    return await _resolve(
      buildRef,
      keys,
      members,
      data,
      householdId,
      dataCipher,
    );
  }

  /// Opens the household key that another member left with the unlock
  /// [code] and stores it for the user again.
  ///
  /// Throws [InvalidHouseholdRestoreCodeException] for a wrong code.
  Future<void> restoreKey(String code) async {
    final current = state.value;
    final dataCipher = ref.read(userDataCipherProvider);
    final keys = ref.read(householdKeyRepositoryProvider);
    if (current is! HouseholdKeyRestoreRequired ||
        dataCipher == null ||
        keys == null) {
      throw const HouseholdKeyUnavailableException();
    }

    final RecoveryKey parsedCode;
    try {
      parsedCode = RecoveryKey.parse(code);
    } on FormatException {
      throw const InvalidHouseholdRestoreCodeException();
    }
    final householdId = current.householdId;
    final householdKey = await keys.loadRestoredKey(
      householdId: householdId,
      memberUid: dataCipher.uid,
      code: parsedCode,
    );
    await keys.saveKey(
      householdId: householdId,
      memberUid: dataCipher.uid,
      householdKey: householdKey,
      dataCipher: dataCipher.cipher,
    );
    await keys.deleteKeyRestore(
      householdId: householdId,
      memberUid: dataCipher.uid,
    );
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }

  /// A user who waits for the key while nobody else is left to hand it
  /// back starts over: the data is wiped and a new key follows.
  Future<HouseholdKeyState> _resolve(
    Ref buildRef,
    HouseholdKeyRepository keys,
    HouseholdMemberRepository members,
    HouseholdDataRepository data,
    String householdId,
    UserDataCipher dataCipher,
  ) async {
    final uid = dataCipher.uid;
    if (await keys.loadKeyRestoreRequested(
      householdId: householdId,
      memberUid: uid,
    )) {
      if (await members.loadHasOtherMembers(householdId)) {
        return HouseholdKeyRestoreRequired(householdId: householdId);
      }
      if (!buildRef.mounted) return const HouseholdKeyUnavailable();
      await data.wipeHouseholdData(householdId);
      await keys.deleteKey(householdId: householdId, memberUid: uid);
      await keys.deleteKeyRestore(householdId: householdId, memberUid: uid);
    }
    var key = await keys.loadKey(
      householdId: householdId,
      memberUid: uid,
      dataCipher: dataCipher.cipher,
    );
    if (key == null) {
      if (await members.loadHasOtherMembers(householdId)) {
        await keys.requestKeyRestore(householdId: householdId, memberUid: uid);
        return HouseholdKeyRestoreRequired(householdId: householdId);
      }
      key = await _createKey(keys, householdId, dataCipher);
    }
    if (!await keys.loadPlaintextMigrated(householdId)) {
      await keys.encryptPlaintextHouseholdData(householdId, PayloadCipher(key));
    }
    return HouseholdKeyReady(householdId: householdId, key: key);
  }

  /// Removes the key entry that the lost data key wrapped. Other members
  /// still hold the key, so the data stays and the user asks them for it.
  /// Alone, nobody can open the data any more, so it is deleted.
  Future<void> _cleanUpAfterFreshStart(
    Ref buildRef,
    HouseholdKeyRepository keys,
    HouseholdMemberRepository members,
    HouseholdDataRepository data,
    String householdId,
    String uid,
  ) async {
    await keys.deleteKey(householdId: householdId, memberUid: uid);
    final hasOtherMembers = await members.loadHasOtherMembers(householdId);
    if (!buildRef.mounted) {
      return;
    }
    if (hasOtherMembers) {
      await keys.requestKeyRestore(householdId: householdId, memberUid: uid);
    } else {
      await data.wipeHouseholdData(householdId);
    }
  }

  Future<SecretKey> _createKey(
    HouseholdKeyRepository keys,
    String householdId,
    UserDataCipher dataCipher,
  ) async {
    final newKey = await PayloadCipher.newDataKey();
    final created = await keys.saveKey(
      householdId: householdId,
      memberUid: dataCipher.uid,
      householdKey: newKey,
      dataCipher: dataCipher.cipher,
      onlyIfMissing: true,
    );
    if (created) {
      return newKey;
    }
    final stored = await keys.loadKey(
      householdId: householdId,
      memberUid: dataCipher.uid,
      dataCipher: dataCipher.cipher,
    );
    if (stored == null) {
      throw StateError('Household key of $householdId could not be created.');
    }
    return stored;
  }

  /// Leaves the active household [householdId] when an admin removes the
  /// user or deletes it: from a shared household the user goes back to the
  /// own one, from the own household into a new, empty one.
  void _leaveWhenMembershipEnds(
    HouseholdMemberRepository members,
    HouseholdRepository households, {
    required String householdId,
    required String ownHouseholdId,
  }) {
    final subscription = members
        .watchMembershipEnded(householdId)
        .listen(
          (_) => unawaited(
            _leaveEndedHousehold(
              households,
              householdId: householdId,
              ownHouseholdId: ownHouseholdId,
            ),
          ),
          onError: (Object error, StackTrace stackTrace) => log(
            'Failed to watch the membership in $householdId.',
            name: _logName,
            error: error,
            stackTrace: stackTrace,
          ),
        );
    ref.onDispose(() => unawaited(subscription.cancel()));
  }

  Future<void> _leaveEndedHousehold(
    HouseholdRepository households, {
    required String householdId,
    required String ownHouseholdId,
  }) async {
    try {
      if (householdId == ownHouseholdId) {
        await households.replaceOwnHousehold(ownHouseholdId);
      } else {
        await households.returnToOwnHousehold(ownHouseholdId);
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to leave $householdId after the membership ended.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// The household whose data the user sees and the cipher for it.
typedef HouseholdCipher = ({
  String householdId,
  SecretKey key,
  PayloadCipher cipher,
});

/// The cipher for the active household, or `null` while the household key
/// is not ready.
@riverpod
HouseholdCipher? householdCipher(Ref ref) {
  final session = ref.watch(householdKeySessionProvider);
  final state = session.isLoading ? null : session.value;
  return state is HouseholdKeyReady
      ? (
          householdId: state.householdId,
          key: state.key,
          cipher: PayloadCipher(state.key),
        )
      : null;
}
