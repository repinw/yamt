import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('global catalog author Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('new documents must name the current user as author', () {
      expect(
        compactRules,
        contains(
          'function isCreatedByCurrentUser(data) { '
          "return data.get('created_by_uid', null) == request.auth.uid; }",
        ),
      );
      expect(
        RegExp(r'isCreatedByCurrentUser\(request\.resource\.data\)')
            .allMatches(compactRules),
        hasLength(4),
      );
    });

    test('updates keep the author', () {
      expect(
        compactRules,
        contains(
          "return next.get('created_by_uid', null) "
          "== current.get('created_by_uid', null); }",
        ),
      );
      expect(
        RegExp(r'keepsAuthor\(request\.resource\.data, resource\.data\)')
            .allMatches(compactRules),
        hasLength(2),
      );
    });

    test('all four global catalog documents allow the author field', () {
      expect(
        RegExp(r"isOptionalString\(data, 'created_by_uid'\)")
            .allMatches(compactRules),
        hasLength(4),
      );
    });
  });
}
