import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../helpers/l10n_test_utils.dart';
import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _askedKey = 'cook_timer_permissions_asked_v2';

CookRun _run() => buildCookRun(
  step: CookRunStep.cook,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  lines: [textLine('l-flour', 'Mehl', settlement: const LineIgnored())],
);

void main() {
  group('texts', () {
    testWidgets('durationText names minutes and seconds in German', (
      tester,
    ) async {
      final l10n = await pumpLocalizations(tester, locale: const Locale('de'));

      expect(
        KochmodusTimerSheet.durationText(l10n, const Duration(seconds: 90)),
        '1 Min 30 Sek',
      );
      expect(
        KochmodusTimerSheet.durationText(l10n, const Duration(minutes: 5)),
        '5 Min',
      );
      expect(
        KochmodusTimerSheet.durationText(l10n, const Duration(seconds: 30)),
        '30 Sek',
      );
    });

    testWidgets('choicesText shows a range of whole minutes only', (
      tester,
    ) async {
      final l10n = await pumpLocalizations(tester, locale: const Locale('de'));

      expect(
        KochmodusTimerSheet.choicesText(l10n, const [
          Duration(minutes: 8),
          Duration(minutes: 10),
        ]),
        '8–10 Min',
      );
      // 1,5 to 2,5 minutes is no range of whole minutes: the first one.
      expect(
        KochmodusTimerSheet.choicesText(l10n, const [
          Duration(seconds: 90),
          Duration(seconds: 150),
        ]),
        KochmodusTimerSheet.durationText(l10n, const Duration(seconds: 90)),
      );
      expect(
        KochmodusTimerSheet.choicesText(l10n, const [Duration(minutes: 7)]),
        '7 Min',
      );
    });
  });

  group('hints', () {
    late KochmodusCookingHarness harness;

    setUp(() async => harness = await KochmodusCookingHarness.open());

    Future<void> openSheet(WidgetTester tester) async {
      final run = _run();
      await harness.store(tester, run);
      // The alarm listener keeps the controller of "Erlauben" alive.
      await harness.pumpApp(
        tester,
        initialLocation: AppRoutes.homeCookRunPath(run.id),
      );
      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);
    }

    // Takes the page down, so no ticker is left running.
    Future<void> close(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox.shrink());

    testWidgets('blocked notifications show their hint, not the exact one', (
      tester,
    ) async {
      await harness.preferences.setString(_askedKey, 'set');
      harness.notifications
        ..allowed = false
        ..exactAllowed = false;

      await openSheet(tester);

      final l10n = harness.l10n(tester);
      expect(
        find.byKey(KochmodusTimerSheet.allowNotificationsKey),
        findsOneWidget,
      );
      expect(
        find.text(l10n.kochmodusTimerNotificationsOffHint),
        findsOneWidget,
      );
      expect(find.byKey(KochmodusTimerSheet.allowExactKey), findsNothing);
      expect(find.text(l10n.kochmodusTimerInexactHint), findsNothing);

      await tester.tap(find.byKey(KochmodusTimerSheet.allowNotificationsKey));
      await harness.idle(tester);

      expect(harness.notifications.settingsOpened, 1);
      await close(tester);
    });

    testWidgets('allowed notifications show no notification hint', (
      tester,
    ) async {
      await harness.preferences.setString(_askedKey, 'set');

      await openSheet(tester);

      expect(
        find.byKey(KochmodusTimerSheet.allowNotificationsKey),
        findsNothing,
      );
      await close(tester);
    });

    testWidgets('a device that never asked shows no notification hint', (
      tester,
    ) async {
      harness.notifications.allowed = false;

      await openSheet(tester);

      expect(
        find.byKey(KochmodusTimerSheet.allowNotificationsKey),
        findsNothing,
      );
      await close(tester);
    });
  });
}
