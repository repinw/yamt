import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';

class _MockUser extends Mock implements User;

const _userId = 'user-1';
const _householdId = 'household-1';

/// Overrides for the data layer only: a signed-in user whose household has
/// [memberCount] members in a fake Firestore. The real household providers
/// read the members from it as an asynchronous stream, so `shared` is
/// derived and never overridden.
List<Override> householdMembersOverrides({required int memberCount}) {
  final firestore = FakeFirebaseFirestore();
  final user = _MockUser();
  when(() => user.uid).thenReturn(_userId);
  Future<void> addMembers() async {
    for (var i = 0; i < memberCount; i++) {
      final uid = i == 0 ? _userId : 'member-$i';
      await firestore.doc('households/$_householdId/members/$uid').set(
        <String, dynamic>{
          'uid': uid,
          'role': i == 0 ? 'admin' : 'member',
          'joined_at': Timestamp.fromDate(DateTime(2026, 1 + i)),
        },
      );
    }
  }

  return [
    firebaseFirestoreProvider.overrideWith((ref) {
      return firestore;
    }),
    authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
    userProfileProvider.overrideWith((ref) async* {
      await addMembers();
      yield const UserProfile(uid: _userId, householdId: _householdId);
    }),
  ];
}
