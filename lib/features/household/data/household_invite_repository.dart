import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/domain/household_member.dart';

part 'household_invite_repository.g.dart';

const _invitesCollection = 'household_invites';
const _usersCollection = 'users';
const _householdIdField = 'householdId';
const _expiresAtField = 'expiresAt';
const _wrappedHouseholdKeyField = 'wrapped_household_key';
const _inviteCodeLifetime = Duration(days: 1);
const _maxInviteCodeGenerationAttempts = 10;

/// Invites people into a household and lets them join.
///
/// The invite document `household_invites/{code}` holds the household key
/// wrapped with the invite secret, which only the QR code or link carries.
class HouseholdInviteRepository {
  /// Creates the repository.
  new({
    required this._firestore,
    required this._keys,
    required this._members,
    required this._currentUserId,
    required this._isAnonymous,
    required this._dataCipher,
    required this._now,
    Random? random,
  }) : _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final HouseholdKeyRepository _keys;
  final HouseholdMemberRepository _members;
  final String _currentUserId;
  final bool _isAnonymous;
  final UserDataCipher? _dataCipher;
  final DateTime Function() _now;
  final Random _random;

  /// Creates an invite into [householdId]. Only a verified admin may invite.
  Future<HouseholdInvite> generateInvite(String householdId) async {
    if (_isAnonymous) {
      throw const HouseholdVerificationRequiredException();
    }
    final member = await _members.loadCurrentMember(householdId);
    if (member == null || !member.isAdmin) {
      throw const HouseholdAdminRequiredException();
    }
    final householdKey = await _keys.loadKey(
      householdId: householdId,
      memberUid: _currentUserId,
      dataCipher: _requireDataCipher().cipher,
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
      if (await _tryCreateInvite(invite.code, householdId, wrappedKey)) {
        return invite;
      }
    }
    throw const HouseholdInviteCodeGenerationFailedException();
  }

  /// Joins the household behind [invite] and makes it the active household.
  ///
  /// Only a user who is alone in the own household may join; the own
  /// household [ownHouseholdId] pauses until the user leaves again.
  Future<void> joinHousehold(
    HouseholdInvite invite, {
    required String activeHouseholdId,
    required String ownHouseholdId,
  }) async {
    final dataCipher = _requireDataCipher();
    final inviteDocument = _inviteDocument(invite.code);
    final data = (await inviteDocument.get()).data();
    final householdId = data?[_householdIdField];
    final expiresAt = data?[_expiresAtField];
    final wrappedKey = data?[_wrappedHouseholdKeyField];
    if (householdId is! String ||
        expiresAt is! Timestamp ||
        wrappedKey is! String) {
      throw const InvalidHouseholdInviteCodeException();
    }
    if (!_now().isBefore(expiresAt.toDate())) {
      throw const ExpiredHouseholdInviteCodeException();
    }
    if (householdId == activeHouseholdId) {
      throw const OwnHouseholdInviteCodeException();
    }
    if (activeHouseholdId != ownHouseholdId ||
        await _members.loadHasOtherMembers(ownHouseholdId)) {
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
    final keyDocument = _keys.keyDocument(householdId, _currentUserId);
    final keyData = await _keys.wrapKey(
      keyDocument,
      householdKey,
      dataCipher.cipher,
    );
    await _firestore.runTransaction((transaction) async {
      transaction
        ..set(
          _members.memberDocument(householdId, _currentUserId),
          _members.newMemberData(HouseholdRole.member, inviteCode: invite.code),
        )
        ..set(keyDocument, keyData)
        ..update(
          _firestore.collection(_usersCollection).doc(_currentUserId),
          <String, dynamic>{_householdIdField: householdId},
        );
    });
  }

  UserDataCipher _requireDataCipher() {
    final dataCipher = _dataCipher;
    if (dataCipher == null || dataCipher.uid != _currentUserId) {
      throw const HouseholdKeyUnavailableException();
    }
    return dataCipher;
  }

  DocumentReference<Map<String, dynamic>> _inviteDocument(String code) {
    return _firestore.collection(_invitesCollection).doc(code);
  }

  Future<bool> _tryCreateInvite(
    String code,
    String householdId,
    String wrappedKey,
  ) {
    final inviteDocument = _inviteDocument(code);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inviteDocument);
      if (snapshot.exists) {
        return false;
      }
      transaction.set(inviteDocument, <String, dynamic>{
        _householdIdField: householdId,
        _expiresAtField: Timestamp.fromDate(_now().add(_inviteCodeLifetime)),
        _wrappedHouseholdKeyField: wrappedKey,
      });
      return true;
    });
  }

  String _generateRandomCode() {
    return _random.nextInt(1000000).toString().padLeft(6, '0');
  }
}

/// Household invite repository, or `null` while signed out or Firestore is
/// unavailable.
@riverpod
HouseholdInviteRepository? householdInviteRepository(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  final keys = ref.watch(householdKeyRepositoryProvider);
  final members = ref.watch(householdMemberRepositoryProvider);
  if (user == null || firestore == null || keys == null || members == null) {
    return null;
  }
  return HouseholdInviteRepository(
    firestore: firestore,
    keys: keys,
    members: members,
    currentUserId: user.uid,
    isAnonymous: user.isAnonymous,
    dataCipher: ref.watch(userDataCipherProvider),
    now: ref.watch(clockProvider),
  );
}
