import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_running_section.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../support/prepared_meal_test_data.dart';
import '../../../kochmodus/kochmodus_fixtures.dart';
import '../../../recipes/cook_run_fixtures.dart';

final _now = DateTime(2026, 11, 7, 20);

CookbookRun _row(
  CookRun run, {
  bool startedByMe = true,
  CookTimer? nextTimer,
}) => CookbookRun(run: run, startedByMe: startedByMe, nextTimer: nextTimer);

Future<GoRouter> _pump(
  WidgetTester tester, {
  List<CookbookRun> runs = const [],
  List<PreparedMeal> openMeals = const [],
  void Function(PreparedMeal meal)? onContinueMeal,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: CookbookRunningSection(
              runs: runs,
              openMeals: openMeals,
              onContinueMeal: onContinueMeal ?? (_) {},
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeCook,
        builder: (context, state) =>
            Text('assign ${state.pathParameters['recipeId']}'),
      ),
      GoRoute(
        path: '/home/cook-run/:runId',
        builder: (context, state) =>
            Text('run ${state.pathParameters['runId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clockProvider.overrideWithValue(() => _now)],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('names each step of a run', (tester) async {
    await _pump(
      tester,
      runs: [
        _row(buildCookRun(id: 'pots', step: CookRunStep.pots)),
        _row(buildCookRun(id: 'assign')),
        _row(buildCookRun(id: 'paused', step: CookRunStep.paused)),
        _row(buildCookRun(id: 'cook', step: CookRunStep.cook)),
        _row(buildCookRun(id: 'portion', step: CookRunStep.portion)),
      ],
    );

    expect(find.text('Choose pots'), findsOneWidget);
    // Both lines of the fixture are still open.
    expect(find.text('2 still open'), findsOneWidget);
    expect(find.text('Paused until shopped'), findsOneWidget);
    expect(find.text('Cooking'), findsOneWidget);
    expect(find.text('Portioning'), findsOneWidget);
    expect(find.text('5 IN THE HOUSEHOLD'), findsOneWidget);
  });

  testWidgets('an assign step without open lines says all is ready', (
    tester,
  ) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            lines: [cookLine('line-0', settlement: const LineIgnored())],
          ),
        ),
      ],
    );

    expect(find.text('All ready'), findsOneWidget);
  });

  testWidgets('an assign step with lines on the list names the shopping', (
    tester,
  ) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            lines: [
              cookLine('line-0', settlement: const LineShopping()),
              cookLine('line-1', settlement: const LineIgnored()),
            ],
          ),
        ),
      ],
    );

    expect(find.text('1 on the shopping list'), findsOneWidget);
    expect(find.text('All ready'), findsNothing);
  });

  testWidgets('an open line comes before the shopping lines', (tester) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            lines: [
              cookLine('line-0'),
              cookLine('line-1', settlement: const LineShopping()),
            ],
          ),
        ),
      ],
    );

    expect(find.text('1 still open'), findsOneWidget);
    expect(find.text('1 on the shopping list'), findsNothing);
  });

  testWidgets('a cooking run with a timer names when it rings', (tester) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(step: CookRunStep.cook),
          nextTimer: CookTimer(
            id: 't',
            label: 'Nudeln',
            endsAt: DateTime(2026, 11, 7, 20, 30),
            deviceId: 'dev',
          ),
        ),
      ],
    );

    expect(find.text('Cooking · timer until 8:30 PM'), findsOneWidget);
  });

  testWidgets('a free cooking run is titled "Free cooking"', (tester) async {
    final free = CookRun.fromJson({
      ...buildCookRun(id: 'free', step: CookRunStep.cook).toJson(),
      'name': '',
    });
    await _pump(tester, runs: [_row(free)]);

    expect(find.text('Free cooking'), findsOneWidget);
    expect(find.text('Cooking'), findsOneWidget);
  });

  testWidgets('a paused run counts what is still to buy', (tester) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            step: CookRunStep.paused,
            lines: [
              cookLine('a', settlement: const LineShopping()),
              cookLine('b', settlement: const LineShopping()),
              cookLine('c', settlement: const LineIgnored()),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Paused until shopped · 2 to buy'), findsOneWidget);
  });

  testWidgets('a guided run without a timer names the step', (tester) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(step: CookRunStep.cook)
              .copyWith(withGuide: true, guideStep: 1),
        ),
      ],
    );

    expect(find.text('Cooking · step 2'), findsOneWidget);
  });

  testWidgets('says "you" for my run and the name for another member', (
    tester,
  ) async {
    await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(id: 'mine', startedAt: DateTime(2026, 11, 7, 18, 30)),
        ),
        _row(
          buildCookRun(id: 'theirs', startedAt: DateTime(2026, 11, 3, 9)),
          startedByMe: false,
        ),
      ],
    );

    expect(find.text('you · since 6:30 PM'), findsOneWidget);
    expect(find.text('Ada · since Nov 3'), findsOneWidget);
  });

  testWidgets('"Weiter" opens the cook run once its lines are assigned', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            step: CookRunStep.cook,
            lines: [
              textLine('line-0', 'Salz', settlement: const LineIgnored()),
            ],
          ),
        ),
      ],
    );

    await tester.tap(
      find.byKey(CookbookRunningSection.continueKey('recipe-t1')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), AppRoutes.homeCookRunPath('recipe-t1'));
    expect(find.text('run recipe-t1'), findsOneWidget);
  });

  testWidgets('"Weiter" of a run with lines to assign opens "Zuweisen"', (
    tester,
  ) async {
    final run = buildCookRun();
    expect(run.needsAssigning, isTrue);
    final router = await _pump(tester, runs: [_row(run)]);

    await tester.tap(
      find.byKey(CookbookRunningSection.continueKey('recipe-t1')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), AppRoutes.homeCookPath('t1'));
    expect(find.text('assign t1'), findsOneWidget);
  });

  testWidgets('"Weiter" of a paused run opens "Zuweisen" too', (tester) async {
    final router = await _pump(
      tester,
      runs: [
        _row(
          buildCookRun(
            step: CookRunStep.paused,
            lines: [
              textLine('line-0', 'Milch', settlement: const LineShopping()),
            ],
          ),
        ),
      ],
    );

    await tester.tap(
      find.byKey(CookbookRunningSection.continueKey('recipe-t1')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), AppRoutes.homeCookPath('t1'));
  });

  testWidgets('old open meals sit under "From the old version"', (
    tester,
  ) async {
    PreparedMeal? continued;
    await _pump(
      tester,
      runs: [_row(buildCookRun())],
      openMeals: [
        preparedMealTestData(id: 'old').copyWith(inPot: true),
        preparedMealTestData(id: 'older')
            .copyWith(pendingRecipeIngredients: const ['40 g Butter']),
      ],
      onContinueMeal: (meal) => continued = meal,
    );

    expect(find.text('FROM THE OLD VERSION · 2 OPEN'), findsOneWidget);

    // A meal in the pot continues, one with open rows is filled.
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    expect(continued?.id, 'old');

    await tester.tap(find.text('Fill'));
    await tester.pumpAndSettle();
    expect(continued?.id, 'older');
  });

  testWidgets('without runs only the old meals show', (tester) async {
    await _pump(
      tester,
      openMeals: [preparedMealTestData(id: 'old').copyWith(inPot: true)],
    );

    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.text('FROM THE OLD VERSION · 1 OPEN'), findsOneWidget);
    expect(find.textContaining('IN THE HOUSEHOLD'), findsNothing);
  });
}
