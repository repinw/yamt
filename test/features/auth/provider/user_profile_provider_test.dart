import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/models/user_profile.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockUser extends Mock implements User {}

void main() {
  User buildUser({
    required String uid,
    required bool isAnonymous,
    String? email,
    String? displayName,
  }) {
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.isAnonymous).thenReturn(isAnonymous);
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(displayName);
    return user;
  }

  test('userProfileProvider creates and syncs the signed-in profile', () async {
    final firestore = FakeFirebaseFirestore();
    final user = buildUser(
      uid: 'user-1',
      isAnonymous: false,
      email: 'jane@example.com',
      displayName: 'Jane',
    );
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        firebaseFirestoreProvider.overrideWith((ref) => firestore),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(userProfileProvider, (_, _) {});
    addTearDown(subscription.close);

    final profile = await container.read(userProfileProvider.future);
    final snapshot = await firestore.collection('users').doc('user-1').get();

    expect(profile, isNotNull);
    expect(profile?.uid, 'user-1');
    expect(profile?.email, 'jane@example.com');
    expect(profile?.displayName, 'Jane');
    expect(profile?.isAnonymous, isFalse);
    expect(snapshot.data()?['uid'], 'user-1');
    expect(snapshot.data()?['email'], 'jane@example.com');
    expect(snapshot.data()?['displayName'], 'Jane');
  });

  test('householdMembersProvider returns the leader first', () async {
    final firestore = FakeFirebaseFirestore();
    final hostProfile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
      isAnonymous: false,
    );
    await firestore.collection('users').doc('host-1').set({
      'uid': 'host-1',
      'email': 'host@example.com',
      'displayName': 'Host',
      'isAnonymous': false,
    });
    await firestore.collection('users').doc('member-1').set({
      'uid': 'member-1',
      'email': 'member@example.com',
      'displayName': 'Member',
      'isAnonymous': false,
      'householdId': 'host-1',
    });

    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWith((ref) => firestore),
        userProfileProvider.overrideWith((ref) => Stream.value(hostProfile)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(householdMembersProvider, (_, _) {});
    addTearDown(subscription.close);

    final members = await container.read(householdMembersProvider.future);

    expect(members.map((member) => member.uid), ['host-1', 'member-1']);
  });

  test('householdMembersProvider returns only the standalone guest '
      'without querying members', () async {
    final firestore = FakeFirebaseFirestore();
    final guestProfile = UserProfile(uid: 'guest-1', isAnonymous: true);

    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWith((ref) => firestore),
        userProfileProvider.overrideWith((ref) => Stream.value(guestProfile)),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(householdMembersProvider, (_, _) {});
    addTearDown(subscription.close);

    final members = await container.read(householdMembersProvider.future);

    expect(members.map((member) => member.uid), ['guest-1']);
  });

  test('shouldIgnoreTransientHouseholdMemberPermissionDenied only ignores '
      'stale household roots', () {
    final permissionDenied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );

    expect(
      shouldIgnoreTransientHouseholdMemberPermissionDenied(
        error: permissionDenied,
        watchedHouseholdRootId: 'guest-1',
        latestProfile: const UserProfile(
          uid: 'guest-1',
          householdId: 'host-1',
          isAnonymous: true,
        ),
      ),
      isTrue,
    );

    expect(
      shouldIgnoreTransientHouseholdMemberPermissionDenied(
        error: permissionDenied,
        watchedHouseholdRootId: 'host-1',
        latestProfile: const UserProfile(
          uid: 'member-1',
          householdId: 'host-1',
          isAnonymous: false,
        ),
      ),
      isFalse,
    );
  });
}
