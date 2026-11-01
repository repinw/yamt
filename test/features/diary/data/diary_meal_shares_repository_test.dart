import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/data/diary_meal_shares_repository.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

import '../../../helpers/memory_app_preferences.dart';

const _key = 'diary_meal_shares_v1';

void main() {
  test('loads the standard split when nothing is saved', () {
    final repository = DiaryMealSharesRepository(MemoryAppPreferences());

    expect(repository.loadShares(), DiaryMealShares.standard);
  });

  test('loads the saved split', () {
    final repository = DiaryMealSharesRepository(
      MemoryAppPreferences(initialStrings: {_key: '0,60,30,10'}),
    );

    expect(repository.loadShares(), const DiaryMealShares([0, 60, 30, 10]));
  });

  test('loads the standard split when the saved one is broken', () {
    final repository = DiaryMealSharesRepository(
      MemoryAppPreferences(initialStrings: {_key: '50,50'}),
    );

    expect(repository.loadShares(), DiaryMealShares.standard);
  });

  test('saves a split and deletes it again', () async {
    final preferences = MemoryAppPreferences();
    final repository = DiaryMealSharesRepository(preferences);

    await repository.saveShares(const DiaryMealShares([20, 40, 30, 10]));
    expect(preferences.getStringSync(_key), '20,40,30,10');
    expect(repository.loadShares(), const DiaryMealShares([20, 40, 30, 10]));

    await repository.deleteShares();
    expect(preferences.getStringSync(_key), isNull);
    expect(repository.loadShares(), DiaryMealShares.standard);
  });
}
