import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_profile_document_codec.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_member.dart';

part 'household_member_repository.g.dart';

const _householdsCollection = 'households';
const _membersCollection = 'members';
const _usersCollection = 'users';
const _uidField = 'uid';
const _roleField = 'role';
const _joinedAtField = 'joined_at';
const _inviteCodeField = 'invite_code';

/// Reads the members of a household and lets the admin change them.
///
/// A member document is `households/{householdId}/members/{uid}`. The name and
/// the e-mail address of a member come from the user profile.
class HouseholdMemberRepository {
  /// Creates the repository.
  const new({
    required this._firestore,
    required this._keys,
    required this._currentUserId,
  });

  final FirebaseFirestore _firestore;
  final HouseholdKeyRepository _keys;
  final String _currentUserId;

  /// The member document of [uid] in [householdId].
  DocumentReference<Map<String, dynamic>> memberDocument(
    String householdId,
    String uid,
  ) {
    return _members(householdId).doc(uid);
  }

  /// The data of a new member document for the current user.
  ///
  /// A member who joins names the [inviteCode], so the rules can check the
  /// invite.
  Map<String, dynamic> newMemberData(HouseholdRole role, {String? inviteCode}) {
    return <String, dynamic>{
      _uidField: _currentUserId,
      _roleField: role.name,
      _joinedAtField: FieldValue.serverTimestamp(),
      _inviteCodeField: ?inviteCode,
    };
  }

  /// Watches the members of [householdId] with their names, the admin first,
  /// then by the day they joined.
  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    return _members(householdId).snapshots().asyncMap((snapshot) async {
      final members = await Future.wait(
        snapshot.docs.map((document) => _withProfile(_parse(document))),
      );
      return members.sorted(_compareMembers);
    });
  }

  /// Loads the members of [householdId], without names.
  Future<List<HouseholdMember>> loadMembers(String householdId) async {
    final snapshot = await _members(householdId).get();
    return snapshot.docs.map(_parse).toList(growable: false);
  }

  /// Loads the current user's member entry in [householdId], or `null`.
  Future<HouseholdMember?> loadCurrentMember(String householdId) async {
    final snapshot = await memberDocument(householdId, _currentUserId).get();
    return snapshot.exists ? _parse(snapshot) : null;
  }

  /// Whether users other than the current one are members of [householdId].
  Future<bool> loadHasOtherMembers(String householdId) async {
    final members = await loadMembers(householdId);
    return members.any((member) => member.uid != _currentUserId);
  }

  /// Emits when the server reports that the current user is no longer a
  /// member of [householdId], for example after the admin removed them.
  Stream<void> watchMembershipEnded(String householdId) {
    return memberDocument(householdId, _currentUserId)
        .snapshots()
        .where((snapshot) => !snapshot.exists && !snapshot.metadata.isFromCache)
        .map((_) {});
  }

  /// Removes [memberUid] from [householdId]: their member entry, key entry
  /// and restore request. Only the admin may do this.
  Future<void> removeMember(String householdId, String memberUid) async {
    await _requireAdmin(householdId);
    await _requireOtherMember(householdId, memberUid);
    final batch = _firestore.batch()
      ..delete(memberDocument(householdId, memberUid))
      ..delete(_keys.keyDocument(householdId, memberUid))
      ..delete(_keys.restoreDocument(householdId, memberUid));
    await batch.commit();
  }

  /// Hands the lead of [householdId] to [memberUid]. The current admin stays
  /// as a member.
  Future<void> makeAdmin(String householdId, String memberUid) async {
    await _requireAdmin(householdId);
    await _requireOtherMember(householdId, memberUid);
    final batch = _firestore.batch()
      ..update(memberDocument(householdId, memberUid), <String, dynamic>{
        _roleField: HouseholdRole.admin.name,
      })
      ..update(memberDocument(householdId, _currentUserId), <String, dynamic>{
        _roleField: HouseholdRole.member.name,
      });
    await batch.commit();
  }

  Future<void> _requireAdmin(String householdId) async {
    final member = await loadCurrentMember(householdId);
    if (member == null || !member.isAdmin) {
      throw const HouseholdAdminRequiredException();
    }
  }

  Future<void> _requireOtherMember(String householdId, String memberUid) async {
    final snapshot = await memberDocument(householdId, memberUid).get();
    if (memberUid == _currentUserId || !snapshot.exists) {
      throw const HouseholdMemberNotFoundException();
    }
  }

  Future<HouseholdMember> _withProfile(HouseholdMember member) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .doc(member.uid)
        .get();
    final profile = decodeUserProfileDocument(
      snapshot.data() ?? const <String, dynamic>{},
      member.uid,
    );
    return member.copyWith(
      displayName: profile.displayName,
      email: profile.email,
    );
  }

  CollectionReference<Map<String, dynamic>> _members(String householdId) {
    return _firestore
        .collection(_householdsCollection)
        .doc(householdId)
        .collection(_membersCollection);
  }
}

HouseholdMember _parse(DocumentSnapshot<Map<String, dynamic>> document) {
  return HouseholdMember.fromJson(normalizeFirestoreJson(document.data()!));
}

int _compareMembers(HouseholdMember left, HouseholdMember right) {
  if (left.isAdmin != right.isAdmin) {
    return left.isAdmin ? -1 : 1;
  }
  return left.joinedAt.compareTo(right.joinedAt);
}

/// Household member repository, or `null` while signed out or Firestore is
/// unavailable.
@riverpod
HouseholdMemberRepository? householdMemberRepository(Ref ref) {
  final uid = ref.watch(
    authStateChangesProvider.select((user) => user.asData?.value?.uid),
  );
  final firestore = ref.watch(firebaseFirestoreProvider);
  final keys = ref.watch(householdKeyRepositoryProvider);
  if (uid == null || firestore == null || keys == null) {
    return null;
  }
  return HouseholdMemberRepository(
    firestore: firestore,
    keys: keys,
    currentUserId: uid,
  );
}
