// P3, P4, P6 and P7 of the free kcal notice (#971): the texts, the macro
// tip, notices that are due before the app opens, and re-planning after a
// diary change. Driven through DiaryPaceNotificationController.sync with the
// real German and English texts.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';

import 'pace_notice_harness.dart';

void main() {
  group('P3', () {
    test('P3: the Mittagessen notice with 800 reads "Hey, du hast wieder '
        '800 kcal frei"', () async {
      final h = PaceHarness();

      await h.sync(paceDay(eaten: 400));

      expect(h.titlesAt(paceAt(11)), [germanTitle('800')]);
    });

    test('P3: no title names a meal or a breakdown', () async {
      final h = PaceHarness();

      await h.sync(paceDay(eaten: 400));

      final titles = h.notifications.scheduled.values.map((n) => n.title);
      expect(titles, isNotEmpty);
      for (final title in titles) {
        expect(title, startsWith('Hey, du hast wieder '));
        expectNoMeal(title);
      }
    });

    test('P3: in English the title reads "Hey, you have 800 kcal free '
        'again"', () async {
      final h = PaceHarness();

      await h.sync(paceDay(eaten: 400), texts: englishTexts());

      expect(h.titlesAt(paceAt(11)), ['Hey, you have 800 kcal free again']);
    });

    test(
      'P3: values of 1.000 and more read with the German separator',
      () async {
        final h = PaceHarness();

        await h.sync(paceDay());

        expect(h.titlesAt(paceAt(11)), [germanTitle('1.200')]);
      },
    );
  });

  group('P4', () {
    test('P4: nothing eaten today, no macro tip', () async {
      final h = PaceHarness();

      await h.sync(paceDay(macro: DiaryPaceMacro.protein));

      expect(h.bodyAt(paceAt(6)), '');
      expect(h.bodyAt(paceAt(11)), '');
      expect(h.bodyAt(paceAt(16)), '');
    });

    test('P4: 400 eaten, protein most left: "Versuch, mehr Eiweiß zu '
        'essen."', () async {
      final h = PaceHarness();

      await h.sync(paceDay(eaten: 400, macro: DiaryPaceMacro.protein));

      expect(h.bodyAt(paceAt(11)), 'Versuch, mehr Eiweiß zu essen.');
    });

    test(
      'P4: 1.000 eaten, fat most left: "Versuch, mehr Fett zu essen."',
      () async {
        final h = PaceHarness();

        await h.sync(paceDay(eaten: 1000, macro: DiaryPaceMacro.fat));

        expect(h.bodyAt(paceAt(16)), 'Versuch, mehr Fett zu essen.');
      },
    );
  });

  group('P6', () {
    test('P6: opened first at 12:30, no Mittagessen notice, Abendessen is '
        'planned for 16:00', () async {
      final h = PaceHarness(now: paceAt(12, 30));

      await h.sync(paceDay());

      expect(h.plannedTimes, [paceAt(16)]);
      expect(h.titlesAt(paceAt(16)), [germanTitle('1.800')]);
    });

    test('P6: not later today either', () async {
      final h = PaceHarness(now: paceAt(12, 30));
      await h.sync(paceDay());

      h.now = paceAt(12, 45);
      await h.sync(paceDay(eaten: 100));
      h.now = paceAt(15, 59);
      await h.sync(paceDay(eaten: 100));

      expect(h.plannedTimes, [paceAt(16)]);
    });
  });

  group('P7', () {
    Future<PaceHarness> pendingAt1300() async {
      final h = PaceHarness(now: paceAt(13));
      await h.sync(paceDay(eaten: 1000));
      expect(h.titlesAt(paceAt(16)), [germanTitle('800')]);
      return h;
    }

    test('P7: 1.300 eaten re-plans 16:00 with 500', () async {
      final h = await pendingAt1300();

      await h.sync(paceDay(eaten: 1300));

      expect(h.titlesAt(paceAt(16)), [germanTitle('500')]);
    });

    test('P7: 800 eaten (delete) re-plans 16:00 with 1.000', () async {
      final h = await pendingAt1300();

      await h.sync(paceDay(eaten: 800));

      expect(h.titlesAt(paceAt(16)), [germanTitle('1.000')]);
    });

    test('P7: 1.800 eaten cancels the notice at 16:00', () async {
      final h = await pendingAt1300();

      await h.sync(paceDay(eaten: 1800));

      expect(h.titlesAt(paceAt(16)), isEmpty);
    });

    test('P7: 2.000 eaten cancels the notice at 16:00', () async {
      final h = await pendingAt1300();

      await h.sync(paceDay(eaten: 2000));

      expect(h.titlesAt(paceAt(16)), isEmpty);
    });

    test('P7: cancelled, then 1.000 deleted at 14:00, it is planned again '
        'with 800', () async {
      final h = await pendingAt1300();
      await h.sync(paceDay(eaten: 2000));
      expect(h.titlesAt(paceAt(16)), isEmpty);

      h.now = paceAt(14);
      await h.sync(paceDay(eaten: 1000));

      expect(h.titlesAt(paceAt(16)), [germanTitle('800')]);
    });

    test('P7: a notice already shown stays and no second one comes', () async {
      final h = PaceHarness(now: paceAt(10, 30));
      await h.sync(paceDay());
      expect(h.titlesAt(paceAt(11)), [germanTitle('1.200')]);
      h.fire(paceAt(11));
      final shown = h.notifications.active.toSet();
      expect(shown, isNotEmpty);

      h.now = paceAt(11, 30);
      await h.sync(paceDay(eaten: 500));
      await h.sync(paceDay());

      expect(h.notifications.active, shown);
      expect(h.titlesAt(paceAt(11)), isEmpty);
      // The pending Abendessen notice follows the change.
      expect(h.titlesAt(paceAt(16)), [germanTitle('1.800')]);
    });
  });
}
