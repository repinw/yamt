import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/core/models/user_profile_document_codec.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/provider/'
    'household_permission_recovery.dart';

part 'household_members_provider.g.dart';

const _usersCollection = 'users';
const _householdMembersLogName = 'HouseholdMembersProvider';

@riverpod
Stream<List<UserProfile>> householdMembers(Ref ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (profile == null || firestore == null) {
    return Stream<List<UserProfile>>.value(const <UserProfile>[]);
  }

  if (isStandaloneGuestUserProfile(profile)) {
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
            decodeUserProfileDocument(
              hostSnapshot!.data() ?? const <String, dynamic>{},
              hostSnapshot!.id,
            ),
          ...memberSnapshot!.docs
              .map((doc) => decodeUserProfileDocument(doc.data(), doc.id))
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
            decodeUserProfileDocument(
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
