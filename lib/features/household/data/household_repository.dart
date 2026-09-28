import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
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
const _maxBatchSize = 400;

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
    required this._storage,
    required this._keys,
    required this._members,
    required this._currentUserId,
    required this._dataCipher,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
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
  /// everything.
  Future<void> leaveHousehold({
    required String householdId,
    required String ownHouseholdId,
    String? successorUid,
  }) async {
    final members = await _members.loadMembers(householdId);
    final current = members.firstWhereOrNull(
      (member) => member.uid == _currentUserId,
    );
    if (current == null) {
      throw const HouseholdMemberNotFoundException();
    }
    final others = members
        .where((member) => member.uid != _currentUserId)
        .toList(growable: false);
    final isOwn = householdId == ownHouseholdId;
    if (others.isEmpty) {
      if (isOwn) {
        throw StateError('Nobody else is in the own household.');
      }
      await _deleteHousehold(householdId, ownHouseholdId);
      return;
    }

    final successor = current.isAdmin ? _successor(others, successorUid) : null;
    final newHousehold = isOwn ? await _prepareHousehold() : null;
    await _firestore.runTransaction((transaction) async {
      if (successor != null) {
        transaction.update(
          _members.memberDocument(householdId, successor.uid),
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

  /// Makes [ownHouseholdId] the active household again, for example after
  /// the admin of the shared household removed the user.
  Future<void> returnToOwnHousehold(String ownHouseholdId) {
    return _userDocument.set(<String, dynamic>{
      _uidField: _currentUserId,
      _householdIdField: ownHouseholdId,
    }, SetOptions(merge: true));
  }

  /// Deletes the documents and images of [householdId]. The household, its
  /// members and their key entries stay.
  Future<void> wipeHouseholdData(String householdId) async {
    final references = <DocumentReference<Map<String, dynamic>>>[];
    for (final collection in householdEncryptedCollections.keys) {
      final snapshot = await _household(householdId)
          .collection(collection)
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
      await _deleteFolder(
        _storage.ref('$_householdsCollection/$householdId/$folder'),
      );
    }
  }

  /// The last member deletes the household with everything in it.
  Future<void> _deleteHousehold(
    String householdId,
    String ownHouseholdId,
  ) async {
    await wipeHouseholdData(householdId);
    await _firestore.runTransaction((transaction) async {
      _writeDeparture(transaction, householdId);
      transaction.delete(_household(householdId));
      _writeActiveHousehold(transaction, ownHouseholdId);
    });
  }

  HouseholdMember _successor(
    List<HouseholdMember> others,
    String? successorUid,
  ) {
    if (successorUid == null) {
      return proposeSuccessor(others, _currentUserId)!;
    }
    return others.firstWhereOrNull((member) => member.uid == successorUid) ??
        (throw const HouseholdMemberNotFoundException());
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

  Future<void> _deleteFolder(Reference folder) async {
    final result = await folder.listAll();
    for (final item in result.items) {
      await item.delete();
    }
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
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
  final storage = ref.watch(firebaseStorageProvider);
  final keys = ref.watch(householdKeyRepositoryProvider);
  final members = ref.watch(householdMemberRepositoryProvider);
  if (uid == null ||
      firestore == null ||
      storage == null ||
      keys == null ||
      members == null) {
    return null;
  }
  return HouseholdRepository(
    firestore: firestore,
    storage: storage,
    keys: keys,
    members: members,
    currentUserId: uid,
    dataCipher: ref.watch(userDataCipherProvider),
  );
}
