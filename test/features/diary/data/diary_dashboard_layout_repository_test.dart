import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/data/diary_dashboard_layout_repository.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';

import '../../../helpers/memory_app_preferences.dart';

class _RefusingPreferences extends MemoryAppPreferences {
  @override
  Future<bool> setString(String key, String value) async => false;
}

const _layout = DiaryDashboardLayout(
  tiles: [
    DiaryTilePlacement(id: 'kcal', size: DiaryTileSize.s2x1, mode: 'ring'),
  ],
  hidden: ['budget'],
);

void main() {
  test('saves the layout per user and deletes it', () async {
    final preferences = MemoryAppPreferences();
    final anna = DiaryDashboardLayoutRepository(preferences, 'anna');

    expect(anna.cachedLayout(), isNull);
    await anna.saveLayout(_layout);

    expect(
      DiaryDashboardLayoutRepository(preferences, 'anna').cachedLayout(),
      _layout,
    );
    expect(
      DiaryDashboardLayoutRepository(preferences, 'ben').cachedLayout(),
      isNull,
    );

    await anna.deleteLayout();
    expect(anna.cachedLayout(), isNull);
  });

  test('signed out reads nothing and refuses to save', () async {
    final repository = DiaryDashboardLayoutRepository(
      MemoryAppPreferences(),
      null,
    );

    expect(repository.cachedLayout(), isNull);
    await expectLater(
      repository.saveLayout(_layout),
      throwsA(isA<StateError>()),
    );
  });

  test('throws when the preferences refuse the write', () async {
    final repository = DiaryDashboardLayoutRepository(
      _RefusingPreferences(),
      'anna',
    );

    await expectLater(
      repository.saveLayout(_layout),
      throwsA(isA<StateError>()),
    );
  });
}
