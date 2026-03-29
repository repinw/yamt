import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  CalorieGoalSettings initialSettings = const CalorieGoalSettings.empty(),
}) {
  return ProviderScope(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showCalorieGoalCalculatorSheet(
                  context,
                  initialSettings: initialSettings,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _ensureSaveButtonVisible(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.nextButton));
  await tester.pumpAndSettle();
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.backButton));
  await tester.pumpAndSettle();
}

Future<void> _goToResultsWithDefaults(WidgetTester tester) async {
  await _tapNext(tester); // sex -> weight
  await _tapNext(tester); // weight -> height
  await _tapNext(tester); // height -> age
  await _tapNext(tester); // age -> activity
  await _tapNext(tester); // activity -> goal mode
  await _tapNext(tester); // goal mode -> results (maintain default)
}

void main() {
  testWidgets('asks values step by step before showing results', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await _openSheet(tester);

    expect(find.text('Sex'), findsOneWidget);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.weightField),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsOneWidget,
    );

    await _tapNext(tester);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.weightField),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.weightField),
      '70',
    );
    await tester.pumpAndSettle();

    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.resultsCard),
      findsOneWidget,
    );
    expect(find.text('1,680 kcal'), findsOneWidget);
  });

  testWidgets('maintain mode disables goal speed and restores previous value', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await _openSheet(tester);

    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);
    await _tapNext(tester);

    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalSpeedField),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalSpeedField),
      '0.75',
    );
    await tester.pumpAndSettle();

    await _tapBack(tester);
    await tester.tap(find.text('Maintain'));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalSpeedField),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.resultsCard),
      findsOneWidget,
    );

    await _tapBack(tester);
    await tester.tap(find.text('Gain'));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    final restoredField = tester.widget<TextField>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalSpeedField),
    );
    expect(restoredField.controller?.text, '0.75');
  });

  testWidgets('shows warning and clamps result to 1200 kcal', (tester) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await _openSheet(tester);

    await _tapNext(tester);
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.weightField),
      '50',
    );
    await _tapNext(tester);
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.heightField),
      '155',
    );
    await _tapNext(tester);
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.ageField),
      '60',
    );
    await _tapNext(tester);
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.activityLevelField),
      '1.2',
    );
    await _tapNext(tester);
    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();
    await _tapNext(tester);
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalSpeedField),
      '0.75',
    );
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.warningCard),
      findsOneWidget,
    );
    expect(find.text('1,200 kcal'), findsOneWidget);
  });

  testWidgets('successful save closes the sheet and persists the profile', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await _openSheet(tester);

    await _goToResultsWithDefaults(tester);
    await _ensureSaveButtonVisible(tester);
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Calorie calculator'), findsNothing);
    final settings = await repository.readSettings();
    expect(settings.calculatorProfile, isNotNull);
    expect(settings.dailyKcalGoal, 2492);
  });

  testWidgets('save failure keeps the sheet open and shows feedback', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository()..saveShouldFail = true;
    addTearDown(repository.dispose);

    await tester.pumpWidget(_buildHarness(settingsRepository: repository));
    await _openSheet(tester);

    await _goToResultsWithDefaults(tester);
    await _ensureSaveButtonVisible(tester);
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Calorie calculator'), findsOneWidget);
    expect(
      find.text('Could not save the calculated calorie target.'),
      findsOneWidget,
    );
  });
}
