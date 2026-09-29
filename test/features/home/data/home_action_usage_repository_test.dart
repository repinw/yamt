import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/home/data/home_action_usage_repository.dart';

import '../../../helpers/memory_app_preferences.dart';

class _RefusingPreferences extends MemoryAppPreferences {
  @override
  Future<bool> setString(String key, String value) async => false;
}

void main() {
  test('saves counts and reads them back', () async {
    final AppPreferences preferences = MemoryAppPreferences();
    final repository = HomeActionUsageRepository(preferences);

    expect(repository.cachedCounts(), isEmpty);

    await repository.saveCounts({'barcode': 3});

    expect(HomeActionUsageRepository(preferences).cachedCounts(), {
      'barcode': 3,
    });
  });

  test('throws when the preferences refuse the write', () async {
    final repository = HomeActionUsageRepository(_RefusingPreferences());

    await expectLater(
      repository.saveCounts({'barcode': 1}),
      throwsA(isA<StateError>()),
    );
  });
}
