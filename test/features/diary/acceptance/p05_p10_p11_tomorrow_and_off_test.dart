// P5, P10 and P11 of the free kcal notice (#971): tomorrow's day-start
// notice, pause days, and turning the switch or the pace marker off.
//
// Assumed seam for tomorrow's budget (the builder follows it):
//   Future<void> DiaryPaceNotificationController.sync(
//     DiaryPaceDay? pace,
//     DiaryPaceNoticeTexts texts, {
//     double? tomorrowTargetKcal,
//   })
// `tomorrowTargetKcal` is tomorrow's real budget (training day, carryover,
// ...); null means tomorrow gets no notice (pause day, unknown). The caller
// (the listener, through the notice day provider) computes it.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

import 'pace_notice_harness.dart';

void main() {
  final tomorrow6 = paceAt(6, 0, paceTomorrow);

  group('P5', () {
    test(
      'P5: planned at 21:30 for tomorrow 6:00 with 500 (budget 2.000)',
      () async {
        final h = PaceHarness(now: paceAt(21, 30));

        await h.sync(paceDay(eaten: 1500), tomorrowTarget: 2000);

        expect(h.titlesAt(tomorrow6), ['Hey, du hast wieder 500 kcal frei']);
      },
    );

    test('P5: a training day with budget 2.400 shows 600', () async {
      final h = PaceHarness(now: paceAt(21, 30));

      await h.sync(paceDay(), tomorrowTarget: 2400);

      expect(h.titlesAt(tomorrow6), ['Hey, du hast wieder 600 kcal frei']);
    });

    test('P5: "Mit Übertrag" with budget 2.100 shows 525', () async {
      final h = PaceHarness(now: paceAt(21, 30));

      await h.sync(paceDay(), tomorrowTarget: 2100);

      expect(h.titlesAt(tomorrow6), ['Hey, du hast wieder 525 kcal frei']);
    });

    test("P5: tomorrow's notice has no macro tip", () async {
      final h = PaceHarness(now: paceAt(21, 30));

      await h.sync(
        paceDay(eaten: 1500, macro: DiaryPaceMacro.protein),
        tomorrowTarget: 2000,
      );

      expect(h.bodyAt(tomorrow6), '');
    });

    test('P5: in English the title reads "Hey, you have 500 kcal free '
        'again"', () async {
      final h = PaceHarness(now: paceAt(21, 30));

      await h.sync(paceDay(), tomorrowTarget: 2000, texts: englishTexts());

      expect(h.titlesAt(tomorrow6), ['Hey, you have 500 kcal free again']);
    });

    test(
      'P5: a later planning plans tomorrow again with the newest budget',
      () async {
        final h = PaceHarness(now: paceAt(21, 30));
        await h.sync(paceDay(), tomorrowTarget: 2000);

        h.now = paceAt(22);
        await h.sync(paceDay(), tomorrowTarget: 2400);

        expect(h.titlesAt(tomorrow6), ['Hey, du hast wieder 600 kcal frei']);
      },
    );
    test('P5: planning the notice of tomorrow leaves the pending ones of today '
        'they are', () async {
      final h = PaceHarness(now: paceAt(13));
      await h.sync(paceDay(eaten: 1000));
      final before = h.titlesAt(paceAt(16));

      await h.sync(paceDay(eaten: 1000), tomorrowTarget: 2000);
      await h.sync(paceDay(eaten: 1000), tomorrowTarget: 2400);

      expect(h.titlesAt(paceAt(16)), before);
      expect(before, [germanTitle('800')]);
      expect(h.titlesAt(tomorrow6), [germanTitle('600')]);
    });

    test('P5: when tomorrow comes only one Frühstück notice comes, also when '
        'the app opens before 6:00', () async {
      final h = PaceHarness(now: paceAt(21, 30));
      await h.sync(paceDay(), tomorrowTarget: 2000);

      h.now = paceAt(5, 0, paceTomorrow);
      await h.sync(paceDay(day: paceTomorrow), tomorrowTarget: 2000);

      expect(h.titlesAt(tomorrow6), [germanTitle('500')]);
      // The day after is planned in turn.
      expect(h.titlesAt(paceAt(6, 0, DateTime(2026, 11, 14))), hasLength(1));
    });
  });

  group('P10', () {
    test(
      'P10: tomorrow is a pause day, no Frühstück notice for tomorrow',
      () async {
        final h = PaceHarness(now: paceAt(21, 30));

        await h.sync(paceDay());

        expect(h.titlesAt(tomorrow6), isEmpty);
      },
    );

    test(
      'P10: tomorrow turns into a pause day, the planned notice goes',
      () async {
        final h = PaceHarness(now: paceAt(21, 30));
        await h.sync(paceDay(), tomorrowTarget: 2000);
        expect(h.titlesAt(tomorrow6), isNotEmpty);

        h.now = paceAt(22);
        await h.sync(paceDay());

        expect(h.titlesAt(tomorrow6), isEmpty);
      },
    );
  });

  group('P11', () {
    Future<PaceHarness> pendingAt1200() async {
      final h = PaceHarness(now: paceAt(12));
      await h.sync(paceDay(eaten: 1000), tomorrowTarget: 2000);
      expect(h.titlesAt(paceAt(16)), isNotEmpty);
      expect(h.titlesAt(tomorrow6), isNotEmpty);
      return h;
    }

    test('P11: turning the switch off cancels both pending notices, a shown '
        'one stays', () async {
      final h = await pendingAt1200();
      h.notifications.active.add(42);

      await h.controller.setEnabled(enabled: false);
      // The app syncs with nothing once the pace notice day is null.
      await h.sync(null);

      expect(h.titlesAt(paceAt(16)), isEmpty);
      expect(h.titlesAt(tomorrow6), isEmpty);
      expect(h.notifications.active, contains(42));
    });

    test('P11: turning the pace marker off cancels both, none is planned '
        'while it is off', () async {
      final h = await pendingAt1200();

      await h.container
          .read(diaryPaceMarkerControllerProvider.notifier)
          .show(visible: false);
      await h.sync(null);

      expect(h.notifications.scheduled, isEmpty);
    });

    test('P11: turning the pace marker on again at 13:00 plans 16:00 and '
        "tomorrow's 6:00 again", () async {
      final h = await pendingAt1200();
      await h.container
          .read(diaryPaceMarkerControllerProvider.notifier)
          .show(visible: false);
      await h.sync(null);

      h.now = paceAt(13);
      await h.container
          .read(diaryPaceMarkerControllerProvider.notifier)
          .show(visible: true);
      await h.sync(paceDay(eaten: 1000), tomorrowTarget: 2000);

      expect(h.titlesAt(paceAt(16)), [germanTitle('800')]);
      expect(h.titlesAt(tomorrow6), [germanTitle('500')]);
    });
  });
}
