import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_async_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_discard_menu.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_bar.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

CookRun _run({CookRunStep step = CookRunStep.pots}) => buildCookRun(
  step: step,
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
  lines: [
    textLine('line-0', '500 g Hackfleisch', settlement: const LineIgnored()),
    textLine('line-1', '200 g Karotten', settlement: const LineIgnored()),
  ],
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
  });

  Future<void> tapTab(WidgetTester tester, KochmodusStep step) async {
    await tester.tap(find.byKey(KochmodusStepBar.tabKey(step)));
    await harness.idle(tester);
  }

  testWidgets('free cooking opens "Töpfe" with the later tabs locked', (
    tester,
  ) async {
    await openPage(tester, harness, const KochmodusPage.free());

    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
    expect(KochmodusStep.values, [
      KochmodusStep.pots,
      KochmodusStep.cook,
      KochmodusStep.portion,
    ]);
    for (final step in KochmodusStep.values) {
      expect(find.byKey(KochmodusStepBar.tabKey(step)), findsOneWidget);
    }
    // The menu with "Verwerfen" needs a stored run.
    expect(find.byKey(KochmodusDiscardMenu.menuKey), findsNothing);

    await tapTab(tester, KochmodusStep.cook);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
    await tapTab(tester, KochmodusStep.portion);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
    // Nothing is stored before the pots are chosen.
    expect(
      await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
      isNull,
    );
  });

  testWidgets('a recipe run opens its cooking page with three tabs only', (
    tester,
  ) async {
    await harness.store(tester, _run());
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
    );

    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    expect(find.byKey(KochmodusDiscardMenu.menuKey), findsOneWidget);
    for (final step in KochmodusStep.values) {
      expect(find.byKey(KochmodusStepBar.tabKey(step)), findsOneWidget);
    }
    // A stored run opens every tab.
    await tapTab(tester, KochmodusStep.portion);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);
  });

  testWidgets('a run that does not exist says so and leads back', (
    tester,
  ) async {
    await openPage(tester, harness, const KochmodusPage.run(runId: 'nope'));

    expect(find.byKey(KochmodusAsyncView.goneBackKey), findsOneWidget);
    expect(
      find.byKey(KochmodusStepBar.tabKey(KochmodusStep.pots)),
      findsNothing,
    );
    await tester.tap(find.byKey(KochmodusAsyncView.goneBackKey));
    await harness.idle(tester);
    expect(find.byKey(homeKey), findsOneWidget);
  });

  testWidgets('a run that another device ends turns into the gone view', (
    tester,
  ) async {
    await harness.store(tester, _run());
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
    );
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);

    await tester.runAsync(() => harness.cook.removeRun('recipe-t1'));
    await harness.idle(tester);

    expect(find.byKey(KochmodusAsyncView.goneBackKey), findsOneWidget);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsNothing);
  });

  testWidgets('a stored run opens on its own step', (tester) async {
    await harness.store(tester, _run());
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
    );

    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
    expect(find.byType(KochmodusCookStep), findsNothing);
  });

  group('a recipe run whose lines need assigning', () {
    CookRun needing({CookRunStep step = CookRunStep.assign}) => buildCookRun(
      step: step,
      pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
      lines: [textLine('line-0', '500 g Hackfleisch')],
    );

    final assignRoute = GoRoute(
      path: AppRoutes.homeCook,
      builder: (context, state) =>
          KochmodusAssignPage(recipeId: state.pathParameters['recipeId']!),
    );

    testWidgets('opens "Zuweisen" in its place', (tester) async {
      await harness.store(tester, needing());
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
        routes: [assignRoute],
      );
      await tester.pumpAndSettle();

      expect(find.byType(KochmodusAssignPage), findsOneWidget);
      expect(find.byType(KochmodusPage), findsNothing);
      expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
      // The cooking page is replaced, not stacked: back leaves for home.
      await tester.tap(find.byTooltip('Back'));
      await harness.idle(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(homeKey), findsOneWidget);
    });

    testWidgets('does so also for a paused run', (tester) async {
      await harness.store(
        tester,
        needing(step: CookRunStep.paused).copyWith(
          lines: [
            textLine(
              'line-0',
              '500 g Hackfleisch',
              settlement: const LineShopping(),
            ),
          ],
        ),
      );
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
        routes: [assignRoute],
      );
      await tester.pumpAndSettle();

      expect(find.byType(KochmodusAssignPage), findsOneWidget);
    });

    testWidgets('stays on the cooking page once nothing needs assigning', (
      tester,
    ) async {
      await harness.store(tester, _run());
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
        routes: [assignRoute],
      );
      await tester.pumpAndSettle();

      expect(find.byType(KochmodusAssignPage), findsNothing);
      expect(find.byType(KochmodusPage), findsOneWidget);
    });

    testWidgets('a line that comes in while cooking does not count', (
      tester,
    ) async {
      await harness.store(
        tester,
        buildCookRun(
          step: CookRunStep.cook,
          pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
          lines: [
            textLine('line-0', 'Salz', settlement: const LineIgnored()),
            cookedLine('line-1', '100 g Sahne'),
          ],
        ),
      );
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
        routes: [assignRoute],
      );
      await tester.pumpAndSettle();

      expect(find.byType(KochmodusAssignPage), findsNothing);
      expect(find.byType(KochmodusPage), findsOneWidget);
    });

    testWidgets('looks only once: a later open line does not move the cook', (
      tester,
    ) async {
      await harness.store(tester, _run());
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
        routes: [assignRoute],
      );

      // Another device adds a line to assign while this one shows "Töpfe".
      await tester.runAsync(
        () => harness.cook.runs.mutate(
          'recipe-t1',
          (run) =>
              run.copyWith(lines: [...run.lines, textLine('line-9', '1 Ei')]),
        ),
      );
      await harness.idle(tester);
      await tester.pumpAndSettle();

      expect(find.byType(KochmodusAssignPage), findsNothing);
      expect(find.byType(KochmodusPage), findsOneWidget);
    });
  });

  testWidgets('the screen stays on while "Kochen" shows', (tester) async {
    final wake = <bool>[];
    await harness.store(tester, _run(step: CookRunStep.cook));
    await openPage(
      tester,
      harness,
      const KochmodusPage.run(runId: 'recipe-t1'),
      wake: wake,
    );
    expect(wake, [true]);

    await tapTab(tester, KochmodusStep.pots);
    expect(wake, [true, false]);

    await tapTab(tester, KochmodusStep.cook);
    expect(wake, [true, false, true]);

    await tester.tap(find.byTooltip('Back'));
    await harness.idle(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(homeKey), findsOneWidget);
    expect(wake, [true, false, true, false]);
  });

  testWidgets(
    '"Verwerfen" deletes the run, leaves, and "Rückgängig" restores',
    (tester) async {
      await harness.store(tester, _run());
      await openPage(
        tester,
        harness,
        const KochmodusPage.run(runId: 'recipe-t1'),
      );

      await tester.tap(find.byKey(KochmodusDiscardMenu.menuKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusDiscardMenu.discardKey));
      await harness.idle(tester);

      expect(find.byKey(homeKey), findsOneWidget);
      expect(find.byKey(KochmodusActionFlow.discardedKey), findsOneWidget);
      expect(
        await tester.runAsync(() => harness.cook.storedRun('recipe-t1')),
        isNull,
      );

      await tester.tap(find.text('Undo'));
      await harness.idle(tester);
      final restored = await harness.storedRun(tester, 'recipe-t1');
      expect(restored.lines.map((line) => line.id), ['line-0', 'line-1']);
    },
  );
}
