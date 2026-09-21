import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_lifecycle.dart';
import 'package:yamt/features/calories/presentation/pages/calorie_goal_archive_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

CalorieGoalSettings _twoGoals() {
  const profile = CalorieCalculatorProfile.defaults();
  return CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: profile.copyWith(
          weightKg: 80,
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
          targetWeightKg: 78,
        ),
        effectiveDate: DateTime(2026, 6),
      )
      .markActiveGoalEnded(DateTime(2026, 6, 10), weightKg: 78)
      .applyGoalChange(
        changedAt: DateTime(2026, 6, 10),
        dailyKcalGoal: 2400,
        calculatorProfile: profile,
        preserveSameDayGoalEntries: true,
      );
}

Future<(FakeCalorieSettingsRepository, List<String>)> _pump(
  WidgetTester tester,
  CalorieGoalSettings settings,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = FakeCalorieSettingsRepository(initialSettings: settings);
  addTearDown(repository.dispose);
  final opened = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CalorieGoalArchivePage(),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesAnalytics,
        builder: (context, state) {
          opened.add(state.uri.toString());
          return const Scaffold(body: Text('analytics'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (repository, opened);
}

void main() {
  testWidgets('shows the active and the archived goal', (tester) async {
    await _pump(tester, _twoGoals());

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Lose'), findsOneWidget);
    expect(find.text('Maintain'), findsOneWidget);
    expect(find.text('0.50 kg/week'), findsOneWidget);
  });

  testWidgets('shows the default goal when no goal was saved', (tester) async {
    await _pump(tester, const CalorieGoalSettings.empty());

    expect(find.text('Goal archive'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('opening a card passes its cycle id to analytics', (
    tester,
  ) async {
    final (_, opened) = await _pump(tester, _twoGoals());

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    final uri = Uri.parse(opened.single);
    expect(
      uri.queryParameters[AppRoutes.homeCaloriesAnalyticsCyclesParam],
      startsWith('cycle_'),
    );
    expect(
      uri.queryParameters[AppRoutes.homeCaloriesAnalyticsCyclesParam],
      isNot(contains(',')),
    );
  });

  testWidgets('selecting two goals opens them together', (tester) async {
    final (_, opened) = await _pump(tester, _twoGoals());

    for (final checkbox in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
      expect(checkbox.value, isFalse);
    }
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open timeline'));
    await tester.pumpAndSettle();

    final ids = Uri.parse(opened.single)
        .queryParameters[AppRoutes.homeCaloriesAnalyticsCyclesParam]!;
    expect(ids.split(','), hasLength(2));
  });
}
