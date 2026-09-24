import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('private data Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('private documents accept only an encrypted payload', () {
      expect(
        compactRules,
        contains(
          "data.keys().hasOnly(['payload'].concat(plaintextKeys)) "
          '&& data.payload is string',
        ),
      );
      expect(
        compactRules,
        contains(
          'match /users/{uid}/calorie_entries/{entryId} { '
          'allow read, delete: if isOwner(uid); '
          'allow create, update: if isOwner(uid) '
          "&& isEncryptedDocument(request.resource.data, ['logged_at']) "
          '&& request.resource.data.logged_at is timestamp; }',
        ),
      );
      for (final collection in <String>[
        'calorie_settings/{settingsId}',
        'health_weights/{weightId}',
        'calorie_product_overrides/{barcode}',
      ]) {
        expect(
          compactRules,
          contains(
            'match /users/{uid}/$collection { '
            'allow read, delete: if isOwner(uid); '
            'allow create, update: if isOwner(uid) '
            '&& isEncryptedDocument(request.resource.data, []); }',
          ),
          reason: collection,
        );
      }
    });

    test('the Burn Week state on the profile must be encrypted', () {
      expect(
        compactRules,
        contains(
          'function hasEncryptedRunState(data) { '
          "return isOptionalString(data, 'burn_week_run_state'); }",
        ),
      );
    });

    test('only the owner can use the key backup', () {
      expect(
        compactRules,
        contains(
          'match /users/{uid}/private/data_key { '
          'allow read, delete: if isOwner(uid); '
          'allow create, update: if isOwner(uid) '
          "&& request.resource.data.keys().hasOnly(['wrapped_key']) "
          '&& request.resource.data.wrapped_key is string; }',
        ),
      );
    });
  });
}
