import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';

void main() {
  test('householdMembersProvider returns the leader first', () async {
    final firestore = FakeFirebaseFirestore();
    const hostProfile = UserProfile(
      uid: 'host-1',
      email: 'host@example.com',
      displayName: 'Host',
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
    const guestProfile = UserProfile(uid: 'guest-1', isAnonymous: true);

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
        ),
      ),
      isFalse,
    );
  });
}
