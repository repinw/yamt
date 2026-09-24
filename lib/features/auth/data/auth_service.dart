import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_profile_document_codec.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';

part 'auth_service.g.dart';

const _usersCollection = 'users';

/// Firebase auth.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// Auth state changes.
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
}

/// User profile.
@Riverpod(keepAlive: true)
Stream<UserProfile?> userProfile(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (user == null || firestore == null) {
    return Stream<UserProfile?>.value(null);
  }

  final document = firestore.collection(_usersCollection).doc(user.uid);
  UserProfile? lastCommittedProfile;
  // Metadata changes report the moment the server commits a pending write.
  return document.snapshots(includeMetadataChanges: true).asyncMap((
    snapshot,
  ) async {
    final profile = await _syncUserProfile(document, snapshot, user);
    final hasPendingWrites = snapshot.metadata.hasPendingWrites;
    final visibleProfile = withCommittedHouseholdId(
      profile,
      hasPendingWrites: hasPendingWrites,
      lastCommittedProfile: lastCommittedProfile,
    );
    if (!hasPendingWrites) {
      lastCommittedProfile = profile;
    }
    return visibleProfile;
  });
}

Future<UserProfile> _syncUserProfile(
  DocumentReference<Map<String, dynamic>> document,
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  User user,
) async {
  final syncedProfile = UserProfile(
    uid: user.uid,
    householdId: householdIdFromUserProfileSnapshot(snapshot),
    email: normalizeOptionalUserProfileValue(user.email),
    displayName: normalizeOptionalUserProfileValue(user.displayName),
    isAnonymous: user.isAnonymous,
  );

  if (!snapshot.exists) {
    await document.set(syncedProfile.toJson(), SetOptions(merge: true));
    return syncedProfile;
  }

  final storedProfile = decodeUserProfileDocument(
    snapshot.data() ?? const <String, dynamic>{},
    snapshot.id,
  );
  if (storedProfile == syncedProfile) {
    return storedProfile;
  }

  await document.set(syncedProfile.toJson(), SetOptions(merge: true));
  return syncedProfile;
}
