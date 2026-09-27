import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Checked against the Firestore emulator on 2026-09-27 (19 cases: counters,
// votes, older aliases, older app versions). These tests keep the key parts
// from being dropped by accident.
void main() {
  group('receipt alias vote Firestore rules', () {
    late String compactRules;

    setUpAll(() {
      compactRules = File('firestore.rules')
          .readAsStringSync()
          .replaceAll(RegExp(r'\s+'), ' ');
    });

    test('a save changes only the counters and the time', () {
      expect(
        compactRules,
        contains(
          'return next.diff(current).affectedKeys().hasOnly([ '
          "'selection_count', 'unique_user_count', 'updated_at', ])",
        ),
      );
      expect(
        compactRules,
        contains('&& next.selection_count == current.selection_count + 1'),
      );
    });

    test('a new user needs a first vote in the same write', () {
      expect(
        compactRules,
        contains(
          '&& !exists(votePath) && existsAfter(votePath) '
          "&& current.get('created_by_uid', null) != request.auth.uid",
        ),
      );
    });

    test('votes cannot be deleted', () {
      final voteRules = RegExp(
        r'match /users/\{uid\}/global_food_item_receipt_alias_votes/'
        r'\{aliasId\} \{.*?allow delete: if (\w+);',
      ).firstMatch(compactRules);
      expect(voteRules, isNotNull);
      expect(voteRules!.group(1), 'false');
    });
  });
}
