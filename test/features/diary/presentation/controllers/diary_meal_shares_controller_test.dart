import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _key = 'diary_meal_shares_v1';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts with the standard split when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(
      container.read(diaryMealSharesControllerProvider),
      DiaryMealShares.standard,
    );
  });

  test('starts with the saved split, also with a meal at 0', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {_key: '0,60,30,10'}),
    );

    expect(
      container.read(diaryMealSharesControllerProvider),
      const DiaryMealShares([0, 60, 30, 10]),
    );
  });

  test('a saved split that does not add up to 100 starts standard', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {_key: '30,30,30,30'}),
    );

    expect(
      container.read(diaryMealSharesControllerProvider),
      DiaryMealShares.standard,
    );
  });

  test('select switches at once and saves for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final subscription = container.listen(
      diaryMealSharesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container
        .read(diaryMealSharesControllerProvider.notifier)
        .select(const DiaryMealShares([30, 30, 30, 10]));

    expect(subscription.read(), const DiaryMealShares([30, 30, 30, 10]));
    expect(preferences.getStringSync(_key), '30,30,30,10');
    expect(
      containerWith(preferences).read(diaryMealSharesControllerProvider),
      const DiaryMealShares([30, 30, 30, 10]),
    );
  });

  test('reset goes back to the standard and forgets the saved split', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: {_key: '0,60,30,10'},
    );
    final container = containerWith(preferences);
    final subscription = container.listen(
      diaryMealSharesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container.read(diaryMealSharesControllerProvider.notifier).reset();

    expect(subscription.read(), DiaryMealShares.standard);
    expect(preferences.getStringSync(_key), isNull);
  });
}
