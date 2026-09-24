import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('household key Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('only the member opens their key entry, the owner may delete it', () {
      expect(
        compactRules,
        contains(
          'match /users/{uid}/household_keys/{memberUid} { '
          'allow read: if isOwner(memberUid) '
          '&& canAccessHouseholdOwnedData(uid); '
          'allow create, update: if isOwner(memberUid) '
          '&& canAccessHouseholdOwnedData(uid) '
          "&& request.resource.data.keys().hasOnly(['wrapped_key']) "
          '&& request.resource.data.wrapped_key is string; '
          'allow delete: if isOwner(memberUid) || isOwner(uid); }',
        ),
      );
    });

    test('an invite must carry the wrapped household key', () {
      expect(
        compactRules,
        contains(
          "'wrapped_household_key', ]) "
          '&& request.resource.data.hostUid == request.auth.uid '
          '&& request.resource.data.expiresAt is timestamp '
          '&& request.resource.data.wrapped_household_key is string;',
        ),
      );
    });
  });
}
