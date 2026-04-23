import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}

Widget _buildHarness({
  required FakeCalorieSettingsRepository settingsRepository,
  required FakeCalorieLogRepository logRepository,
  required BurnWeekRunStateRepository runStateRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(runStateRepository),
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
        body: CalorieGoalCalculatorFlow(
          initialSettings: const CalorieGoalSettings.empty(),
          presentation: CalorieGoalCalculatorFlowPresentation.onboarding,
        ),
      ),
    ),
  );
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(CalorieGoalCalculatorSheetKeys.nextButton),
  );
  await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.nextButton));
  await tester.pumpAndSettle();
}

Future<void> _goToResultsWithDefaults(WidgetTester tester) async {
  await _tapNext(tester); // sex -> weight
  await _tapNext(tester); // weight -> height
  await _tapNext(tester); // height -> age
  await _tapNext(tester); // age -> activity
  await _tapNext(tester); // activity -> goal mode
  await _tapNext(tester); // goal mode -> results
}

void main() {
  testWidgets('onboarding waits for explicit start choice', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      ),
    );
    await _goToResultsWithDefaults(tester);

    final saveButton = tester.widget<FilledButton>(
      find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
    );

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartNowOption),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartLaterOption),
      findsOneWidget,
    );
    expect(saveButton.onPressed, isNull);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpLowOption),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpNormalOption),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpHighOption),
      findsNothing,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartChangeButton),
      findsNothing,
    );

    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartNowOption),
    );
    await tester.pumpAndSettle();

    final enabledSaveButton = tester.widget<FilledButton>(
      find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
    );

    expect(enabledSaveButton.onPressed, isNotNull);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpLowOption),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpNormalOption),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpHighOption),
      findsOneWidget,
    );
  });

  testWidgets('onboarding can save a future goal start', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-20',
        lastActiveDayKey: '2026-4-22',
        runWeekNumber: 2,
        starCount: 1,
        heartCount: 2,
        heartCreditKcal: 300,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      ),
    );
    await _goToResultsWithDefaults(tester);

    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartLaterOption),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartChangeButton),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.catchUpNormalOption),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
    );
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.saveButton));
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final settings = await settingsRepository.readSettings();
    expect(
      settings.nextGoalStartAfterDay(DateTime.now()),
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
    expect(runStateRepository.state.currentWeekStartDayKey, isNull);
    expect(runStateRepository.state.runWeekNumber, 1);
  });
}
