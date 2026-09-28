import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('household image Storage rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('storage.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('membership is the member entry in the household', () {
      expect(
        compactRules,
        contains(
          <String>[
            'function isHouseholdMember(householdId) { return isSignedIn() ',
            '&& firestore.exists( /databases/(default)/documents/households/',
            r'$(householdId)/members/$(request.auth.uid) ); }',
          ].join(),
        ),
      );
    });

    test('members use the images of their household', () {
      expect(
        compactRules,
        contains(
          <String>[
            'match /households/{householdId}/kitchen_utensils/{utensilId}/',
            'images/{imageId} { ',
            'allow read, delete: if isHouseholdMember(householdId); ',
            'allow create, update: if isHouseholdMember(householdId) ',
            '&& isKitchenUtensilImage(); }',
          ].join(),
        ),
      );
      expect(
        compactRules,
        contains(
          'match /households/{householdId}/recipes/{mealId}/images/{imageId} '
          '{ allow read, delete: if isHouseholdMember(householdId); '
          'allow create, update: if isHouseholdMember(householdId) '
          '&& isRecipeImage(); }',
        ),
      );
      expect(
        compactRules,
        contains(
          'match /households/{householdId}/{folder}/{allPaths=**} { '
          'allow list: if isHouseholdMember(householdId) '
          "&& folder in ['kitchen_utensils', 'recipes']; }",
        ),
      );
    });

    test('household images no longer live under the user', () {
      expect(compactRules, isNot(contains('match /users/{uid}/')));
    });
  });
}
