// P12 and P13 of the free kcal notice (#971): the switch hint and the
// debug button's notice.
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import 'pace_notice_harness.dart';

void main() {
  group('P12', () {
    test('P12: the German hint describes the new trigger', () {
      expect(
        AppLocalizationsDe().diaryBudgetMenuPaceNoticeHint,
        'Zu Beginn jeder Tageszeit, wenn du kcal frei hast',
      );
    });

    test('P12: the English hint describes the new trigger', () {
      expect(
        AppLocalizationsEn().diaryBudgetMenuPaceNoticeHint,
        'At the start of each part of the day, when you have kcal free',
      );
    });
  });

  group('P13', () {
    test('P13: the debug notice reads "Hey, du hast wieder <number> kcal '
        'frei" with no meal name', () async {
      final h = PaceHarness(now: paceAt(10, 15));

      await h.controller.debugShowSoon(paceDay(eaten: 400), germanTexts());

      final titles = h.notifications.scheduled.values.map((n) => n.title);
      expect(titles, hasLength(1));
      expect(
        titles.single,
        matches(RegExp(r'^Hey, du hast wieder [\d.]+ kcal frei$')),
      );
      expectNoMeal(titles.single);
    });
  });
}
