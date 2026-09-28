import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/user_profile_dto.dart';
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
  return document.snapshots().asyncMap(
    (snapshot) => _syncUserProfile(document, snapshot, user),
  );
}

/// Keeps the account fields of the profile in line with [user].
///
/// Writes only the fields that the account owns. The household fields belong
/// to the household feature, which switches them in transactions.
Future<UserProfile> _syncUserProfile(
  DocumentReference<Map<String, dynamic>> document,
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  User user,
) async {
  final storedProfile = decodeUserProfileDocument(
    snapshot.data() ?? const <String, dynamic>{},
    snapshot.id,
  );
  final syncedProfile = storedProfile.copyWith(
    uid: user.uid,
    email: normalizeOptionalUserProfileValue(user.email),
    displayName: normalizeOptionalUserProfileValue(user.displayName),
    isAnonymous: user.isAnonymous,
  );
  if (snapshot.exists && storedProfile == syncedProfile) {
    return storedProfile;
  }

  await document.set(<String, dynamic>{
    'uid': syncedProfile.uid,
    'email': syncedProfile.email,
    'displayName': syncedProfile.displayName,
    'isAnonymous': syncedProfile.isAnonymous,
  }, SetOptions(merge: true));
  return syncedProfile;
}
