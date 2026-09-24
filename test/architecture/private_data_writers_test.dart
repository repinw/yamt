import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Private collections that must only be written as encrypted payloads.
const _privateCollectionNames = <String>[
  'calorie_entries',
  'calorie_settings',
  'health_weights',
  'calorie_product_overrides',
  'burn_week_run_state',
];

/// Files that encrypt what they write to the private collections.
const _allowedFiles = <String>{
  'lib/features/auth/data/user_data_key_repository.dart',
  'lib/features/calories/data/burn_week_run_state_repository.dart',
  'lib/features/calories/data/calorie_log_repository.dart',
  'lib/features/calories/data/calorie_product_cache_repository.dart',
  'lib/features/calories/data/calorie_settings_repository.dart',
  'lib/features/health/data/firestore_manual_health_weight_repository.dart',
  'lib/features/inventory/data/firestore_inventory_calorie_entry_commit_store.dart',
  'lib/features/inventory/data/prepared_meal_calorie_entry_commit_store.dart',
};

void main() {
  test('only encrypting files name the private collections', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (_allowedFiles.contains(path)) continue;
      final source = file.readAsStringSync();
      for (final name in _privateCollectionNames) {
        if (source.contains("'$name'")) {
          offenders.add('$path names $name');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Private data must be written through a repository that encrypts '
          'it with the user data key. Add a new writer here only after it '
          'encrypts its payload.',
    );
  });
}
