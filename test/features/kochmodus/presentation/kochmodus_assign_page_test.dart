import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_assign_page.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_page.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_async_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_card_answers.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_discard_menu.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_pots_step.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';
import 'kochmodus_page_harness.dart';

const _runId = 'recipe-t1';

// What "Kochen" replaces the page with.
final _cookRoute = GoRoute(
  path: AppRoutes.homeCookRun,
  builder: (context, state) =>
      KochmodusPage.run(runId: state.pathParameters['runId']!),
);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async {
    harness = await KochmodusCookingHarness.open();
    addRecipe(harness, kochmodusRecipe());
  });

  Future<void> open(
    WidgetTester tester, {
    String recipeId = 't1',
    int? portions,
  }) => openPage(
    tester,
    harness,
    KochmodusAssignPage(recipeId: recipeId, portions: portions),
    routes: [_cookRoute],
  );

  Future<CookRun?> stored(WidgetTester tester) =>
      tester.runAsync<CookRun?>(() => harness.cook.storedRun(_runId));

  CookRun storedRun({
    CookRunStep step = CookRunStep.assign,
    bool settled = false,
  }) => buildCookRun(
    step: step,
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    lines: [
      textLine(
        'line-0',
        '500 g Hackfleisch',
        settlement: settled ? const LineIgnored() : const LineOpen(),
      ),
    ],
  );

  testWidgets('starting to cook asks first for what the timers need', (
    tester,
  ) async {
    await open(tester);

    expect(harness.notifications.permissionRequests, 1);
  });

  testWidgets('a recipe without a run shows its lines and stores nothing', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(KochmodusAssignPage), findsOneWidget);
    // One line on the card, every line in "Alle Zutaten".
    expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
    expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
    expect(find.byKey(KochmodusIngredientRow.rowKey('line-0')), findsOne);
    expect(find.byKey(KochmodusIngredientRow.rowKey('line-1')), findsOne);
    // The first change stores the draft, not opening the page.
    expect(await stored(tester), isNull);
  });

  testWidgets('the portions of the route are the portions cooked', (
    tester,
  ) async {
    await open(tester, portions: 6);
    final l10n = harness.l10n(tester);

    // The ready card names them once every line is answered.
    await tester.tap(find.byKey(KochmodusCardAnswers.ignoreKey));
    await harness.idle(tester);
    await tester.tap(find.byKey(KochmodusCardAnswers.ignoreKey));
    await harness.idle(tester);

    expect(find.text(l10n.kochmodusAssignReadyText(6)), findsOneWidget);
    expect((await stored(tester))!.portions, 6);
  });

  testWidgets('the first change stores the draft on "Zuweisen"', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(KochmodusCardAnswers.ignoreKey));
    await harness.idle(tester);

    final run = (await stored(tester))!;
    expect(run.step, CookRunStep.assign);
    expect(run.pots, isNull);
    expect(run.lineOf('line-0')!.settlement, isA<LineIgnored>());
    expect(run.lineOf('line-1')!.settlement, isA<LineOpen>());
  });

  testWidgets('there is no "Verwerfen" before the run is stored', (
    tester,
  ) async {
    await open(tester);

    expect(find.byKey(KochmodusDiscardMenu.menuKey), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets(
    '"Verwerfen" deletes the run, leaves, and "Rückgängig" restores',
    (tester) async {
      await harness.store(tester, storedRun());
      await open(tester);

      await tester.tap(find.byKey(KochmodusDiscardMenu.menuKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusDiscardMenu.discardKey));
      await harness.idle(tester);

      expect(find.byKey(homeKey), findsOneWidget);
      expect(find.byKey(KochmodusActionFlow.discardedKey), findsOneWidget);
      expect(await stored(tester), isNull);

      await tester.tap(find.text('Undo'));
      await harness.idle(tester);
      final restored = await harness.storedRun(tester, _runId);
      expect(restored.lines.map((line) => line.id), ['line-0']);
    },
  );

  testWidgets('back leaves and keeps the run', (tester) async {
    await harness.store(tester, storedRun());
    await open(tester);

    await tester.tap(find.byTooltip('Back'));
    await harness.idle(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(homeKey), findsOneWidget);
    expect((await stored(tester))!.step, CookRunStep.assign);
  });

  testWidgets('"Später" leaves and keeps the run', (tester) async {
    await harness.store(tester, storedRun());
    await open(tester);

    await tester.tap(find.byKey(KochmodusReadyCard.laterKey));
    await harness.idle(tester);

    expect(find.byKey(homeKey), findsOneWidget);
    expect(await stored(tester), storedRun());
  });

  testWidgets('"Kochen" stores "Töpfe" and replaces the page', (tester) async {
    await harness.store(tester, storedRun(settled: true));
    await open(tester);

    await tester.tap(find.byKey(KochmodusReadyCard.mainKey));
    await harness.idle(tester);
    await tester.pumpAndSettle();

    expect((await stored(tester))!.step, CookRunStep.pots);
    expect(find.byType(KochmodusAssignPage), findsNothing);
    expect(find.byType(KochmodusPage), findsOneWidget);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
  });

  testWidgets('"Kochen" of a draft creates the run first', (tester) async {
    // "Salz" does not count, so the draft starts with it left out and the
    // card is the ready one.
    addRecipe(harness, kochmodusRecipe(ingredients: const ['Salz']));
    await open(tester);
    expect(await stored(tester), isNull);

    await tester.tap(find.byKey(KochmodusReadyCard.mainKey));
    await harness.idle(tester);
    await tester.pumpAndSettle();

    expect((await stored(tester))!.step, CookRunStep.pots);
    expect(find.byKey(KochmodusPotsStep.nextKey), findsOneWidget);
  });

  testWidgets('a paused run opens its shopping lines again, once', (
    tester,
  ) async {
    await harness.store(
      tester,
      storedRun(step: CookRunStep.paused).copyWith(
        lines: [
          textLine(
            'line-0',
            '500 g Hackfleisch',
            settlement: const LineShopping(),
          ),
        ],
      ),
    );
    await open(tester);
    final l10n = harness.l10n(tester);

    final run = (await stored(tester))!;
    expect(run.step, CookRunStep.assign);
    expect(run.lineOf('line-0')!.settlement, isA<LineOpen>());
    expect(find.text(l10n.kochmodusAssignReopenedHint), findsOneWidget);
    expect(find.byKey(KochmodusAssignStep.cardKey), findsOneWidget);
    expect(find.byKey(KochmodusCardAnswers.haveKey), findsOneWidget);
  });

  testWidgets('a recipe that does not exist says so and leads back', (
    tester,
  ) async {
    await open(tester, recipeId: 'nope');

    expect(find.byKey(KochmodusAsyncView.goneBackKey), findsOneWidget);
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
    await tester.tap(find.byKey(KochmodusAsyncView.goneBackKey));
    await harness.idle(tester);
    expect(find.byKey(homeKey), findsOneWidget);
  });

  testWidgets('a run that another device ends turns into the gone view', (
    tester,
  ) async {
    await harness.store(tester, storedRun(settled: true));
    await open(tester);
    expect(find.byKey(KochmodusReadyCard.mainKey), findsOneWidget);

    await tester.runAsync(() => harness.cook.removeRun(_runId));
    await harness.idle(tester);

    expect(find.byKey(KochmodusAsyncView.goneBackKey), findsOneWidget);
    expect(find.byKey(KochmodusReadyCard.mainKey), findsNothing);
  });
}
