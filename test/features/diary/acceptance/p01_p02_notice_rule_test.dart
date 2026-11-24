// P1 and P2 of the free kcal notice (#971): which notices a day has and the
// value each one shows, driven through the public rule diaryPaceNotices.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';

import 'pace_notice_harness.dart';

/// The notice that comes at [hour]:00, as (hour:minute, kcal); null if none.
int? _valueAt(DiaryPaceDay pace, int hour) {
  final at = paceAt(hour);
  final hits = diaryPaceNotices(pace).where((n) => n.at == at).toList();
  expect(hits.length, lessThanOrEqualTo(1), reason: 'one notice at $hour:00');
  return hits.isEmpty ? null : hits.single.freeKcal;
}

void main() {
  group('P1', () {
    test('P1: one notice at 6:00, 11:00 and 16:00 with the standard times, '
        'none for the snack', () {
      final notices = diaryPaceNotices(paceDay());

      expect(notices.map((n) => n.at), [paceAt(6), paceAt(11), paceAt(16)]);
      // Not at the end of Abendessen (20:00) or at any other time.
      expect(notices.map((n) => n.at), isNot(contains(paceAt(20))));
    });

    test('P1: own meal times move the notices, Frühstück by 10:00 moves the '
        'Mittagessen notice to 10:00', () {
      const times = DiaryMealTimes(
        start: 6 * 60,
        ends: [10 * 60, 16 * 60, 20 * 60, 21 * 60],
      );

      expect(diaryPaceNotices(paceDay(times: times)).map((n) => n.at), [
        paceAt(6),
        paceAt(10),
        paceAt(16),
      ]);
    });

    test('P1: a day start of 7:00 moves the first notice to 7:00', () {
      final times = DiaryMealTimes.standard.withStart(7 * 60);

      expect(diaryPaceNotices(paceDay(times: times)).first.at, paceAt(7));
    });

    test('P1: at most one notice per part of the day', () {
      final ats = diaryPaceNotices(paceDay()).map((n) => n.at).toList();

      expect(ats.toSet().length, ats.length);
      expect(ats.length, lessThanOrEqualTo(3));
    });
  });

  group('P2', () {
    test('P2: with nothing eaten the values are what is due by the end of '
        'each part: 500, 1.200, 1.800', () {
      expect(diaryPaceNotices(paceDay()).map((n) => n.freeKcal), [
        500,
        1200,
        1800,
      ]);
    });

    test('P2: Frühstück, nothing eaten, shows 500', () {
      expect(_valueAt(paceDay(), 6), 500);
    });

    test('P2: Mittagessen with 400 eaten shows 800', () {
      expect(_valueAt(paceDay(eaten: 400), 11), 800);
    });

    test(
      'P2: Mittagessen with nothing eaten shows 1.200 (open kcal add up)',
      () {
        expect(_valueAt(paceDay(), 11), 1200);
      },
    );

    test('P2: Mittagessen with 700 eaten shows 500', () {
      expect(_valueAt(paceDay(eaten: 700), 11), 500);
    });

    test('P2: Mittagessen with 1.199 eaten shows 1', () {
      expect(_valueAt(paceDay(eaten: 1199), 11), 1);
    });

    test('P2: Abendessen with 1.000 eaten shows 800', () {
      expect(_valueAt(paceDay(eaten: 1000), 16), 800);
    });

    test('P2: Abendessen with 1.800 eaten brings no notice', () {
      expect(_valueAt(paceDay(eaten: 1800), 16), isNull);
    });

    test('P2: Abendessen with 2.100 eaten (-300) brings no notice', () {
      expect(_valueAt(paceDay(eaten: 2100), 16), isNull);
    });

    test('P2: the snack share is never counted', () {
      // Eaten 0: the last value is 1.800, not 2.000.
      expect(diaryPaceNotices(paceDay()).last.freeKcal, 1800);
    });

    test('P2: with the carryover budget 2.100 Frühstück shows 525', () {
      expect(_valueAt(paceDay(target: 2100), 6), 525);
    });

    test(
      'P2: budget 2.150, nothing eaten, 537,5 is rounded half up to 538',
      () {
        expect(_valueAt(paceDay(target: 2150), 6), 538);
      },
    );

    test('P2: budget 2.150, 0,4 eaten, 537,1 shows 537', () {
      expect(_valueAt(paceDay(target: 2150, eaten: 0.4), 6), 537);
    });

    test('P2: budget 2.150, 537,2 eaten, value 0,3 rounds to 0: no notice', () {
      expect(_valueAt(paceDay(target: 2150, eaten: 537.2), 6), isNull);
    });
  });
}
