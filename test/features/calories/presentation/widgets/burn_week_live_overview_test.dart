import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
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

class _FakeHealthConnectionController extends HealthConnectionController {
  @override
  FutureOr<HealthConnectionStatus> build() {
    return const HealthConnectionStatus.unsupported();
  }
}

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required double totalKcal,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Meal $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 10,
    per100Fat: 10,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

DateTime _futureSameDay(DateTime now) {
  if (now.hour < 23) {
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }
  if (now.minute < 59) {
    return DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
  }
  return DateTime(now.year, now.month, now.day, 23, 59, 59);
}

Widget _buildHarness({
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
  required BurnWeekRunStateRepository runStateRepository,
  ProviderContainer? containerOverride,
}) {
  final container =
      containerOverride ??
      ProviderContainer(
        overrides: [
          burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            runStateRepository,
          ),
          healthConnectionControllerProvider.overrideWith(
            _FakeHealthConnectionController.new,
          ),
        ],
      );
  if (containerOverride == null) {
    addTearDown(container.dispose);
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);
  }

  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: BurnWeekLiveOverview()),
    ),
  );
}

FakeCalorieSettingsRepository _settingsWithGoal(
  DateTime effectiveDate, {
  double dailyKcalGoal = 2000,
}) {
  return FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: null,
      effectiveDate: effectiveDate,
    ),
  );
}

BurnWeekRunState _runStateForDay(
  DateTime day, {
  int runWeekNumber = 1,
  int starCount = 0,
  int heartCount = 3,
  double heartCreditKcal = 0,
  bool starBrokeThisWeek = false,
  bool missedTrackingThisWeek = false,
}) {
  return BurnWeekRunState(
    currentWeekStartDayKey: '${day.year}-${day.month}-${day.day}',
    runWeekNumber: runWeekNumber,
    starCount: starCount,
    heartCount: heartCount,
    heartCreditKcal: heartCreditKcal,
    starBrokeThisWeek: starBrokeThisWeek,
    missedTrackingThisWeek: missedTrackingThisWeek,
  );
}

Future<void> _pumpOverviewScenario(
  WidgetTester tester, {
  required DateTime effectiveDate,
  required List<CalorieEntry> entries,
  required BurnWeekRunState runState,
}) async {
  final settingsRepository = _settingsWithGoal(effectiveDate);
  final logRepository = FakeCalorieLogRepository(initialEntries: entries);
  final runStateRepository = _FakeBurnWeekRunStateRepository(runState);
  addTearDown(settingsRepository.dispose);
  addTearDown(logRepository.dispose);

  await tester.pumpWidget(
    _buildHarness(
      logRepository: logRepository,
      settingsRepository: settingsRepository,
      runStateRepository: runStateRepository,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('future goal start shows practice day card', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: tomorrow,
      ),
    );
    final logRepository = FakeCalorieLogRepository();
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        runStateRepository: runStateRepository,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.text('Goal: 2,000 kcal'), findsOneWidget);
    expect(find.text('EATEN'), findsNothing);
  });

  testWidgets('renders live Burn overview and details dialog', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await _pumpOverviewScenario(
      tester,
      effectiveDate: today,
      entries: <CalorieEntry>[
        _entry('today', loggedAt: today, totalKcal: 1100),
      ],
      runState: _runStateForDay(
        today,
        runWeekNumber: 2,
        starCount: 1,
        heartCount: 2,
      ),
    );

    expect(find.text('EATEN'), findsOneWidget);
    expect(find.text('TODAY LEFT'), findsOneWidget);
    expect(find.text('x 1'), findsOneWidget);
    expect(find.text('x 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(find.text('Burn Week details'), findsOneWidget);
    expect(find.textContaining('Budget starts'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('new user day one shows daily left, not full weekly left', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await _pumpOverviewScenario(
      tester,
      effectiveDate: today,
      entries: <CalorieEntry>[
        _entry('today', loggedAt: today, totalKcal: 100),
      ],
      runState: const BurnWeekRunState.initial(),
    );

    expect(find.text('1,900 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(find.textContaining('x 6 full days +'), findsNothing);
  });

  testWidgets('rendering overview starts live week sync', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cycleStart = today.subtract(const Duration(days: 14));
    final dayProgress =
        now.difference(today).inSeconds / const Duration(days: 1).inSeconds;
    final settingsRepository = _settingsWithGoal(cycleStart);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        for (var dayOffset = 14; dayOffset >= 1; dayOffset -= 1)
          _entry(
            'day-$dayOffset',
            loggedAt: today.subtract(Duration(days: dayOffset)),
            totalKcal: 1000,
          ),
        _entry(
          'today',
          loggedAt: today,
          totalKcal: 2000 * dayProgress,
        ),
      ],
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState.initial(),
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        runStateRepository: runStateRepository,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(runStateRepository.state.currentWeekStartDayKey, diaryDayKey(today));
    expect(runStateRepository.state.runWeekNumber, 3);
    expect(runStateRepository.state.starCount, 2);
  });

  testWidgets(
    'today left keeps cycle carryover after a fresh Burn Week restart',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      await _pumpOverviewScenario(
        tester,
        effectiveDate: yesterday,
        entries: <CalorieEntry>[
          _entry('yesterday', loggedAt: yesterday, totalKcal: 1800),
          _entry('today', loggedAt: today, totalKcal: 1000),
        ],
        runState: _runStateForDay(today),
      );

      expect(find.text('1,033 kcal'), findsOneWidget);
    },
  );

  testWidgets('future same-day meal stays in planned state', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final laterToday = _futureSameDay(now);
    await _pumpOverviewScenario(
      tester,
      effectiveDate: today,
      entries: <CalorieEntry>[
        _entry('now', loggedAt: today, totalKcal: 300),
        _entry('later', loggedAt: laterToday, totalKcal: 500),
      ],
      runState: _runStateForDay(today),
    );

    expect(find.text('300 kcal'), findsOneWidget);
    expect(find.text('1,200 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Planned later today: 500 kcal'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('planned later today refreshes after diary edit', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final laterToday = _futureSameDay(now);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: today,
      ),
    );
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('now', loggedAt: today, totalKcal: 300),
        _entry('later', loggedAt: laterToday, totalKcal: 500),
      ],
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      BurnWeekRunState(
        currentWeekStartDayKey: '${today.year}-${today.month}-${today.day}',
        runWeekNumber: 1,
        starCount: 0,
        heartCount: 3,
        heartCreditKcal: 0,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
        healthConnectionControllerProvider.overrideWith(
          _FakeHealthConnectionController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        runStateRepository: runStateRepository,
        containerOverride: container,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Planned later today: 500 kcal'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await logRepository.saveEntry(
      _entry('later', loggedAt: laterToday, totalKcal: 800),
    );
    container.read(calorieOverviewRevisionProvider.notifier).markChanged();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Planned later today: 800 kcal'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('run over restarts from tomorrow', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = nextDiaryDay(today);
    final tomorrowKey = diaryDayKey(tomorrow);
    final settingsRepository = _settingsWithGoal(today);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('today', loggedAt: today, totalKcal: 15000),
      ],
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      _runStateForDay(
        today,
        heartCount: 0,
      ),
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        logRepository: logRepository,
        settingsRepository: settingsRepository,
        runStateRepository: runStateRepository,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Run over'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(runStateRepository.state.currentWeekStartDayKey, tomorrowKey);
    expect(
      find.text(
        'Fresh run starts on ${DateFormat.yMMMd('en').format(tomorrow)}.',
      ),
      findsOneWidget,
    );
    expect(find.text('TODAY LEFT'), findsNothing);
  });

  testWidgets('dispose closes an open zone dialog', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final showsOverview = ValueNotifier<bool>(true);
    addTearDown(showsOverview.dispose);
    final settingsRepository = _settingsWithGoal(today);
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('today', loggedAt: today, totalKcal: 15000),
      ],
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      _runStateForDay(
        today,
        heartCount: 0,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
        healthConnectionControllerProvider.overrideWith(
          _FakeHealthConnectionController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showsOverview,
              builder: (context, isVisible, child) {
                if (!isVisible) {
                  return const SizedBox.shrink();
                }
                return const BurnWeekLiveOverview();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Run over'), findsOneWidget);

    showsOverview.value = false;
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(BurnWeekLiveOverview), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Run over'), findsNothing);
  });
}
