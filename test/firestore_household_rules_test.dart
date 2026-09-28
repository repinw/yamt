import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('household Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('membership is the member entry in the household', () {
      expect(
        compactRules,
        contains(
          <String>[
            'function isHouseholdMember(householdId) { return isSignedIn() ',
            r'&& exists(/databases/$(database)/documents/households/',
            r'$(householdId)/members/$(request.auth.uid)); }',
          ].join(),
        ),
      );
      expect(
        compactRules,
        contains(
          'function isHouseholdAdmin(householdId) { '
          'return isHouseholdMember(householdId) '
          '&& get(memberPath(householdId, request.auth.uid)).data.role '
          "== 'admin'; }",
        ),
      );
    });

    test('a user creates a household only with their admin entry, '
        'and no client deletes one', () {
      expect(
        compactRules,
        contains(
          'match /households/{householdId} { '
          'allow read: if isHouseholdMember(householdId);',
        ),
      );
      expect(
        compactRules,
        contains(
          'allow create: if isSignedIn() '
          "&& request.resource.data.keys().hasOnly(['created_at']) "
          '&& request.resource.data.created_at == request.time '
          '&& getAfter(memberPath(householdId, request.auth.uid)).data.role '
          "== 'admin';",
        ),
      );
      expect(
        compactRules,
        contains(
          'names a new admin when none is left. allow delete: if false;',
        ),
      );
      expect(
        compactRules,
        contains(
          "&& request.resource.data.role == 'admin' "
          '&& request.resource.data.joined_at == request.time '
          '&& !exists(householdPath(householdId)) '
          '&& existsAfter(householdPath(householdId));',
        ),
      );
    });

    test('everybody else joins as a member with an invite and uses it up', () {
      expect(
        compactRules,
        contains(
          "&& request.resource.data.role == 'member' "
          '&& request.resource.data.joined_at == request.time '
          '&& request.resource.data.invite_code is string '
          '&& isValidInvite(request.resource.data.invite_code, householdId) '
          '&& !existsAfter(invitePath(request.resource.data.invite_code)) '
          '&& exists(householdPath(householdId));',
        ),
      );
      expect(
        compactRules,
        contains(
          'The user who joins with the invite uses it up in the same write. '
          'allow delete: if isSignedIn() '
          '&& !exists(memberPath(resource.data.householdId, '
          'request.auth.uid)) '
          '&& getAfter(memberPath(resource.data.householdId, '
          'request.auth.uid)) '
          ".data.get('invite_code', null) == code;",
        ),
      );
      expect(
        compactRules,
        contains(
          '&& invite.data.householdId == householdId '
          '&& invite.data.expiresAt > request.time;',
        ),
      );
    });

    test('only the admin changes roles, and hands the lead on whole', () {
      expect(
        compactRules,
        contains(
          'allow update: if isHouseholdAdmin(householdId) '
          '&& request.resource.data.diff(resource.data).affectedKeys() '
          ".hasOnly(['role']) "
          "&& request.resource.data.role in ['admin', 'member'] "
          "&& ( request.resource.data.role == 'member' "
          '|| !existsAfter(memberPath(householdId, request.auth.uid)) '
          '|| getAfter(memberPath(householdId, request.auth.uid)).data.role '
          "== 'member' );",
        ),
      );
      expect(
        compactRules,
        contains(
          'A member leaves, the admin removes members. '
          'allow delete: if isOwner(uid) || isHouseholdAdmin(householdId); }',
        ),
      );
    });

    test('only the member opens their key entry', () {
      expect(
        compactRules,
        contains(
          'match /keys/{uid} { '
          'allow read: if isOwner(uid) && isHouseholdMember(householdId); '
          'allow create, update: if isOwner(uid) '
          '&& isHouseholdMemberAfter(householdId) '
          "&& request.resource.data.keys().hasOnly(['wrapped_key']) "
          '&& request.resource.data.wrapped_key is string; '
          'allow delete: if isOwner(uid) || isHouseholdAdmin(householdId); }',
        ),
      );
    });

    test('a member who lost the key asks, the others answer', () {
      expect(
        compactRules,
        contains(
          'match /key_restores/{uid} { '
          'allow read: if isHouseholdMember(householdId); '
          'allow create, update: if isOwner(uid) '
          '&& isHouseholdMember(householdId) '
          '&& request.resource.data.keys().size() == 0; '
          'allow update: if isHouseholdMember(householdId) '
          '&& !isOwner(uid) '
          "&& request.resource.data.keys().hasOnly(['wrapped_household_key']) "
          '&& request.resource.data.wrapped_household_key is string; '
          'allow delete: if isOwner(uid) || isHouseholdAdmin(householdId); }',
        ),
      );
    });

    test('only the admin invites, and nobody lists invites', () {
      expect(
        compactRules,
        contains(
          'match /household_invites/{code} { '
          'allow get: if isSignedIn(); '
          'allow create: if isVerifiedAccount() '
          r"&& code.matches('^[A-Za-z0-9]{20}$')",
        ),
      );
      expect(
        compactRules,
        contains(
          '&& request.resource.data.householdId is string '
          '&& isHouseholdAdmin(request.resource.data.householdId) '
          '&& request.resource.data.expiresAt is timestamp',
        ),
      );
    });

    test('household documents accept only an encrypted payload', () {
      const collections = <String, String>{
        'inventory_items/{itemId}':
            "['entry_date', 'origin', 'is_deposit', 'is_discount']",
        'shopping_list_items/{itemId}': '[]',
        'prepared_meals/{mealId}': '[]',
        'prepared_meal_templates/{templateId}': '[]',
        'kitchen_utensils/{utensilId}': '[]',
        'inventory_discard_events/{eventId}': "['discarded_at']",
      };
      for (final MapEntry(key: collection, value: keys)
          in collections.entries) {
        expect(
          compactRules,
          contains(
            'match /$collection { '
            'allow read, delete: if isHouseholdMember(householdId); '
            'allow create, update: if isHouseholdMember(householdId) '
            '&& isEncryptedDocument(request.resource.data, $keys); }',
          ),
          reason: collection,
        );
      }
      expect(
        compactRules,
        contains(
          'match /inventory_activity_events/{eventId} { '
          'allow read: if isHouseholdMember(householdId); '
          'allow create: if isHouseholdMember(householdId) '
          "&& isEncryptedDocument(request.resource.data, ['happened_at']); "
          'allow update: if isHouseholdMember(householdId) '
          "&& !('payload' in resource.data) "
          "&& isEncryptedDocument(request.resource.data, ['happened_at']); "
          'allow delete: if isHouseholdAdmin(householdId); }',
        ),
      );
    });

    test('members read the profiles of their co-members', () {
      expect(
        compactRules,
        contains(
          'function canReadUserDocument(uid) { '
          'return isOwner(uid) || (isSignedIn() && isActiveCoMember(uid)); }',
        ),
      );
    });

    test('the generic userId rule stays out of households and invites', () {
      expect(
        compactRules,
        contains(
          'function isOutsideHouseholds(path) { '
          "return !(path[0] in ['households', 'household_invites']); }",
        ),
      );
      expect(
        compactRules,
        contains(
          'return invite.data.keys().hasOnly([ '
          "'householdId', 'expiresAt', 'wrapped_household_key', ]) "
          '&& invite.data.householdId == householdId',
        ),
      );
      expect(
        RegExp(r'isOutsideHouseholds\(document\)').allMatches(compactRules),
        hasLength(2),
      );
    });

    test('household data no longer lives under the user', () {
      for (final collection in <String>[
        'inventory_items',
        'shopping_list_items',
        'prepared_meals',
        'prepared_meal_templates',
        'kitchen_utensils',
        'inventory_discard_events',
        'inventory_activity_events',
        'household_keys',
      ]) {
        expect(
          compactRules,
          isNot(contains('match /users/{uid}/$collection')),
          reason: collection,
        );
      }
      expect(compactRules, isNot(contains('household_key_restores')));
    });
  });
}
