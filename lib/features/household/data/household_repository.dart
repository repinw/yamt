import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_data_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_member.dart';

part 'household_repository.g.dart';

const _householdsCollection = 'households';
const _usersCollection = 'users';
const _createdAtField = 'created_at';
const _roleField = 'role';
const _uidField = 'uid';
const _householdIdField = 'householdId';
const _ownHouseholdIdField = 'ownHouseholdId';

typedef _NewHousehold = ({
  DocumentReference<Map<String, dynamic>> household,
  DocumentReference<Map<String, dynamic>> keyDocument,
  Map<String, dynamic> keyData,
});

/// Creates, leaves and wipes households, and switches the active household
/// of the current user.
///
/// Every user has an own household. Joining another one pauses it, leaving
/// goes back to it. A switch runs in a transaction, which writes nothing
/// locally before the server accepts it. So the profile never names a
/// household before the membership there exists.
class HouseholdRepository {
  /// Creates the repository.
  const new({
    required this._firestore,
    required this._data,
    required this._keys,
    required this._members,
    required this._currentUserId,
    required this._dataCipher,
  });

  final FirebaseFirestore _firestore;
  final HouseholdDataRepository _data;
  final HouseholdKeyRepository _keys;
  final HouseholdMemberRepository _members;
  final String _currentUserId;
  final UserDataCipher? _dataCipher;

  /// Creates the own household of the current user, with the user as admin
  /// and a new household key, unless the profile names one already.
  Future<void> createOwnHousehold() async {
    final household = await _prepareHousehold();
    await _firestore.runTransaction((transaction) async {
      final profile = await transaction.get(_userDocument);
      if (profile.data()?[_ownHouseholdIdField] is String) {
        return;
      }
      _writeHousehold(transaction, household, profileExists: profile.exists);
    });
  }

  /// Leaves [householdId] and goes back to the own household
  /// [ownHouseholdId].
  ///
  /// The admin hands the lead to [successorUid], or to the member who joined
  /// first. The last member deletes the household with all its data. A user
  /// who leaves the own household gets a new, empty one; the others keep
  /// everything. The transaction reads the members again, so a member who
  /// leaves or takes the lead at the same time changes the decision.
  ///
  /// Throws [HouseholdChangedException] when the user would be left alone,
  /// and [HouseholdMemberNotFoundException] when the successor left.
  Future<void> leaveHousehold({
    required String householdId,
    required String ownHouseholdId,
    String? successorUid,
  }) async {
    final members = await _members.loadMembers(householdId);
    if (!members.any((member) => member.uid == _currentUserId)) {
      throw const HouseholdMemberNotFoundException();
    }
    final isOwn = householdId == ownHouseholdId;
    if (members.length == 1) {
      if (isOwn) {
        throw StateError('Nobody else is in the own household.');
      }
      await _deleteHousehold(householdId, ownHouseholdId);
      return;
    }

    final newHousehold = isOwn ? await _prepareHousehold() : null;
    await _firestore.runTransaction((transaction) async {
      final successor = await _members.loadSuccessor(
        transaction,
        householdId,
        uids: {for (final member in members) member.uid, ?successorUid},
        successorUid: successorUid,
      );
      if (successor != null) {
        transaction.update(
          _members.memberDocument(householdId, successor),
          <String, dynamic>{_roleField: HouseholdRole.admin.name},
        );
      }
      _writeDeparture(transaction, householdId);
      if (newHousehold == null) {
        _writeActiveHousehold(transaction, ownHouseholdId);
      } else {
        _writeHousehold(transaction, newHousehold, profileExists: true);
      }
    });
  }

  /// Gives the user a new, empty own household when the membership in the
  /// own household [lostHouseholdId] ended, for example after the member who
  /// took over its lead removed the user. Does nothing while the membership
  /// stands or once the profile names another own household.
  Future<void> replaceOwnHousehold(String lostHouseholdId) async {
    final household = await _prepareHousehold();
    await _firestore.runTransaction((transaction) async {
      final profile = await transaction.get(_userDocument);
      final membership = await transaction.get(
        _members.memberDocument(lostHouseholdId, _currentUserId),
      );
      if (profile.data()?[_ownHouseholdIdField] != lostHouseholdId ||
          membership.exists) {
        return;
      }
      _writeHousehold(transaction, household, profileExists: true);
    });
  }

  /// Makes [ownHouseholdId] the active household again, for example after
  /// the admin of the shared household removed the user.
  Future<void> returnToOwnHousehold(String ownHouseholdId) {
    return _userDocument.set(<String, dynamic>{
      _uidField: _currentUserId,
      _householdIdField: ownHouseholdId,
    }, SetOptions(merge: true));
  }

  /// The last member deletes the household with everything in it.
  ///
  /// Deleting the household document closes the household: the rules let
  /// nobody join one without it. A member who joined before that stops the
  /// deletion: the household document comes back, the wiped data does not.
  Future<void> _deleteHousehold(
    String householdId,
    String ownHouseholdId,
  ) async {
    await _data.wipeHouseholdData(householdId);
    await _firestore.runTransaction((transaction) async {
      final current = await _members.loadMember(
        transaction,
        householdId,
        _currentUserId,
      );
      if (current == null) {
        throw const HouseholdMemberNotFoundException();
      }
      transaction.delete(_household(householdId));
    });
    final members = await _members.loadMembers(householdId);
    if (members.any((member) => member.uid != _currentUserId)) {
      await _household(
        householdId,
      ).set(<String, dynamic>{_createdAtField: FieldValue.serverTimestamp()});
      throw const HouseholdChangedException();
    }
    await _firestore.runTransaction((transaction) async {
      _writeDeparture(transaction, householdId);
      _writeActiveHousehold(transaction, ownHouseholdId);
    });
  }

  Future<_NewHousehold> _prepareHousehold() async {
    final dataCipher = _dataCipher;
    if (dataCipher == null || dataCipher.uid != _currentUserId) {
      throw const HouseholdKeyUnavailableException();
    }
    final household = _firestore.collection(_householdsCollection).doc();
    final keyDocument = _keys.keyDocument(household.id, _currentUserId);
    return (
      household: household,
      keyDocument: keyDocument,
      keyData: await _keys.wrapKey(
        keyDocument,
        await PayloadCipher.newDataKey(),
        dataCipher.cipher,
      ),
    );
  }

  void _writeHousehold(
    Transaction transaction,
    _NewHousehold household, {
    required bool profileExists,
  }) {
    final householdId = household.household.id;
    final profile = <String, dynamic>{
      _householdIdField: householdId,
      _ownHouseholdIdField: householdId,
    };
    transaction
      ..set(household.household, <String, dynamic>{
        _createdAtField: FieldValue.serverTimestamp(),
      })
      ..set(
        _members.memberDocument(householdId, _currentUserId),
        _members.newMemberData(HouseholdRole.admin),
      )
      ..set(household.keyDocument, household.keyData);
    if (profileExists) {
      transaction.update(_userDocument, profile);
    } else {
      transaction.set(_userDocument, <String, dynamic>{
        _uidField: _currentUserId,
        ...profile,
      });
    }
  }

  void _writeDeparture(Transaction transaction, String householdId) {
    transaction
      ..delete(_keys.keyDocument(householdId, _currentUserId))
      ..delete(_keys.restoreDocument(householdId, _currentUserId))
      ..delete(_members.memberDocument(householdId, _currentUserId));
  }

  void _writeActiveHousehold(Transaction transaction, String householdId) {
    transaction.update(_userDocument, <String, dynamic>{
      _householdIdField: householdId,
    });
  }

  DocumentReference<Map<String, dynamic>> _household(String householdId) {
    return _firestore.collection(_householdsCollection).doc(householdId);
  }

  DocumentReference<Map<String, dynamic>> get _userDocument {
    return _firestore.collection(_usersCollection).doc(_currentUserId);
  }
}

/// Household repository, or `null` while signed out or Firebase is
/// unavailable.
@riverpod
HouseholdRepository? householdRepository(Ref ref) {
  final uid = ref.watch(
    authStateChangesProvider.select((user) => user.asData?.value?.uid),
  );
  final firestore = ref.watch(firebaseFirestoreProvider);
  final data = ref.watch(householdDataRepositoryProvider);
  final keys = ref.watch(householdKeyRepositoryProvider);
  final members = ref.watch(householdMemberRepositoryProvider);
  if (uid == null ||
      firestore == null ||
      data == null ||
      keys == null ||
      members == null) {
    return null;
  }
  return HouseholdRepository(
    firestore: firestore,
    data: data,
    keys: keys,
    members: members,
    currentUserId: uid,
    dataCipher: ref.watch(userDataCipherProvider),
  );
}
