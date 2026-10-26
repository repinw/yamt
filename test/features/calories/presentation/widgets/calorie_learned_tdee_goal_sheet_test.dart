import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/root_navigator_test_utils.dart';
import '../../support/fake_calories_repositories.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;
  int saveCallCount = 0;
  bool saveThrows = false;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    saveCallCount += 1;
    if (saveThrows) {
      throw StateError('Saving the Burn Week run failed.');
    }
    state = nextState;
    return true;
  }
}

Widget _buildHarness({
  required CalorieGoalSettings initialSettings,
  List<Override> overrides = const <Override>[],
  bool startsNewGoal = false,
  double? currentWeightKg,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                unawaited(
                  showCalorieLearnedTdeeGoalSheet(
                    context,
                    initialSettings: initialSettings,
                    startsNewGoal: startsNewGoal,
                    currentWeightKg: currentWeightKg,
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

CalorieGoalSettings _learnedTdeeSettings({
  DateTime? goalStartDate,
  CalorieGoalMode goalMode = CalorieGoalMode.maintain,
  double goalSpeedKgPerWeek = 0,
}) {
  final resolvedGoalStartDate = goalStartDate ?? DateTime(2026, 4, 10);
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2450,
    calculatorProfile: CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.7,
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      targetWeightKg: goalMode == CalorieGoalMode.maintain ? null : 60,
    ),
    effectiveDate: resolvedGoalStartDate,
    countingStartDate: resolvedGoalStartDate,
    source: CalorieGoalSource.calculator,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: addLocalDays(resolvedGoalStartDate, -7),
      windowEndDate: addLocalDays(resolvedGoalStartDate, -1),
      trendWeightChangePerDay: -0.08,
      calculatedTdeeKcal: 2450,
      lowConfidence: false,
    ),
  );
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('switching goal modes preserves the previous pace', (
    tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _buildHarness(
        initialSettings: _learnedTdeeSettings(
          goalMode: CalorieGoalMode.lose,
          goalSpeedKgPerWeek: 0.5,
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final speedFieldFinder = find.byKey(
      CalorieGoalCalculatorSheetKeys.goalSpeedField,
    );
    expect(speedFieldFinder, findsOneWidget);
    expect(tester.widget<TextField>(speedFieldFinder).controller?.text, '0.5');

    await tester.enterText(speedFieldFinder, '0,7');
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.text('Maintain'));
    await tester.pumpAndSettle();

    expect(speedFieldFinder, findsNothing);
    expect(find.textContaining('2,450'), findsWidgets);

    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();

    expect(speedFieldFinder, findsOneWidget);
    expect(tester.widget<TextField>(speedFieldFinder).controller?.text, '0,7');
  });

  testWidgets('learned TDEE sheet opens on root navigator by default', (
    tester,
  ) async {
    _useTallView(tester);
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  unawaited(
                    showCalorieLearnedTdeeGoalSheet(
                      context,
                      initialSettings: _learnedTdeeSettings(),
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

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsOneWidget);
  });

  testWidgets('full reset opens the complete calculator flow', (tester) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _buildHarness(initialSettings: _learnedTdeeSettings()),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.fullResetButton));
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.stepCounter),
      findsOneWidget,
    );
    expect(find.text('Sex'), findsOneWidget);
  });

  testWidgets('keeps existing goal start date when editing learned TDEE goal', (
    tester,
  ) async {
    _useTallView(tester);
    final goalStartDate = DateTime(2026, 4, 10, 16, 30);
    final countingStartDate = DateTime(2026, 4, 12);
    final initialSettings = CalorieGoalSettings.single(
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
      countingStartDate: countingStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTdeeKcal: 2450,
        lowConfidence: false,
      ),
    );

    await tester.pumpWidget(_buildHarness(initialSettings: initialSettings));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final goalStartValue = tester.widget<Text>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartValue),
    );

    expect(
      goalStartValue.data,
      DateFormat.yMMMd('en').format(countingStartDate),
    );
  });

  testWidgets('saving unchanged learned goal does not restart Burn Week', (
    tester,
  ) async {
    _useTallView(tester);
    final today = normalizeLocalDay(DateTime.now());
    final goalStartDate = addLocalDays(today, -2);
    final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: addLocalDays(goalStartDate, -7),
      windowEndDate: addLocalDays(goalStartDate, -1),
      trendWeightChangePerDay: -0.08,
      calculatedTdeeKcal: 2450,
      lowConfidence: false,
    );
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.7,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2450,
      calculatorProfile: profile,
      effectiveDate: goalStartDate,
      countingStartDate: goalStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: learnedSnapshot,
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    final initialRunState = BurnWeekRunState(
      currentWeekStartDayKey: localDayKey(addLocalDays(goalStartDate, -7)),
      lastActiveDayKey: localDayKey(today),
      runWeekNumber: 3,
      starCount: 2,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: true,
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(initialRunState);
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            runStateRepository,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(runStateRepository.saveCallCount, 0);
    expect(runStateRepository.state, initialRunState);
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
  });

  testWidgets('saving changed learned goal restarts Burn Week at week one', (
    tester,
  ) async {
    _useTallView(tester);
    final today = normalizeLocalDay(DateTime.now());
    final goalStartDate = addLocalDays(today, -6);
    final initialSettings = _learnedTdeeSettings(goalStartDate: goalStartDate);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      BurnWeekRunState(
        currentWeekStartDayKey: localDayKey(addLocalDays(goalStartDate, -49)),
        lastActiveDayKey: localDayKey(today),
        runWeekNumber: 8,
        starCount: 7,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            runStateRepository,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.targetWeightField),
      '60',
    );
    await tester.pumpAndSettle();

    final goalStartValue = tester.widget<Text>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartValue),
    );
    expect(goalStartValue.data, DateFormat.yMMMd('en').format(today));

    await tester.ensureVisible(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(runStateRepository.saveCallCount, 1);
    expect(runStateRepository.state.currentWeekStartDayKey, localDayKey(today));
    expect(
      runStateRepository.state.runWeekNumber,
      burnWeekLearningRunWeekNumber,
    );
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
  });

  testWidgets('a double tap on save asks once and saves once (#703)', (
    tester,
  ) async {
    _useTallView(tester);
    final today = normalizeLocalDay(DateTime.now());
    final initialSettings = _learnedTdeeSettings(
      goalStartDate: addLocalDays(today, -6),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.targetWeightField),
      '60',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    await tester.pumpAndSettle();
    final reading = Completer<void>();
    logRepository.onReadEntriesForDay = (_) async {
      await reading.future;
      return const [];
    };

    var saves = 0;
    settingsRepository.onSaveSettings = (_) async => saves++;

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pump();
    // The whole form is locked while it reads today (#721).
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(
                  of: find.byKey(
                    CalorieGoalCalculatorSheetKeys.targetWeightField,
                  ),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
    reading.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();
    expect(saves, 1);
  });

  testWidgets('shows failure snackbar when learned TDEE save fails', (
    tester,
  ) async {
    _useTallView(tester);
    final initialSettings = _learnedTdeeSettings(
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    )..saveShouldFail = true;
    final logRepository = FakeCalorieLogRepository();
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintain'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsOneWidget);
    expect(
      find.text('Could not save the learned TDEE target.'),
      findsOneWidget,
    );
  });
  testWidgets('a failed read of today shows the error and keeps save usable '
      '(#710)', (tester) async {
    _useTallView(tester);
    final initialSettings = _learnedTdeeSettings(
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository()
      ..onReadEntriesForDay = (_) async => throw StateError('offline');
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maintain'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsOneWidget);
    expect(
      find.text('Could not save the learned TDEE target.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a failed Burn Week restart closes the saved goal and says so '
      '(#710)', (tester) async {
    _useTallView(tester);
    final today = normalizeLocalDay(DateTime.now());
    final goalStartDate = addLocalDays(today, -6);
    final initialSettings = _learnedTdeeSettings(goalStartDate: goalStartDate);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    )..saveThrows = true;
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            runStateRepository,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.targetWeightField),
      '60',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(runStateRepository.saveCallCount, 1);
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(
      find.text('Goal saved, but the run could not restart.'),
      findsOneWidget,
    );
  });

  testWidgets('lose needs a target weight before it can be saved', (
    tester,
  ) async {
    _useTallView(tester);
    await tester.pumpWidget(
      _buildHarness(initialSettings: _learnedTdeeSettings()),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lose'));
    await tester.pumpAndSettle();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.byKey(CalorieLearnedTdeeSheetKeys.saveButton),
    );
    expect(saveButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(CalorieGoalCalculatorSheetKeys.targetWeightField),
      '60',
    );
    await tester.pumpAndSettle();

    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('new goal sheet archives the current goal on save', (
    tester,
  ) async {
    _useTallView(tester);
    final today = normalizeLocalDay(DateTime.now());
    final initialSettings = _learnedTdeeSettings(
      goalStartDate: addLocalDays(today, -20),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        startsNewGoal: true,
        currentWeightKg: 64,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            _FakeBurnWeekRunStateRepository(
              BurnWeekRunState(
                currentWeekStartDayKey: localDayKey(today),
                lastActiveDayKey: localDayKey(today),
                runWeekNumber: 1,
                starCount: 0,
                starBrokeThisWeek: false,
                missedTrackingThisWeek: false,
              ),
            ),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Current weight: 64 kg · Maintain'), findsOneWidget);
    expect(
      find.byKey(CalorieLearnedTdeeSheetKeys.fullResetButton),
      findsNothing,
    );
    expect(find.text('Goal mode'), findsNothing);

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    final history = (await settingsRepository.readSettings()).sortedGoalHistory;
    expect(history, hasLength(2));
    expect(history.first.endedAt, today);
    expect(history.first.endedWeightKg, 64);
    expect(history.last.endedAt, isNull);
    expect(history.last.calculatorProfile?.weightKg, 64);
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
  });
}
