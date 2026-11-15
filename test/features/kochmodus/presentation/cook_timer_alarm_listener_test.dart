import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/application/cook_timer_alarms.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _runId = 'recipe-t1';

CookTimer _timer(String id, Duration left, {String deviceId = 'this'}) =>
    CookTimer(
      id: id,
      label: 'Nudeln',
      endsAt: kochmodusTestStart.add(left),
      deviceId: deviceId,
    );

CookRun _run([List<CookTimer> timers = const []]) => buildCookRun(
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

  Future<void> change(
    WidgetTester tester,
    CookRun Function(CookRun run) edit,
  ) async {
    await tester.runAsync(() => harness.cook.runs.mutate(_runId, edit));
    await harness.idle(tester);
  }

  // The timer of this device, which the install id names.
  Future<CookTimer> mine(WidgetTester tester, Duration left) async =>
      _timer('t-1', left, deviceId: await harness.deviceId(tester));

  group('CookTimerAlarmListener', () {
    testWidgets('schedules the timer this device started', (tester) async {
      final timer = await mine(tester, const Duration(minutes: 5));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);
      final l10n = harness.l10n(tester);

      final id = cookTimerNotificationId('t-1');
      expect(harness.notifications.scheduled.keys, [id]);
      final scheduled = harness.notifications.scheduled[id]!;
      expect(scheduled.at, atMoment(timer.endsAt));
      expect(scheduled.title, l10n.kochmodusTimerAlarmTitle('Nudeln'));
      expect(scheduled.payload, cookTimerPayload(_runId));
      // The first timer asks once for the permission.
      expect(harness.notifications.permissionRequests, 1);
    });

    testWidgets('a timer of another device does not ring here', (tester) async {
      await harness.store(
        tester,
        _run([_timer('t-1', const Duration(minutes: 5), deviceId: 'other')]),
      );
      await harness.pumpApp(tester);

      expect(harness.notifications.scheduled, isEmpty);
      expect(harness.notifications.permissionRequests, 0);
    });

    testWidgets('a timer that ran out is not scheduled', (tester) async {
      final timer = await mine(tester, const Duration(minutes: -1));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);

      expect(harness.notifications.scheduled, isEmpty);
    });

    testWidgets('a timer started later is scheduled when the run changes', (
      tester,
    ) async {
      await harness.store(tester, _run());
      await harness.pumpApp(tester);
      expect(harness.notifications.scheduled, isEmpty);

      final timer = await mine(tester, const Duration(minutes: 5));
      await change(tester, (run) => run.addTimer(timer));

      expect(harness.notifications.scheduled.keys, [
        cookTimerNotificationId('t-1'),
      ]);
    });

    testWidgets('+1 Min moves the notification to the new time', (
      tester,
    ) async {
      final timer = await mine(tester, const Duration(minutes: 5));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);

      await change(
        tester,
        (run) => run.extendTimer(
          't-1',
          const Duration(minutes: 1),
          now: kochmodusTestStart,
        ),
      );

      expect(
        harness.notifications.scheduled[cookTimerNotificationId('t-1')]!.at,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 6))),
      );
      expect(harness.notifications.scheduled.length, 1);
    });

    testWidgets('Stopp cancels the notification', (tester) async {
      final timer = await mine(tester, const Duration(minutes: 5));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);
      expect(harness.notifications.scheduled.length, 1);

      await change(tester, (run) => run.stopTimer('t-1'));

      expect(harness.notifications.scheduled, isEmpty);
    });

    testWidgets('a run that ended cancels its notifications', (tester) async {
      final timer = await mine(tester, const Duration(minutes: 5));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);
      expect(harness.notifications.scheduled.length, 1);

      await tester.runAsync(() => harness.cook.removeRun(_runId));
      await harness.idle(tester);

      expect(harness.notifications.scheduled, isEmpty);
    });

    testWidgets('without the household key no notification is cancelled', (
      tester,
    ) async {
      final id = cookTimerNotificationId('t-1');
      final at = kochmodusTestStart.add(const Duration(minutes: 5));
      harness.householdReady = false;
      // Scheduled before, as in the last session; the runs read empty now.
      await harness.notifications.schedule(
        id: id,
        at: at,
        channel: (id: 'cook_timer', name: 'Timer'),
        title: 'Nudeln',
        body: 'Eintopf',
        payload: cookTimerPayload(_runId),
      );
      await harness.pumpApp(tester);

      expect(harness.notifications.scheduled.keys, [id]);
    });

    testWidgets('a tap opens the run', (tester) async {
      final timer = await mine(tester, const Duration(minutes: 5));
      await harness.store(tester, _run([timer]));
      await harness.pumpApp(tester);
      expect(find.byKey(homeKey), findsOneWidget);

      harness.notifications.tap(cookTimerPayload(_runId));
      await harness.idle(tester);

      expect(
        find.byType(KochmodusPage),
        findsOneWidget,
        reason: '${harness.router.routerDelegate.currentConfiguration.matches}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a tap on the open run does not open it twice', (tester) async {
      await harness.store(tester, _run());
      await harness.pumpApp(tester);
      unawaited(harness.router.push<void>(AppRoutes.homeCookRunPath(_runId)));
      await harness.idle(tester);
      expect(find.byType(KochmodusPage), findsOneWidget);

      harness.notifications.tap(cookTimerPayload(_runId));
      await harness.idle(tester);
      harness.router.routerDelegate.navigatorKey.currentState!.pop();
      await harness.idle(tester);

      // One page was on the stack, so one pop is back at the home.
      expect(find.byType(KochmodusPage), findsNothing);
      expect(find.byKey(homeKey), findsOneWidget);
    });

    testWidgets('a tap that brings the app back opens the run', (tester) async {
      await harness.store(tester, _run());
      await harness.pumpApp(tester);
      final binding = tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);

      harness.notifications.tap(cookTimerPayload(_runId));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await harness.idle(tester);

      expect(find.byType(KochmodusPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a tap before sign-in waits for the home', (tester) async {
      await harness.store(tester, _run());
      await harness.pumpApp(tester, initialLocation: awayPath);
      expect(find.byKey(awayKey), findsOneWidget);

      harness.notifications.tap(cookTimerPayload(_runId));
      await harness.idle(tester);
      expect(find.byType(KochmodusPage), findsNothing);

      harness.router.go(AppRoutes.homeInventoryTemplates);
      await harness.idle(tester);

      expect(find.byType(KochmodusPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a tap of another notification opens nothing', (tester) async {
      await harness.store(tester, _run());
      await harness.pumpApp(tester);

      harness.notifications.tap('plan-reminder:today');
      await harness.idle(tester);

      expect(find.byType(KochmodusPage), findsNothing);
      expect(find.byKey(homeKey), findsOneWidget);
    });
  });
}
