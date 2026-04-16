import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/core/models/user_profile_document_codec.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';

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
  });
}
