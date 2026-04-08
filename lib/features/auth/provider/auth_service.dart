import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/household/provider/'
    'household_permission_recovery.dart';

part 'auth_service.g.dart';

const _usersCollection = 'users';
const _householdMembersLogName = 'HouseholdMembersProvider';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
}

@riverpod
Stream<UserProfile?> userProfile(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (user == null || firestore == null) {
    return Stream<UserProfile?>.value(null);
  }

  final document = firestore.collection(_usersCollection).doc(user.uid);
  return document.snapshots().asyncMap((snapshot) async {
    final syncedProfile = UserProfile(
      uid: user.uid,
      householdId: _householdIdFromSnapshot(snapshot),
      email: _normalizeOptional(user.email),
      displayName: _normalizeOptional(user.displayName),
      isAnonymous: user.isAnonymous,
    );

    if (!snapshot.exists) {
      await document.set(syncedProfile.toJson(), SetOptions(merge: true));
      return syncedProfile;
    }

    final storedProfile = _decodeUserProfile(
      snapshot.data() ?? const <String, dynamic>{},
      snapshot.id,
    );
    if (storedProfile == syncedProfile) {
      return storedProfile;
    }

    await document.set(syncedProfile.toJson(), SetOptions(merge: true));
    return syncedProfile;
  });
}

@riverpod
Stream<List<UserProfile>> householdMembers(Ref ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (profile == null || firestore == null) {
    return Stream<List<UserProfile>>.value(const <UserProfile>[]);
  }

  if (_isStandaloneGuestProfile(profile)) {
    log(
      'Skipping household member query for standalone guest user '
      '${profile.uid}.',
      name: _householdMembersLogName,
    );
    return Stream<List<UserProfile>>.value(<UserProfile>[profile]);
  }

  final householdRootId = householdRootIdForProfile(profile) ?? profile.uid;
  final users = firestore.collection(_usersCollection);
  return Stream<List<UserProfile>>.multi((controller) {
    DocumentSnapshot<Map<String, dynamic>>? hostSnapshot;
    QuerySnapshot<Map<String, dynamic>>? memberSnapshot;
    var lastEmittedMembers = <UserProfile>[profile];

    void emitMembers() {
      if (hostSnapshot == null || memberSnapshot == null) {
        return;
      }

      final members = _sortHouseholdMembers(
        householdRootId: householdRootId,
        members: <UserProfile>[
          if (hostSnapshot!.exists)
            _decodeUserProfile(
              hostSnapshot!.data() ?? const <String, dynamic>{},
              hostSnapshot!.id,
            ),
          ...memberSnapshot!.docs
              .map((doc) => _decodeUserProfile(doc.data(), doc.id))
              .where((member) => member.uid != householdRootId),
        ],
      );
      lastEmittedMembers = members;
      controller.add(members);
    }

    void emitFallbackMembers({
      required Object error,
      required String source,
      StackTrace? stackTrace,
    }) {
      if (!shouldIgnoreTransientHouseholdMemberPermissionDenied(
        error: error,
        watchedHouseholdRootId: householdRootId,
        latestProfile: ref.read(userProfileProvider).asData?.value,
      )) {
        controller.addError(error, stackTrace);
        return;
      }

      final fallbackMembers = _sortHouseholdMembers(
        householdRootId: householdRootId,
        members: <UserProfile>[
          if (hostSnapshot?.exists ?? false)
            _decodeUserProfile(
              hostSnapshot!.data() ?? const <String, dynamic>{},
              hostSnapshot!.id,
            ),
          ...lastEmittedMembers,
          profile,
        ],
      );
      lastEmittedMembers = fallbackMembers;
      log(
        'Ignoring transient household member permission denial for '
        'user ${profile.uid} at root $householdRootId from $source.',
        name: _householdMembersLogName,
        error: error,
        stackTrace: stackTrace,
      );
      controller.add(fallbackMembers);
    }

    final hostSubscription = users
        .doc(householdRootId)
        .snapshots()
        .listen(
          (snapshot) {
            hostSnapshot = snapshot;
            emitMembers();
          },
          onError: (Object error, StackTrace stackTrace) {
            emitFallbackMembers(
              error: error,
              source: 'host',
              stackTrace: stackTrace,
            );
          },
        );
    final memberSubscription = users
        .where('householdId', isEqualTo: householdRootId)
        .snapshots()
        .listen(
          (snapshot) {
            memberSnapshot = snapshot;
            emitMembers();
          },
          onError: (Object error, StackTrace stackTrace) {
            emitFallbackMembers(
              error: error,
              source: 'members',
              stackTrace: stackTrace,
            );
          },
        );

    controller.onCancel = () {
      unawaited(hostSubscription.cancel());
      unawaited(memberSubscription.cancel());
    };
  });
}

List<UserProfile> _sortHouseholdMembers({
  required String householdRootId,
  required List<UserProfile> members,
}) {
  final membersByUid = <String, UserProfile>{
    for (final member in members) member.uid: member,
  };
  final sortedMembers = membersByUid.values.toList(growable: false);
  sortedMembers.sort((left, right) {
    final leftRank = left.uid == householdRootId ? 0 : 1;
    final rightRank = right.uid == householdRootId ? 0 : 1;
    if (leftRank != rightRank) {
      return leftRank.compareTo(rightRank);
    }
    final leftName = (left.displayName ?? left.email ?? left.uid).toLowerCase();
    final rightName = (right.displayName ?? right.email ?? right.uid)
        .toLowerCase();
    return leftName.compareTo(rightName);
  });
  return sortedMembers;
}

bool _isPermissionDenied(Object error) {
  return error is FirebaseException && error.code == 'permission-denied';
}

@visibleForTesting
bool shouldIgnoreTransientHouseholdMemberPermissionDenied({
  required Object error,
  required String watchedHouseholdRootId,
  required UserProfile? latestProfile,
}) {
  if (!_isPermissionDenied(error)) {
    return false;
  }

  return hasWatchedHouseholdRootChanged(
    watchedHouseholdRootId: watchedHouseholdRootId,
    latestProfile: latestProfile,
  );
}

UserProfile _decodeUserProfile(Map<String, dynamic> data, String documentId) {
  final normalizedData = Map<String, dynamic>.from(data);
  final uid =
      _normalizeOptional(normalizedData['uid'] as String?) ?? documentId;
  normalizedData['uid'] = uid;
  normalizedData['householdId'] = _normalizeOptional(
    normalizedData['householdId'] as String?,
  );
  normalizedData['email'] = _normalizeOptional(
    normalizedData['email'] as String?,
  );
  normalizedData['displayName'] = _normalizeOptional(
    normalizedData['displayName'] as String?,
  );
  return UserProfile.fromJson(normalizedData);
}

String? _householdIdFromSnapshot(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  return _normalizeOptional(snapshot.data()?['householdId'] as String?);
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

bool _isStandaloneGuestProfile(UserProfile profile) {
  return profile.isAnonymous && _normalizeOptional(profile.householdId) == null;
}
