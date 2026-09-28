import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/user_profile_dto.dart';

void main() {
  test(
    'decodeUserProfileDocument falls back to document id and trims strings',
    () {
      final profile = decodeUserProfileDocument(const <String, dynamic>{
        'uid': '  ',
        'householdId': ' household-1 ',
        'ownHouseholdId': ' household-2 ',
        'email': ' jane@example.com ',
        'displayName': ' Jane ',
        'isAnonymous': true,
      }, 'user-1');

      expect(profile.uid, 'user-1');
      expect(profile.householdId, 'household-1');
      expect(profile.ownHouseholdId, 'household-2');
      expect(profile.email, 'jane@example.com');
      expect(profile.displayName, 'Jane');
      expect(profile.isAnonymous, isTrue);
    },
  );

  test('decodeUserProfileDocument leaves missing households empty', () {
    final profile = decodeUserProfileDocument(const <String, dynamic>{
      'householdId': '  ',
    }, 'user-1');

    expect(profile.householdId, isNull);
    expect(profile.ownHouseholdId, isNull);
  });
}
