import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app version Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('every client reads the version config and no client writes it', () {
      expect(
        compactRules,
        contains(
          'match /config/app_version { '
          'allow read: if true; allow write: if false; }',
        ),
      );
    });

    test('a user writes only the version fields of their own devices', () {
      expect(
        compactRules,
        contains(
          'match /users/{uid}/clients/{installId} { '
          'allow read, delete: if isOwner(uid); '
          'allow create, update: if isOwner(uid) '
          '&& request.resource.data.keys() '
          ".hasOnly(['app_version', 'platform', 'last_seen_at']) "
          '&& request.resource.data.app_version is string '
          '&& request.resource.data.app_version.size() <= 32 '
          '&& request.resource.data.platform is string '
          '&& request.resource.data.platform.size() <= 16 '
          '&& request.resource.data.last_seen_at is timestamp; }',
        ),
      );
    });
  });
}
