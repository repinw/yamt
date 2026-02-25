import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  String name = 'Skyr',
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: name,
    mealType: mealType,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.homeCalories,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.homeCalories,
        builder: (context, state) => const Scaffold(body: CaloriesPage()),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) => const Scaffold(body: Text('Create')),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryEdit,
        builder: (context, state) => const Scaffold(body: Text('Edit')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('renders summary and meal section cards', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b-1',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings(
        dailyKcalGoal: 2200,
        updatedAt: DateTime(today.year, today.month, today.day, 9),
      ),
    );
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.summaryCard), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Skyr'), findsOneWidget);
    expect(find.textContaining('2200 kcal'), findsWidgets);
  });

  testWidgets('delete action removes entry after confirmation', (tester) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'delete-me',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
          name: 'Delete Me',
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(CaloriesPageKeys.entryDeleteButton('delete-me')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete entry?'), findsOneWidget);

    final dialogDeleteButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Delete'),
    );
    await tester.tap(dialogDeleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Me'), findsNothing);
    expect(
      logRepository.entries.where((entry) => entry.id == 'delete-me'),
      isEmpty,
    );
  });

  testWidgets('set-goal dialog validates input and updates goal', (
    tester,
  ) async {
    final today = DateTime.now();
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'goal',
          loggedAt: DateTime(today.year, today.month, today.day, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CaloriesPageKeys.setGoalButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(CalorieGoalDialogKeys.valueField), '0');
    await tester.tap(find.byKey(CalorieGoalDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(CalorieGoalDialogKeys.valueField),
      '2300',
    );
    await tester.tap(find.byKey(CalorieGoalDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final settings = await settingsRepository.readSettings();
    expect(settings.dailyKcalGoal, 2300);
  });
}
