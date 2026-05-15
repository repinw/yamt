import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/user_profile_document_codec.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';

void main() {
  test(
    'decodeUserProfileDocument falls back to document id and trims strings',
    () {
      final profile = decodeUserProfileDocument(
        const <String, dynamic>{
          'uid': '  ',
          'householdId': ' household-1 ',
          'email': ' jane@example.com ',
          'displayName': ' Jane ',
          'isAnonymous': true,
        },
        'user-1',
      );

      expect(profile.uid, 'user-1');
      expect(profile.householdId, 'household-1');
      expect(profile.email, 'jane@example.com');
      expect(profile.displayName, 'Jane');
      expect(profile.isAnonymous, isTrue);
    },
  );

  test(
    'householdIdFromUserProfileSnapshot normalizes missing and blank values',
    () async {
      final firestore = FakeFirebaseFirestore();
      final missing = await firestore.collection('users').doc('missing').get();
      await firestore.collection('users').doc('blank').set({
        'householdId': '  ',
      });
      final blank = await firestore.collection('users').doc('blank').get();

      expect(householdIdFromUserProfileSnapshot(missing), isNull);
      expect(householdIdFromUserProfileSnapshot(blank), isNull);
    },
  );

  test('isStandaloneGuestUserProfile detects guests without household', () {
    expect(
      isStandaloneGuestUserProfile(
        const UserProfile(uid: 'guest', isAnonymous: true),
      ),
      isTrue,
    );
    expect(
      isStandaloneGuestUserProfile(
        const UserProfile(
          uid: 'guest',
          householdId: 'household-1',
          isAnonymous: true,
        ),
      ),
      isFalse,
    );
    expect(
      isStandaloneGuestUserProfile(const UserProfile(uid: 'user')),
      isFalse,
    );
  });
}
