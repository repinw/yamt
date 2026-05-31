import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('serving suggestion Firestore rules', () {
    late String rules;
    late String compactRules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
      compactRules = _compact(rules);
    });

    test('allow global ids, fingerprints, and optional labels', () {
      expect(compactRules, contains("'global_food_item_id'"));
      expect(compactRules, contains("'food_fingerprint'"));
      expect(compactRules, contains("'label'"));
      expect(compactRules, contains("isOptionalString(data, 'label')"));
      expect(
        compactRules,
        contains(
          <String>[
            r'exists( /databases/$(database)/documents/',
            r'global_food_items/$(data.global_food_item_id) )',
          ].join(),
        ),
      );
    });

    test('require either global id or fingerprint for shared suggestions', () {
      expect(
        compactRules,
        contains(
          'data.global_food_item_id is string && '
          'data.global_food_item_id.size() > 0',
        ),
      );
      expect(
        compactRules,
        contains(
          'data.food_fingerprint is string && '
          'data.food_fingerprint.size() > 0',
        ),
      );
      expect(
        compactRules,
        contains(
          "data.keys().hasAll([ 'id', 'item_key', 'amount', "
          "'unit', 'selection_count', 'unique_user_count'",
        ),
      );
    });

    test('lock shared identity fields on update with safe map access', () {
      expect(
        compactRules,
        contains(
          "request.resource.data.get('global_food_item_id', null) "
          "== resource.data.get('global_food_item_id', null)",
        ),
      );
      expect(
        compactRules,
        contains(
          "request.resource.data.get('food_fingerprint', null) "
          "== resource.data.get('food_fingerprint', null)",
        ),
      );
      expect(
        compactRules,
        contains(
          "request.resource.data.get('label', null) "
          "== resource.data.get('label', null)",
        ),
      );
    });
  });

  test('serving suggestion global query has matching composite index', () {
    final rawIndexes =
        jsonDecode(
              File('firestore.indexes.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final indexes = rawIndexes['indexes'] as List<dynamic>;

    final servingIndex = indexes.cast<Map<String, dynamic>>().singleWhere(
      (index) {
        return index['collectionGroup'] == 'global_food_item_serving_sizes';
      },
    );

    expect(servingIndex['queryScope'], 'COLLECTION');
    expect(
      servingIndex['fields'],
      <Map<String, String>>[
        {'fieldPath': 'item_key', 'order': 'ASCENDING'},
        {'fieldPath': 'unique_user_count', 'order': 'DESCENDING'},
        {'fieldPath': 'selection_count', 'order': 'DESCENDING'},
        {'fieldPath': 'updated_at', 'order': 'DESCENDING'},
      ],
    );
  });
}

String _compact(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
