import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';

class _MockUser extends Mock implements User;

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

  Future<UserProfile?> readProfile(
    FakeFirebaseFirestore firestore,
    User user,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        firebaseFirestoreProvider.overrideWith((ref) => firestore),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(userProfileProvider, (_, _) {});
    addTearDown(subscription.close);
    return await container.read(userProfileProvider.future);
  }

  test('userProfileProvider creates and syncs the signed-in profile', () async {
    final firestore = FakeFirebaseFirestore();
    final user = buildUser(
      uid: 'user-1',
      isAnonymous: false,
      email: 'jane@example.com',
      displayName: 'Jane',
    );

    final profile = await readProfile(firestore, user);
    final snapshot = await firestore.collection('users').doc('user-1').get();

    expect(profile, isNotNull);
    expect(profile?.uid, 'user-1');
    expect(profile?.email, 'jane@example.com');
    expect(profile?.displayName, 'Jane');
    expect(profile?.isAnonymous, isFalse);
    expect(profile?.householdId, isNull);
    expect(snapshot.data(), <String, dynamic>{
      'uid': 'user-1',
      'email': 'jane@example.com',
      'displayName': 'Jane',
      'isAnonymous': false,
    });
  });

  test('userProfileProvider keeps the household fields when it syncs '
      'the account', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('user-1').set(<String, dynamic>{
      'uid': 'user-1',
      'displayName': 'Old name',
      'householdId': 'shared-1',
      'ownHouseholdId': 'own-1',
    });
    final user = buildUser(
      uid: 'user-1',
      isAnonymous: false,
      displayName: 'Jane',
    );

    final profile = await readProfile(firestore, user);
    final stored = (await firestore.doc('users/user-1').get()).data()!;

    expect(profile?.displayName, 'Jane');
    expect(profile?.householdId, 'shared-1');
    expect(profile?.ownHouseholdId, 'own-1');
    expect(stored['displayName'], 'Jane');
    expect(stored['householdId'], 'shared-1');
    expect(stored['ownHouseholdId'], 'own-1');
  });

  test(
    'userProfileProvider adds isAnonymous to a profile that lacks it',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.doc('users/user-1').set(<String, dynamic>{
        'uid': 'user-1',
        'email': null,
        'displayName': null,
      });
      final user = buildUser(uid: 'user-1', isAnonymous: false);

      await readProfile(firestore, user);
      await pumpEventQueue();

      final stored = (await firestore.doc('users/user-1').get()).data()!;
      expect(stored['isAnonymous'], isFalse);
    },
  );
}
