// P8, P9 and P14 of the free kcal notice (#971): the standard meal times,
// own times kept, and the pace marker that jumps at the start of each part
// of the day (DiaryMealTimes.dueAt).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';

import '../../../helpers/memory_app_preferences.dart';
import 'pace_notice_harness.dart';

const _key = 'diary_meal_times_v1';

ProviderContainer _containerWith(MemoryAppPreferences preferences) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

/// What the marker stands at, in kcal of a 2.000 budget, at [hour]:[minute].
double _marker(int hour, int minute, [DiaryMealTimes? times]) =>
    (times ?? DiaryMealTimes.standard).dueAt(
      hour * 60 + minute,
      DiaryMealShares.standard,
    ) *
    2000;

void main() {
  group('P8', () {
    test('P8: the standard times are 6 / 11 / 16 / 20 / 21', () {
      expect(DiaryMealTimes.standard.start, 6 * 60);
      expect(DiaryMealTimes.standard.ends, [
        11 * 60,
        16 * 60,
        20 * 60,
        21 * 60,
      ]);
      expect(DiaryMealTimes.standard.encode(), '360,660,960,1200,1260');
    });
  });

  group('P9', () {
    test('P9: meal times never changed by me start with the new standard', () {
      final container = _containerWith(MemoryAppPreferences());

      expect(
        container.read(diaryMealTimesControllerProvider).encode(),
        '360,660,960,1200,1260',
      );
    });

    test('P9: own times 7 / 10 / 14 / 19 / 22 are kept', () {
      final container = _containerWith(
        MemoryAppPreferences(initialStrings: {_key: '420,600,840,1140,1320'}),
      );

      expect(
        container.read(diaryMealTimesControllerProvider).encode(),
        '420,600,840,1140,1320',
      );
    });

    test('P9: "Zurücksetzen" brings 6 / 11 / 16 / 20 / 21', () async {
      final container = _containerWith(
        MemoryAppPreferences(initialStrings: {_key: '420,600,840,1140,1320'}),
      );

      await container.read(diaryMealTimesControllerProvider.notifier).reset();

      expect(
        container.read(diaryMealTimesControllerProvider).encode(),
        '360,660,960,1200,1260',
      );
    });
  });

  group('P14', () {
    test('P14: before the day start the marker stands at 0', () {
      expect(_marker(0, 0), 0);
      expect(_marker(5, 59), 0);
    });

    test('P14: at 6:00 it jumps to 500 and stays through the morning', () {
      expect(_marker(6, 0), closeTo(500, 1e-6));
      expect(_marker(8, 30), closeTo(500, 1e-6));
      expect(_marker(10, 59), closeTo(500, 1e-6));
    });

    test('P14: at 11:00 it jumps to 1.200', () {
      expect(_marker(11, 0), closeTo(1200, 1e-6));
      expect(_marker(13, 30), closeTo(1200, 1e-6));
      expect(_marker(15, 59), closeTo(1200, 1e-6));
    });

    test('P14: at 16:00 it jumps to 1.800', () {
      expect(_marker(16, 0), closeTo(1800, 1e-6));
      expect(_marker(19, 59), closeTo(1800, 1e-6));
    });

    test('P14: at 20:00 (snack part) it jumps to 2.000 and stays', () {
      expect(_marker(20, 0), closeTo(2000, 1e-6));
      expect(_marker(23, 59), closeTo(2000, 1e-6));
    });

    test('P14: not 250 at 8:30 (the old even rise)', () {
      expect(_marker(8, 30), isNot(closeTo(250, 1)));
    });

    test('P14: with a day start of 7:00 it is 0 at 6:30 and 500 at 7:00', () {
      final times = DiaryMealTimes.standard.withStart(7 * 60);

      expect(_marker(6, 30, times), 0);
      expect(_marker(7, 0, times), closeTo(500, 1e-6));
    });

    test('P14: marker and notice show the same: at 11:00 with 400 eaten the '
        'marker stands 800 ahead and the notice says 800', () {
      final notice = diaryPaceNotices(paceDay(eaten: 400))
          .singleWhere((n) => n.at == paceAt(11));

      expect(_marker(11, 0) - 400, closeTo(800, 1e-6));
      expect(notice.freeKcal, 800);
    });
  });
}
