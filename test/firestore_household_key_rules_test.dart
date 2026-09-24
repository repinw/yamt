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
            'match /users/{uid}/$collection { '
            'allow read, delete: if canAccessHouseholdOwnedData(uid); '
            'allow create, update: if canAccessHouseholdOwnedData(uid) '
            '&& isEncryptedDocument(request.resource.data, $keys); }',
          ),
          reason: collection,
        );
      }
      expect(
        compactRules,
        contains(
          'match /users/{uid}/inventory_activity_events/{eventId} { '
          'allow read: if canAccessHouseholdOwnedData(uid); '
          'allow create: if canAccessHouseholdOwnedData(uid) '
          "&& isEncryptedDocument(request.resource.data, ['happened_at']); "
          'allow update: if canAccessHouseholdOwnedData(uid) '
          "&& !('payload' in resource.data) "
          "&& isEncryptedDocument(request.resource.data, ['happened_at']); "
          'allow delete: if false; }',
        ),
      );
    });
  });
}
