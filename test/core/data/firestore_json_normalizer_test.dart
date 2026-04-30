import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';

void main() {
  group('normalizeFirestoreJson', () {
    test('converts timestamps and nested values recursively', () {
      final createdAt = DateTime(2026, 4, 30, 12, 15);
      final nestedAt = DateTime(2026, 5, 1, 8, 30);

      final normalized = normalizeFirestoreJson(<String, dynamic>{
        'created_at': Timestamp.fromDate(createdAt),
        'nested': <String, dynamic>{
          'updated_at': Timestamp.fromDate(nestedAt),
        },
        'items': <dynamic>[
          Timestamp.fromDate(createdAt),
          <Object, dynamic>{
            42: Timestamp.fromDate(nestedAt),
          },
        ],
      });

      expect(normalized['created_at'], createdAt);
      expect(normalized['nested'], <String, dynamic>{'updated_at': nestedAt});
      expect(normalized['items'], <dynamic>[
        createdAt,
        <String, dynamic>{'42': nestedAt},
      ]);
    });

    test('keeps primitive values unchanged', () {
      final normalized = normalizeFirestoreJson(<String, dynamic>{
        'name': 'Apple',
        'amount': 2,
        'enabled': true,
        'missing': null,
      });

      expect(normalized, <String, dynamic>{
        'name': 'Apple',
        'amount': 2,
        'enabled': true,
        'missing': null,
      });
    });
  });
}
