import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_new_goal_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

const _openButtonKey = ValueKey<String>('open-new-goal-sheet');

void main() {
  testWidgets('shows no back arrow unless the caller asks for it', (
    tester,
  ) async {
    final harness = await _pumpHarness(tester, settings: _learnedSettings());
    await _openSheet(tester);

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsOneWidget);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
      findsNothing,
    );
    expect(harness.results, isEmpty);
  });

  testWidgets('the back arrow closes the learned TDEE sheet without a goal', (
    tester,
  ) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [false]);
    final settings = await harness.settingsRepository.readSettings();
    expect(settings.sortedGoalHistory, hasLength(1));
  });

  testWidgets('the full calculator has the back arrow and cancel too', (
    tester,
  ) async {
    final harness = await _pumpHarness(
      tester,
      settings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 10),
      ),
      showBackButton: true,
    );
    await _openSheet(tester);

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.sheetBackButton),
    );
    await tester.pumpAndSettle();

    await _openSheet(tester);
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.cancelButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsNothing,
    );
    expect(harness.results, [false, false]);
  });

  testWidgets('the cancel button closes the sheet without a goal', (
    tester,
  ) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.cancelButton));
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [false]);
    final settings = await harness.settingsRepository.readSettings();
    expect(settings.sortedGoalHistory, hasLength(1));
  });

  testWidgets('on a phone the sheet closes with a swipe down (#820)', (
    tester,
  ) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
      viewSize: const Size(390, 844),
    );
    await _openSheet(tester);

    await tester.drag(
      find.byKey(CalorieLearnedTdeeSheetKeys.goalValue),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [false]);
  });

  testWidgets('the pace wheel sets the pace of the saved goal', (tester) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.paceRow), findsNothing);
    final slider = find.byType(Slider);
    await tester.tapAt(
      tester.getCenter(slider) - Offset(tester.getSize(slider).width / 4, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.paceRow));
    await tester.pumpAndSettle();
    expect(find.text('0.50 kg / week'), findsWidgets);

    await tester.drag(
      find.byKey(CalorieLearnedTdeeSheetKeys.paceWheel),
      const Offset(0, -(34 + kDragSlopDefault)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(harness.results, [true]);
    final settings = await harness.settingsRepository.readSettings();
    final profile = settings.sortedGoalHistory.last.calculatorProfile!;
    expect(profile.goalMode, CalorieGoalMode.lose);
    expect(profile.goalSpeedKgPerWeek, closeTo(0.55, 0.001));
  });

  testWidgets('dismissing the sheet completes without a goal', (tester) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [false]);
  });

  testWidgets('saving a new goal completes with true', (tester) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [true]);
    final settings = await harness.settingsRepository.readSettings();
    expect(settings.sortedGoalHistory, hasLength(2));
  });

  testWidgets('closing the sheet while it saves still reports the save', (
    tester,
  ) async {
    final harness = await _pumpHarness(
      tester,
      settings: _learnedSettings(),
      showBackButton: true,
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    final saveGate = Completer<void>();
    harness.settingsRepository.onSaveSettings = (_) => saveGate.future;
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    // Lets the dialog close; the sheet keeps saving behind the gate.
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.binding.handlePopRoute();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, isEmpty);

    saveGate.complete();
    await tester.pumpAndSettle();

    expect(harness.results, [true]);
  });
}

/// The repositories of the harness and the results of the opened sheets.
final class _Harness {
  new(this.settingsRepository);

  final FakeCalorieSettingsRepository settingsRepository;
  final results = <bool?>[];
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  required CalorieGoalSettings settings,
  bool showBackButton = false,
  Size viewSize = const Size(800, 1400),
}) async {
  tester.view
    ..physicalSize = viewSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: settings,
  );
  final logRepository = FakeCalorieLogRepository();
  addTearDown(settingsRepository.dispose);
  addTearDown(logRepository.dispose);
  final harness = _Harness(settingsRepository);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          FakeBurnWeekRunStateRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                key: _openButtonKey,
                onPressed: () async {
                  harness.results.add(
                    await showCalorieNewGoalSheet(
                      context,
                      currentWeightKg: 64,
                      showBackButton: showBackButton,
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
  return harness;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_openButtonKey));
  await tester.pumpAndSettle();
}

CalorieGoalSettings _learnedSettings() {
  final goalStartDate = addLocalDays(DateTime.now(), -20);
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
      windowStartDate: addLocalDays(goalStartDate, -7),
      windowEndDate: addLocalDays(goalStartDate, -1),
      trendWeightChangePerDay: -0.08,
      calculatedTdeeKcal: 2450,
      lowConfidence: false,
    ),
  );
}
