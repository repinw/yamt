import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_reset_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/root_navigator_test_utils.dart';
import '../../support/fake_calories_repositories.dart';

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  CalorieGoalSettings initialSettings = const CalorieGoalSettings.empty(),
}) {
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                unawaited(
                  showCalorieGoalCalculatorSheet(
                    context,
                    initialSettings: initialSettings,
                  ),
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
  await tester.ensureVisible(
    find.byKey(CalorieGoalCalculatorSheetKeys.nextButton),
  );
  await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.nextButton));
  await tester.pumpAndSettle();
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(CalorieGoalCalculatorSheetKeys.backButton),
  );
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

CalorieGoalSettings _learnedTdeeSettings() {
  final goalStartDate = DateTime(2026, 4, 10);
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2450,
    calculatorProfile: const CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.7,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    ),
    effectiveDate: goalStartDate,
    countingStartDate: goalStartDate,
    source: CalorieGoalSource.calculator,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: goalStartDate.subtract(const Duration(days: 7)),
      windowEndDate: goalStartDate.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.08,
      calculatedTrueTdeeKcal: 2450,
      averageActiveKcal: 210,
      lowConfidence: false,
    ),
  );
}

void main() {
  testWidgets('calculator sheet opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ],
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    unawaited(
                      showCalorieGoalCalculatorSheet(
                        context,
                        initialSettings: const CalorieGoalSettings.empty(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await _openSheet(tester);

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsOneWidget,
    );
  });

  testWidgets('reset sheet opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    unawaited(
                      showCalorieGoalCalculatorResetSheet(
                        context,
                        initialSettings: const CalorieGoalSettings.empty(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await _openSheet(tester);

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsOneWidget,
    );
  });

  testWidgets('routes learned TDEE settings to learned TDEE sheet', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialSettings: _learnedTdeeSettings(),
      ),
    );
    await _openSheet(tester);

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsOneWidget);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsNothing,
    );
  });

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
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartCard),
      findsOneWidget,
    );
    expect(find.text('1,680 kcal'), findsOneWidget);
  });

  testWidgets(
    'activity step shows selectable options instead of a text field',
    (tester) async {
      final repository = FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_buildHarness(settingsRepository: repository));
      await _openSheet(tester);

      await _tapNext(tester);
      await _tapNext(tester);
      await _tapNext(tester);
      await _tapNext(tester);

      expect(
        find.byKey(CalorieGoalCalculatorSheetKeys.activityLevelOptions),
        findsOneWidget,
      );
      expect(
        find.byKey(
          CalorieGoalCalculatorSheetKeys.activityLevelOption(
            CalorieActivityLevelOption.low.name,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);

      final highActivityOption = find.byKey(
        CalorieGoalCalculatorSheetKeys.activityLevelOption(
          CalorieActivityLevelOption.high.name,
        ),
      );
      await tester.ensureVisible(highActivityOption);
      await tester.tap(highActivityOption);
      await tester.pumpAndSettle();
      await _tapNext(tester);
      await _tapNext(tester);

      expect(find.text('3,071 kcal'), findsNWidgets(2));
    },
  );

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
    final noneActivityOption = find.byKey(
      CalorieGoalCalculatorSheetKeys.activityLevelOption(
        CalorieActivityLevelOption.none.name,
      ),
    );
    await tester.ensureVisible(noneActivityOption);
    await tester.tap(noneActivityOption);
    await tester.pumpAndSettle();
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
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calorie calculator'), findsNothing);
    final settings = await repository.readSettings();
    expect(settings.calculatorProfile, isNotNull);
    expect(settings.dailyKcalGoal, 2136);
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
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calorie calculator'), findsOneWidget);
    expect(
      find.text('Could not save the calculated calorie target.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps existing goal start date when editing calculator goal', (
    tester,
  ) async {
    final repository = FakeCalorieSettingsRepository();
    final goalStartDate = DateTime(2026, 4, 10, 16, 30);
    final countingStartDate = DateTime(2026, 4, 12);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: repository,
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2136,
          calculatorProfile: const CalorieCalculatorProfile(
            sex: CalorieCalculatorSex.male,
            weightKg: 80,
            heightCm: 180,
            ageYears: 30,
            activityLevel: 1.2,
            goalMode: CalorieGoalMode.maintain,
            goalSpeedKgPerWeek: 0,
          ),
          effectiveDate: goalStartDate,
          countingStartDate: countingStartDate,
          source: CalorieGoalSource.calculator,
        ),
      ),
    );
    await _openSheet(tester);
    await _goToResultsWithDefaults(tester);

    final goalStartValue = tester.widget<Text>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartValue),
    );

    expect(
      goalStartValue.data,
      DateFormat.yMMMd('en').format(countingStartDate),
    );
  });

  testWidgets(
    'save keeps future official start for existing sandbox goal',
    (tester) async {
      final repository = FakeCalorieSettingsRepository();
      final futureGoalStart = DateTime.now().add(const Duration(days: 2));
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _buildHarness(
          settingsRepository: repository,
          initialSettings: CalorieGoalSettings.single(
            dailyKcalGoal: 1680,
            calculatorProfile: const CalorieCalculatorProfile.defaults(),
            effectiveDate: DateTime.now(),
            countingStartDate: futureGoalStart,
            source: CalorieGoalSource.calculator,
          ),
        ),
      );
      await _openSheet(tester);
      await _goToResultsWithDefaults(tester);
      await _ensureSaveButtonVisible(tester);

      await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.saveButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not save the calculated calorie target.'),
        findsNothing,
      );
      final settings = await repository.readSettings();
      expect(
        settings.latestGoalEntry?.effectiveCountingStartDate,
        DateTime(
          futureGoalStart.year,
          futureGoalStart.month,
          futureGoalStart.day,
        ),
      );
    },
  );
}
