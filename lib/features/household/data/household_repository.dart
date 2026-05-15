import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
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

  if (user == null || firestore == null) {
    throw StateError('Household sharing requires an authenticated user.');
  }

  return HouseholdRepository(
    firestore: firestore,
    currentUserId: user.uid,
    isAnonymous: user.isAnonymous,
    currentHouseholdId: profile?.householdId,
  );
}

/// Defines household repository.
class HouseholdRepository {
  /// Creates an instance.
  HouseholdRepository({
    required FirebaseFirestore firestore,
    required String currentUserId,
    required bool isAnonymous,
    required String? currentHouseholdId,
    Random? random,
  }) : _firestore = firestore,
       _currentUserId = currentUserId,
       _isAnonymous = isAnonymous,
       _currentHouseholdId = _normalizeOptional(currentHouseholdId),
       _random = random ?? Random.secure();

  static const _fieldUid = 'uid';
  static const _fieldHouseholdId = 'householdId';
  static const _fieldHostUid = 'hostUid';
  static const _fieldExpiresAt = 'expiresAt';

  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final bool _isAnonymous;
  final String? _currentHouseholdId;
  final Random _random;

  /// Generate invite code.
  Future<String> generateInviteCode() async {
    _assertVerifiedLeader();

    for (
      var attempt = 0;
      attempt < _maxInviteCodeGenerationAttempts;
      attempt += 1
    ) {
      final code = _generateRandomCode();
      final created = await _tryCreateInviteCode(code);
      if (created) {
        return code;
      }
    }

    throw const HouseholdInviteCodeGenerationFailedException();
  }

  /// Join household.
  Future<void> joinHousehold(String code) async {
    if (_currentHouseholdId != null) {
      throw const HouseholdLeaveRequiredException();
    }

    final normalizedCode = code.trim();
    final snapshot = await _inviteDocument(normalizedCode).get();
    if (!snapshot.exists) {
      throw const InvalidHouseholdInviteCodeException();
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final expiresAt = data[_fieldExpiresAt];
    final hostUid = _normalizeOptional(data[_fieldHostUid] as String?);

    if (expiresAt is! Timestamp || hostUid == null) {
      throw const InvalidHouseholdInviteCodeException();
    }
    if (!DateTime.now().isBefore(expiresAt.toDate())) {
      throw const ExpiredHouseholdInviteCodeException();
    }
    if (hostUid == _currentUserId) {
      throw const OwnHouseholdInviteCodeException();
    }

    await _userDocument(_currentUserId).set(<String, dynamic>{
      _fieldUid: _currentUserId,
      _fieldHouseholdId: hostUid,
    }, SetOptions(merge: true));
  }

  /// Leave household.
  Future<void> leaveHousehold() {
    if (_currentHouseholdId == null) {
      throw const HouseholdMembershipRequiredException();
    }

    return _userDocument(_currentUserId).set(<String, dynamic>{
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

    await _userDocument(normalizedUserId).set(<String, dynamic>{
      _fieldHouseholdId: FieldValue.delete(),
    }, SetOptions(merge: true));
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

  Future<bool> _tryCreateInviteCode(String code) {
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
