import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';

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
    if (ownerUid == null || dataCipher == null || repository == null) {
      return const HouseholdKeyUnavailable();
    }

    final ownKey = await _ensureOwnKey(repository, dataCipher);
    if (ownerUid == dataCipher.uid) {
      return HouseholdKeyReady(ownerUid: ownerUid, key: ownKey);
    }

    final hostKey = await repository.loadKey(
      ownerUid: ownerUid,
      memberUid: dataCipher.uid,
      dataCipher: dataCipher.cipher,
    );
    if (hostKey == null) {
      return HouseholdKeyInviteRequired(ownerUid: ownerUid);
    }
    return HouseholdKeyReady(ownerUid: ownerUid, key: hostKey);
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
