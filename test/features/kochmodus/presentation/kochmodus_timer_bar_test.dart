import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_bar.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

CookTimer _timer(String id, String label, Duration left) => CookTimer(
  id: id,
  label: label,
  endsAt: kochmodusTestStart.add(left),
  deviceId: 'dev-1',
);

CookRun _run(List<CookTimer> timers) => buildCookRun(
  step: CookRunStep.cook,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  timers: timers,
  lines: [textLine('l-flour', 'Mehl', settlement: const LineIgnored())],
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  // Takes the page down, so no ticker of the bar is left running.
  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('large text and many timers', () {
    // Every layout error of the page, to tell the bar's from the others.
    final errors = <String>[];

    Future<void> openNarrow(
      WidgetTester tester,
      CookRun run, {
      required double scale,
    }) async {
      errors.clear();
      final handler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.toString(minLevel: DiagnosticLevel.fine));
        handler?.call(details);
      };
      addTearDown(() => FlutterError.onError = handler);
      await harness.store(tester, run);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await harness.pumpRun(tester, run.id);
      tester.view.physicalSize = const Size(360, 3000);
      await harness.idle(tester);
    }

    testWidgets('at double text the actions are icons and nothing overflows', (
      tester,
    ) async {
      await openNarrow(
        tester,
        _run([
          _timer('t-1', 'Nudeln mit langem Namen', const Duration(minutes: 5)),
        ]),
        scale: 2,
      );
      final l10n = harness.l10n(tester);

      for (final key in [
        KochmodusTimerBar.extendKey('t-1'),
        KochmodusTimerBar.stopKey('t-1'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(IconButton),
          ),
          findsOneWidget,
        );
      }
      expect(find.text(l10n.kochmodusTimerStop), findsNothing);
      // Other parts of the page may overflow; the bar must not.
      tester.takeException();
      expect(errors.where((e) => e.contains('kochmodus_timer_bar')), isEmpty);

      await tester.tap(find.byKey(KochmodusTimerBar.stopKey('t-1')));
      await harness.idle(tester);
      expect((await harness.storedRun(tester, 'recipe-t1')).timers, isEmpty);
      await close(tester);
    });

    testWidgets('the page at 360 dp and double text does not overflow', (
      tester,
    ) async {
      await openNarrow(tester, _run(const []), scale: 2);

      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('at normal text the actions are words', (tester) async {
      await openNarrow(
        tester,
        _run([_timer('t-1', 'Nudeln', const Duration(minutes: 5))]),
        scale: 1,
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTimerStop), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KochmodusTimerBar),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
      await close(tester);
    });

    testWidgets('four timers stay within the height cap and scroll', (
      tester,
    ) async {
      await openNarrow(
        tester,
        _run([
          for (var i = 1; i <= 4; i++)
            _timer('t-$i', 'Timer $i', Duration(minutes: 5 + i)),
        ]),
        scale: 1,
      );

      expect(
        tester.getSize(find.byType(KochmodusTimerBar)).height,
        lessThanOrEqualTo(AppGraphit.buttonHeight * 2.5),
      );
      expect(
        find.byKey(KochmodusTimerBar.stopKey('t-4'), skipOffstage: false),
        findsOneWidget,
      );
      expect(errors, isEmpty);
      await close(tester);
    });
  });

  group('Timer', () {
    testWidgets('the Timer button starts a timer from the sheet', (
      tester,
    ) async {
      await open(tester, _run(const []));
      final l10n = harness.l10n(tester);
      final device = await harness.deviceId(tester);

      expect(find.byKey(KochmodusTimerBar.stopKey('any')), findsNothing);
      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);
      // 5, 10 and 15 minutes.
      expect(find.byKey(KochmodusTimerSheet.choiceKey(2)), findsOneWidget);
      expect(find.byKey(KochmodusTimerSheet.choiceKey(3)), findsNothing);
      await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(1)));
      await harness.idle(tester);

      final timer = (await harness.storedRun(
        tester,
        'recipe-t1',
      )).timers.single;
      expect(timer.label, l10n.kochmodusTimerName(1));
      expect(
        timer.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 10))),
      );
      expect(timer.deviceId, device);
      expect(find.text(l10n.kochmodusTimerName(1)), findsOneWidget);
      expect(find.text(l10n.kochmodusTimerLeft(10, '00')), findsOneWidget);
      await close(tester);
    });

    testWidgets('names the next timer one higher', (tester) async {
      await open(
        tester,
        _run([_timer('t-1', 'Timer 1', const Duration(minutes: 5))]),
      );
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(0)));
      await harness.idle(tester);

      expect(find.text(l10n.kochmodusTimerName(2)), findsOneWidget);
      expect((await harness.storedRun(tester, 'recipe-t1')).timers.length, 2);
      await close(tester);
    });

    testWidgets('takes the lowest number no running timer carries', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _timer('t-1', 'Timer 1', const Duration(minutes: 5)),
          _timer('t-3', 'Timer 3', const Duration(minutes: 6)),
        ]),
      );
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(0)));
      await harness.idle(tester);

      final labels = [
        for (final timer in (await harness.storedRun(
          tester,
          'recipe-t1',
        )).timers)
          timer.label,
      ];
      expect(labels, contains(l10n.kochmodusTimerName(2)));
      expect(labels, hasLength(3));
      await close(tester);
    });

    testWidgets('the sheet stays quiet while exact alarms are allowed', (
      tester,
    ) async {
      await open(tester, _run(const []));

      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusTimerSheet.allowExactKey), findsNothing);
      await close(tester);
    });

    testWidgets('the sheet says exact alarms are off and allows them', (
      tester,
    ) async {
      harness.notifications
        ..exactAllowed = false
        // Reopening a running run asks nothing; the cook allows later.
        ..grantsExact = false;
      final run = _run(const []);
      await harness.store(tester, run);
      // The alarm listener keeps the controller of "Erlauben" alive.
      await harness.pumpApp(
        tester,
        initialLocation: AppRoutes.homeCookRunPath(run.id),
      );
      final l10n = harness.l10n(tester);
      // Reopening a running run asks for no exact alarms.
      expect(harness.notifications.permissionRequests, 1);
      expect(harness.notifications.exactRequests, 0);

      await tester.tap(find.byKey(KochmodusCookList.timerKey));
      await harness.idle(tester);

      expect(find.text(l10n.kochmodusTimerInexactHint), findsOneWidget);
      expect(find.text(l10n.kochmodusTimerAllowExact), findsOneWidget);

      harness.notifications.grantsExact = true;
      await tester.tap(find.byKey(KochmodusTimerSheet.allowExactKey));
      await harness.idle(tester);

      expect(harness.notifications.exactRequests, 1);
      expect(find.byKey(KochmodusTimerSheet.allowExactKey), findsNothing);
      await close(tester);
    });

    testWidgets('lists the running timers, the soonest first', (tester) async {
      await open(
        tester,
        _run([
          _timer('t-late', 'Reis', const Duration(minutes: 20)),
          _timer('t-soon', 'Nudeln', const Duration(minutes: 5, seconds: 5)),
        ]),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusTimerLeft(5, '05')), findsOneWidget);
      expect(find.text(l10n.kochmodusTimerLeft(20, '00')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Nudeln')).dy,
        lessThan(tester.getTopLeft(find.text('Reis')).dy),
      );
      await close(tester);
    });

    testWidgets('+1 Min rings the timer a minute later', (tester) async {
      await open(
        tester,
        _run([_timer('t-1', 'Nudeln', const Duration(minutes: 5))]),
      );
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusTimerBar.extendKey('t-1')));
      await harness.idle(tester);

      final stored = await harness.storedRun(tester, 'recipe-t1');
      expect(
        stored.timers.single.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 6))),
      );
      expect(find.text(l10n.kochmodusTimerLeft(6, '00')), findsOneWidget);
      await close(tester);
    });

    testWidgets('Stopp takes the timer away, and with it the bar', (
      tester,
    ) async {
      await open(
        tester,
        _run([
          _timer('t-1', 'Nudeln', const Duration(minutes: 5)),
          _timer('t-2', 'Reis', const Duration(minutes: 9)),
        ]),
      );

      await tester.tap(find.byKey(KochmodusTimerBar.stopKey('t-1')));
      await harness.idle(tester);

      expect(find.text('Nudeln'), findsNothing);
      expect(find.text('Reis'), findsOneWidget);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).timers.map((t) => t.id),
        ['t-2'],
      );

      await tester.tap(find.byKey(KochmodusTimerBar.stopKey('t-2')));
      await harness.idle(tester);
      expect(find.byKey(KochmodusTimerBar.stopKey('t-2')), findsNothing);
      expect(find.byKey(KochmodusTimerBar.extendKey('t-2')), findsNothing);
      await close(tester);
    });

    testWidgets('the rest time counts down with the clock', (tester) async {
      await open(
        tester,
        _run([_timer('t-1', 'Nudeln', const Duration(minutes: 5))]),
      );
      final l10n = harness.l10n(tester);
      expect(find.text(l10n.kochmodusTimerLeft(5, '00')), findsOneWidget);

      harness.now = kochmodusTestStart.add(
        const Duration(minutes: 4, seconds: 5),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n.kochmodusTimerLeft(0, '55')), findsOneWidget);
      expect(find.text(l10n.kochmodusTimerDone), findsNothing);
      await close(tester);
    });

    testWidgets('a timer that rang shows fertig, +1 Min brings it back', (
      tester,
    ) async {
      await open(
        tester,
        _run([_timer('t-1', 'Nudeln', const Duration(minutes: 5))]),
      );
      final l10n = harness.l10n(tester);

      harness.now = kochmodusTestStart.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n.kochmodusTimerDone), findsOneWidget);
      expect(find.byKey(KochmodusTimerBar.stopKey('t-1')), findsOneWidget);

      await tester.tap(find.byKey(KochmodusTimerBar.extendKey('t-1')));
      await harness.idle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(l10n.kochmodusTimerDone), findsNothing);
      expect(find.text(l10n.kochmodusTimerLeft(1, '00')), findsOneWidget);
      await close(tester);
    });

    testWidgets('a timer buzzes once and again after +1 Min', (tester) async {
      var buzzes = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate' &&
              call.arguments == 'HapticFeedbackType.heavyImpact') {
            buzzes++;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(
        tester,
        _run([_timer('t-1', 'Nudeln', const Duration(minutes: 5))]),
      );

      harness.now = kochmodusTestStart.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(buzzes, 1);

      await tester.tap(find.byKey(KochmodusTimerBar.extendKey('t-1')));
      await harness.idle(tester);
      harness.now = kochmodusTestStart.add(
        const Duration(minutes: 6, seconds: 1),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(buzzes, 2);
      await close(tester);
    });
  });
}
