import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';

part 'household_repository.g.dart';

const _usersCollection = 'users';
const _invitesCollection = 'household_invites';
const _inviteCodeLifetime = Duration(days: 1);
const _maxInviteCodeGenerationAttempts = 10;

/// Household repository.
@riverpod
HouseholdRepository householdRepository(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final profile = ref.watch(userProfileProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  final keys = ref.watch(householdKeyRepositoryProvider);

  if (user == null || firestore == null || keys == null) {
    throw StateError('Household sharing requires an authenticated user.');
  }

  return HouseholdRepository(
    firestore: firestore,
    keys: keys,
    dataCipher: ref.watch(userDataCipherProvider),
    currentUserId: user.uid,
    isAnonymous: user.isAnonymous,
    currentHouseholdId: profile?.householdId,
  );
}

/// Defines household repository.
class HouseholdRepository {
  /// Creates an instance.
  new({
    required this._firestore,
    required this._keys,
    required this._dataCipher,
    required this._currentUserId,
    required this._isAnonymous,
    required String? currentHouseholdId,
    Random? random,
  }) : _currentHouseholdId = _normalizeOptional(currentHouseholdId),
       _random = random ?? Random.secure();

  static const _fieldUid = 'uid';
  static const _fieldHouseholdId = 'householdId';
  static const _fieldHostUid = 'hostUid';
  static const _fieldExpiresAt = 'expiresAt';
  static const _fieldWrappedHouseholdKey = 'wrapped_household_key';

  final FirebaseFirestore _firestore;
  final HouseholdKeyRepository _keys;
  final UserDataCipher? _dataCipher;
  final String _currentUserId;
  final bool _isAnonymous;
  final String? _currentHouseholdId;
  final Random _random;

  /// Creates an invite into the current user's household.
  ///
  /// The invite document holds the household key wrapped with the invite
  /// secret, which only the returned [HouseholdInvite] carries.
  Future<HouseholdInvite> generateInviteCode() async {
    _assertVerifiedLeader();
    final dataCipher = _requireDataCipher();
    final householdKey = await _keys.loadKey(
      ownerUid: _currentUserId,
      memberUid: _currentUserId,
      dataCipher: dataCipher.cipher,
    );
    if (householdKey == null) {
      throw const HouseholdKeyUnavailableException();
    }

    for (
      var attempt = 0;
      attempt < _maxInviteCodeGenerationAttempts;
      attempt += 1
    ) {
      final invite = HouseholdInvite(
        code: _generateRandomCode(),
        secret: RecoveryKey.generate(),
      );
      final wrappedKey = await invite.secret.wrapDataKey(
        householdKey,
        uid: _inviteDocument(invite.code).path,
      );
      final created = await _tryCreateInviteCode(invite.code, wrappedKey);
      if (created) {
        return invite;
      }
    }

    throw const HouseholdInviteCodeGenerationFailedException();
  }

  /// Joins the household behind [invite] and stores its household key for
  /// the current user.
  ///
  /// A member of the same household may join again, which restores a missing
  /// key entry.
  Future<void> joinHousehold(HouseholdInvite invite) async {
    final dataCipher = _requireDataCipher();
    final inviteDocument = _inviteDocument(invite.code);
    final snapshot = await inviteDocument.get();
    if (!snapshot.exists) {
      throw const InvalidHouseholdInviteCodeException();
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final expiresAt = data[_fieldExpiresAt];
    final hostUid = _normalizeOptional(data[_fieldHostUid] as String?);
    final wrappedKey = data[_fieldWrappedHouseholdKey];

    if (expiresAt is! Timestamp || hostUid == null || wrappedKey is! String) {
      throw const InvalidHouseholdInviteCodeException();
    }
    if (!DateTime.now().isBefore(expiresAt.toDate())) {
      throw const ExpiredHouseholdInviteCodeException();
    }
    if (hostUid == _currentUserId) {
      throw const OwnHouseholdInviteCodeException();
    }
    if (_currentHouseholdId != null && _currentHouseholdId != hostUid) {
      throw const HouseholdLeaveRequiredException();
    }

    final SecretKey householdKey;
    try {
      householdKey = await invite.secret.unwrapDataKey(
        wrappedKey,
        uid: inviteDocument.path,
      );
    } on SecretBoxAuthenticationError {
      throw const InvalidHouseholdInviteCodeException();
    }

    // The rules grant access to the host's key entries only to members, so
    // the membership must exist before the key entry is written.
    await _userDocument(_currentUserId).set(<String, dynamic>{
      _fieldUid: _currentUserId,
      _fieldHouseholdId: hostUid,
    }, SetOptions(merge: true));
    await _keys.saveKey(
      ownerUid: hostUid,
      memberUid: _currentUserId,
      householdKey: householdKey,
      dataCipher: dataCipher.cipher,
    );
  }

  /// Leave household.
  Future<void> leaveHousehold() async {
    final householdId = _currentHouseholdId;
    if (householdId == null) {
      throw const HouseholdMembershipRequiredException();
    }

    await _keys.deleteKey(ownerUid: householdId, memberUid: _currentUserId);
    await _userDocument(_currentUserId).set(<String, dynamic>{
      _fieldUid: _currentUserId,
      _fieldHouseholdId: FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Remove member.
  Future<void> removeMember(String userId) async {
    _assertVerifiedLeader();
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || normalizedUserId == _currentUserId) {
      throw const HouseholdMemberRemovalDeniedException();
    }

    final snapshot = await _userDocument(normalizedUserId).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final householdId = _normalizeOptional(data[_fieldHouseholdId] as String?);
    if (!snapshot.exists || householdId != _currentUserId) {
      throw const HouseholdMemberRemovalDeniedException();
    }

    await _keys.deleteKey(
      ownerUid: _currentUserId,
      memberUid: normalizedUserId,
    );
    await _userDocument(normalizedUserId).set(<String, dynamic>{
      _fieldHouseholdId: FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  UserDataCipher _requireDataCipher() {
    final dataCipher = _dataCipher;
    if (dataCipher == null || dataCipher.uid != _currentUserId) {
      throw const HouseholdKeyUnavailableException();
    }
    return dataCipher;
  }

  void _assertVerifiedLeader() {
    if (_isAnonymous) {
      throw const HouseholdVerificationRequiredException();
    }
    if (_currentHouseholdId != null) {
      throw const HouseholdLeaderRequiredException();
    }
  }

  DocumentReference<Map<String, dynamic>> _inviteDocument(String code) {
    return _firestore.collection(_invitesCollection).doc(code);
  }

  Future<bool> _tryCreateInviteCode(String code, String wrappedKey) {
    final inviteDocument = _inviteDocument(code);
    final expiresAt = DateTime.now().add(_inviteCodeLifetime);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inviteDocument);
      if (snapshot.exists) {
        return false;
      }

      transaction.set(inviteDocument, <String, dynamic>{
        _fieldHostUid: _currentUserId,
        _fieldExpiresAt: Timestamp.fromDate(expiresAt),
        _fieldWrappedHouseholdKey: wrappedKey,
      });
      return true;
    });
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
  }

  String _generateRandomCode() {
    final value = _random.nextInt(1000000);
    return value.toString().padLeft(6, '0');
  }
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
