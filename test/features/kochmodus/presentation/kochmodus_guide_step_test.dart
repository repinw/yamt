import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_guide_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foods.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _steps = [
  'Zwiebeln anschwitzen.',
  'Nudeln 8-10 Minuten kochen.',
  'Servieren.',
];

CookRun _run({
  int guideStep = 0,
  List<CookTimer> timers = const [],
  List<String> steps = _steps,
}) => buildCookRun(
  step: CookRunStep.cook,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: steps,
  timers: timers,
  lines: [textLine('l-flour', 'Mehl', settlement: const LineIgnored())],
).useGuide(on: true).guideTo(guideStep);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  // Takes the page down, so no timer of the page is left running.
  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('Kochhelfer', () {
    testWidgets('shows one instruction as Schritt N von M', (tester) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      expect(
        find.text(l10n.kochmodusGuideProgress(1, 3).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(_steps[0]), findsOneWidget);
      expect(find.text(_steps[1]), findsNothing);
      // No time in it, so no timer button; the first step goes back to the
      // pots.
      expect(find.byKey(KochmodusGuideStep.timerKey(0)), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(KochmodusGuideStep.backKey))
            .onPressed,
        isNotNull,
      );
      expect(find.byKey(KochmodusGuideStep.nextKey), findsOneWidget);
      expect(find.byKey(KochmodusGuideStep.portionKey), findsNothing);
      await close(tester);
    });

    testWidgets('Nächster Schritt and Zurück move through the steps', (
      tester,
    ) async {
      await open(tester, _run());
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusGuideStep.nextKey));
      await harness.idle(tester);
      expect(
        find.text(l10n.kochmodusGuideProgress(2, 3).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(_steps[1]), findsOneWidget);
      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 1);

      await tester.tap(find.byKey(KochmodusGuideStep.backKey));
      await harness.idle(tester);
      expect(find.text(_steps[0]), findsOneWidget);
      expect((await harness.storedRun(tester, 'recipe-t1')).guideStep, 0);
      await close(tester);
    });

    testWidgets('"Zurück" on the first step shows the pots', (tester) async {
      await open(tester, _run());
      expect(find.byType(KochmodusPotsStep), findsNothing);

      await tester.tap(find.byKey(KochmodusGuideStep.backKey));
      await harness.idle(tester);

      expect(find.byType(KochmodusPotsStep), findsOneWidget);
      expect(find.byKey(KochmodusGuideStep.nextKey), findsNothing);
      await close(tester);
    });

    testWidgets('"Zurück" on the second step goes to the first', (
      tester,
    ) async {
      await open(tester, _run(guideStep: 1));

      await tester.tap(find.byKey(KochmodusGuideStep.backKey));
      await harness.idle(tester);

      expect(find.byType(KochmodusPotsStep), findsNothing);
      expect(find.text(_steps[0]), findsOneWidget);
      await close(tester);
    });

    testWidgets('the last step ends with Fertig · Portionieren', (
      tester,
    ) async {
      await open(tester, _run(guideStep: 2));
      final l10n = harness.l10n(tester);

      expect(find.byKey(KochmodusGuideStep.nextKey), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(KochmodusGuideStep.portionKey),
          matching: find.text(l10n.kochmodusToPortion),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(KochmodusGuideStep.portionKey));
      await harness.idle(tester);

      expect(find.byKey(KochmodusGuideStep.portionKey), findsNothing);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).step,
        CookRunStep.portion,
      );
      await close(tester);
    });

    testWidgets('a time in the step is a button that starts a timer', (
      tester,
    ) async {
      await open(tester, _run(guideStep: 1));
      final l10n = harness.l10n(tester);
      final device = await harness.deviceId(tester);

      // "8-10 Minuten" is one button for the span.
      expect(find.text(l10n.kochmodusTimerMinuteRange(8, 10)), findsOneWidget);
      expect(find.byKey(KochmodusGuideStep.timerKey(1)), findsNothing);

      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(0)));
      await harness.idle(tester);
      // The sheet offers each minute of the span; the later one starts.
      expect(find.byKey(KochmodusTimerSheet.choiceKey(0)), findsOneWidget);
      await tester.tap(find.byKey(KochmodusTimerSheet.choiceKey(1)));
      await harness.idle(tester);

      final timer = (await harness.storedRun(
        tester,
        'recipe-t1',
      )).timers.single;
      expect(timer.label, l10n.kochmodusGuideTimerLabel(2));
      expect(
        timer.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 10))),
      );
      expect(timer.deviceId, device);
      expect(find.text(timer.label), findsOneWidget);
      expect(find.text(l10n.kochmodusTimerLeft(10, '00')), findsOneWidget);
      await close(tester);
    });

    testWidgets('a step with several times numbers its timers', (tester) async {
      await open(
        tester,
        _run(steps: const ['10 Minuten kochen, dann 5 Minuten ziehen.']),
      );
      final l10n = harness.l10n(tester);

      // One time: a tap starts the timer, no sheet.
      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(1)));
      await harness.idle(tester);

      expect(find.byKey(KochmodusTimerSheet.choiceKey(0)), findsNothing);
      final timer = (await harness.storedRun(
        tester,
        'recipe-t1',
      )).timers.single;
      expect(timer.label, l10n.kochmodusGuideTimerLabelNumbered(1, 2));
      await close(tester);
    });

    testWidgets('one time starts the timer at once, a span still asks', (
      tester,
    ) async {
      await open(
        tester,
        _run(
          steps: const ['10 Minuten kochen.', 'Nudeln 8-10 Minuten kochen.'],
        ),
      );

      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(0)));
      await harness.idle(tester);

      expect(find.byKey(KochmodusTimerSheet.choiceKey(0)), findsNothing);
      final timer = (await harness.storedRun(
        tester,
        'recipe-t1',
      )).timers.single;
      expect(
        timer.endsAt,
        atMoment(kochmodusTestStart.add(const Duration(minutes: 10))),
      );
      await close(tester);
    });

    testWidgets('two quick taps on the time of a step start one timer', (
      tester,
    ) async {
      await open(tester, _run(steps: const ['10 Minuten kochen.']));
      final l10n = harness.l10n(tester);

      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(0)));
      await tester.tap(find.byKey(KochmodusGuideStep.timerKey(0)));
      await harness.idle(tester);

      final timers = (await harness.storedRun(tester, 'recipe-t1')).timers;
      expect(timers, hasLength(1));
      // One row in the timer bar.
      expect(find.text(l10n.kochmodusGuideTimerLabel(1)), findsOneWidget);
      await close(tester);
    });

    group('the hint when timers may not ring', () {
      const asked = 'cook_timer_permissions_asked_v2';

      Future<void> openGuide(WidgetTester tester) async {
        final run = _run(guideStep: 1);
        await harness.store(tester, run);
        // The alarm listener keeps the controller of "Erlauben" alive.
        await harness.pumpApp(
          tester,
          initialLocation: AppRoutes.homeCookRunPath(run.id),
        );
      }

      testWidgets('blocked notifications show their hint with "Erlauben"', (
        tester,
      ) async {
        await harness.preferences.setString(asked, 'set');
        harness.notifications
          ..allowed = false
          ..exactAllowed = false;

        await openGuide(tester);
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
        await close(tester);
      });

      testWidgets('inexact alarms show the exact-alarm hint', (tester) async {
        await harness.preferences.setString(asked, 'set');
        harness.notifications.exactAllowed = false;

        await openGuide(tester);

        expect(find.byKey(KochmodusTimerSheet.allowExactKey), findsOneWidget);
        expect(
          find.byKey(KochmodusTimerSheet.allowNotificationsKey),
          findsNothing,
        );
        await close(tester);
      });

      testWidgets('timers that ring on time show no hint', (tester) async {
        await harness.preferences.setString(asked, 'set');

        await openGuide(tester);

        expect(find.byKey(KochmodusGuideStep.timerKey(0)), findsOneWidget);
        expect(find.byKey(KochmodusTimerSheet.allowExactKey), findsNothing);
        expect(
          find.byKey(KochmodusTimerSheet.allowNotificationsKey),
          findsNothing,
        );
        await close(tester);
      });
    });

    testWidgets('added lines are "cleared up at the portions" while one is '
        'open', (tester) async {
      await open(tester, _run().addLine(cookedLine('new-1', 'Reis')));
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusGuideAdded), findsOneWidget);
      expect(find.text(l10n.kochmodusGuideAddedSettled), findsNothing);
      await close(tester);
    });

    testWidgets('added lines that are all settled get the plain title', (
      tester,
    ) async {
      await open(
        tester,
        _run().addLine(
          cookedLine('new-2', 'Reis', settlement: const LineIgnored()),
        ),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusGuideAddedSettled), findsOneWidget);
      expect(find.text(l10n.kochmodusGuideAdded), findsNothing);
      await close(tester);
    });

    testWidgets('the list button shows all ingredients and back again', (
      tester,
    ) async {
      await open(tester, _run());

      await tester.tap(find.byKey(KochmodusGuideStep.listKey));
      await harness.idle(tester);
      expect(find.byKey(KochmodusCookList.guideKey), findsOneWidget);
      expect(find.byKey(KochmodusGuideStep.nextKey), findsNothing);
      expect((await harness.storedRun(tester, 'recipe-t1')).withGuide, isFalse);

      await tester.tap(find.byKey(KochmodusCookList.guideKey));
      await harness.idle(tester);
      expect(find.byKey(KochmodusGuideStep.nextKey), findsOneWidget);
      expect((await harness.storedRun(tester, 'recipe-t1')).withGuide, isTrue);
      await close(tester);
    });

    testWidgets('a line that came in shows as a chip that can go again', (
      tester,
    ) async {
      final run = _run().addLine(cookedLine('new-1', 'Reis'));
      await open(tester, run);
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.kochmodusGuideAdded), findsOneWidget);
      expect(find.text('Reis'), findsOneWidget);

      await tester.tap(find.byKey(KochmodusGuideStep.removeKey('new-1')));
      await harness.idle(tester);

      expect(find.text('Reis'), findsNothing);
      expect(find.text(l10n.kochmodusGuideAdded), findsNothing);
      expect(
        (await harness.storedRun(tester, 'recipe-t1')).lines.map((l) => l.id),
        ['l-flour'],
      );
      await close(tester);
    });
  });
  group('the foods a step names', () {
    final milk = stockItem(
      'milk',
      1000,
      unit: InventoryAmountUnit.milliliter,
    ).copyWith(name: 'Milch');
    final sugar = stockItem('sugar', 500).copyWith(name: 'Zucker');

    CookRun foodsRun({int guideStep = 0}) => buildCookRun(
      step: CookRunStep.cook,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      steps: const [
        'Milch mit Salz aufkochen.',
        'Zucker dazugeben.',
        'Alles gut umrühren.',
      ],
      lines: [
        textLine('l-milk', '1 l Milch', settlement: assigned({'milk': 1000})),
        textLine('l-salt', '1 Prise Salz', settlement: const LineIgnored()),
        textLine('l-sugar', 'Zucker', settlement: assigned({'sugar': 50})),
      ],
    ).useGuide(on: true).guideTo(guideStep);

    Future<void> openFoods(WidgetTester tester, {int guideStep = 0}) async {
      await harness.stock(tester, [milk, sugar]);
      await open(tester, foodsRun(guideStep: guideStep));
    }

    Finder inBlock(Finder finder) => find.descendant(
      of: find.byKey(KochmodusStepFoods.blockKey),
      matching: finder,
    );

    testWidgets('one row per food under the sentence, amount and food as '
        'text', (tester) async {
      await openFoods(tester);

      expect(find.byKey(KochmodusStepFoods.blockKey), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(KochmodusStepFoods.rowKey('l-milk')))
            .data,
        'Milch',
      );
      expect(
        tester
            .widget<Text>(find.byKey(KochmodusStepFoods.rowKey('l-salt')))
            .data,
        'Salz',
      );
      expect(inBlock(find.text('1000\u00A0ml')).evaluate(), isEmpty);
      expect(inBlock(find.text('1000 ml')), findsOneWidget);
      expect(inBlock(find.text('1 Prise')), findsOneWidget);
      expect(find.byKey(KochmodusStepFoods.rowKey('l-sugar')), findsNothing);
      // Under the sentence.
      expect(
        tester.getTopLeft(find.byKey(KochmodusStepFoods.blockKey)).dy,
        greaterThan(
          tester.getBottomLeft(find.text('Milch mit Salz aufkochen.')).dy - 1,
        ),
      );
      await close(tester);
    });

    testWidgets('a food without an amount shows its name alone', (
      tester,
    ) async {
      await openFoods(tester, guideStep: 1);

      final shown = tester
          .widgetList<Text>(inBlock(find.byType(Text)))
          .map((text) => text.data)
          .where((text) => text != null && text.isNotEmpty);
      expect(shown, ['Zucker']);
      await close(tester);
    });

    testWidgets('a step that names no line has no block', (tester) async {
      await openFoods(tester, guideStep: 2);

      expect(find.byKey(KochmodusStepFoods.blockKey), findsNothing);
      expect(find.text('Alles gut umrühren.'), findsOneWidget);
      await close(tester);
    });
  });

  group('Kochhelfer header at a large text', () {
    testWidgets('German at 360 dp and scale 2 does not overflow', (
      tester,
    ) async {
      final run = _run();
      await harness.store(tester, run);

      await harness.pumpRun(
        tester,
        run.id,
        width: 360,
        textScale: 2,
        locale: const Locale('de'),
      );
      final l10n = harness.l10n(tester);

      expect(find.text(l10n.cookingGuideKeepsScreenOn), findsOneWidget);
      await close(tester);
    });
  });
}
