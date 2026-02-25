import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User {}

CalorieEntry _entry(String id) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    loggedAt: DateTime(2026, 2, 25, 8),
    createdAt: DateTime(2026, 2, 25, 8),
    updatedAt: DateTime(2026, 2, 25, 8),
  );
}

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Root')),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryCreate,
        builder: (context, state) => const CalorieEntryEditorPage(),
      ),
      GoRoute(
        path: AppRoutes.homeCaloriesEntryEdit,
        builder: (context, state) {
          return CalorieEntryEditorPage(
            entryId: state.pathParameters['entryId'],
          );
        },
      ),
    ],
  );

  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');

  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
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
  testWidgets('create flow saves a new entry and pops back', (tester) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100ProteinField),
      '9.8',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100CarbsField),
      '4.1',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100FatField),
      '0.5',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(logRepository.entries, hasLength(1));
    expect(logRepository.entries.single.name, 'Greek Yogurt');
  });

  testWidgets('edit flow loads and updates existing entry', (tester) async {
    final existing = _entry('entry-1');
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[existing],
    );
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryEditPath('entry-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit calorie entry'), findsOneWidget);

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Updated Skyr',
    );
    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Edit calorie entry'), findsOneWidget);
    final updated = logRepository.entries.single;
    expect(updated.id, 'entry-1');
    expect(updated.name, 'Updated Skyr');
  });

  testWidgets('validation blocks save for empty name', (tester) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(CalorieEntryEditorKeys.nameField), '');
    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('validation blocks save for negative consumed amount', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.amountField),
      '-10',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a number greater than zero.'),
      findsOneWidget,
    );
    expect(logRepository.entries, isEmpty);
  });

  testWidgets('validation blocks save for invalid number characters', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        initialLocation: AppRoutes.homeCaloriesEntryCreate,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.nameField),
      'Greek Yogurt',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.amountField),
      '200',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100KcalField),
      '95',
    );
    await tester.enterText(
      find.byKey(CalorieEntryEditorKeys.per100ProteinField),
      'abc',
    );

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a number equal to or greater than zero.'),
      findsOneWidget,
    );
    expect(logRepository.entries, isEmpty);
  });
}
