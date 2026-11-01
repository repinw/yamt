import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _key = 'diary_meal_times_v1';

void main() {
  ProviderContainer containerWith(MemoryAppPreferences preferences) {
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts with the standard times when nothing is saved', () {
    final container = containerWith(MemoryAppPreferences());

    expect(
      container.read(diaryMealTimesControllerProvider),
      DiaryMealTimes.standard,
    );
  });

  test('starts with the saved times', () {
    final container = containerWith(
      MemoryAppPreferences(initialStrings: {_key: '300,480,720,1080,1320'}),
    );

    expect(
      container.read(diaryMealTimesControllerProvider),
      const DiaryMealTimes(start: 300, ends: [480, 720, 1080, 1320]),
    );
  });

  test('saved times that cannot be read start standard', () {
    for (final broken in [
      'x,540,780,1140,1260',
      '360,540,780,1140',
      '360,540,780,1260,1140',
      '360,540,780,1140,1440',
      '',
    ]) {
      final container = containerWith(
        MemoryAppPreferences(initialStrings: {_key: broken}),
      );

      expect(
        container.read(diaryMealTimesControllerProvider),
        DiaryMealTimes.standard,
        reason: broken,
      );
    }
  });

  test('select switches at once and saves for the next start', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final states = <DiaryMealTimes>[];
    final subscription = container.listen(
      diaryMealTimesControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final times = DiaryMealTimes.standard.withEnd(MealType.lunch, 480);

    await container
        .read(diaryMealTimesControllerProvider.notifier)
        .select(times);

    expect(states, [DiaryMealTimes.standard, times]);
    expect(preferences.getStringSync(_key), '360,480,480,1140,1260');
    expect(
      containerWith(preferences).read(diaryMealTimesControllerProvider),
      times,
    );
  });

  test('select replaces the saved times each time', () async {
    final preferences = MemoryAppPreferences();
    final container = containerWith(preferences);
    final subscription = container.listen(
      diaryMealTimesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      diaryMealTimesControllerProvider.notifier,
    );

    await controller.select(DiaryMealTimes.standard.withStart(420));
    await controller.select(DiaryMealTimes.standard.withStart(300));

    expect(subscription.read().start, 300);
    expect(preferences.getStringSync(_key), '300,540,780,1140,1260');
  });

  test('reset goes back to the standard and forgets the saved times', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: {_key: '300,480,720,1080,1320'},
    );
    final container = containerWith(preferences);
    final states = <DiaryMealTimes>[];
    final subscription = container.listen(
      diaryMealTimesControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(diaryMealTimesControllerProvider.notifier).reset();

    expect(states, [
      const DiaryMealTimes(start: 300, ends: [480, 720, 1080, 1320]),
      DiaryMealTimes.standard,
    ]);
    expect(preferences.getStringSync(_key), isNull);
    expect(
      containerWith(preferences).read(diaryMealTimesControllerProvider),
      DiaryMealTimes.standard,
    );
  });
}
