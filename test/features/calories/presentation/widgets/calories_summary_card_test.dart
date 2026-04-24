import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_gauge.dart';
import 'package:yamt/features/calories/provider/'
    'burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_balance_summary_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_summary_view_mode_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../support/fake_calories_repositories.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;
  int saveCount = 0;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    saveCount += 1;
    state = nextState;
    return true;
  }
}

class _DelayedCalorieSettingsRepository implements CalorieSettingsRepository {
  _DelayedCalorieSettingsRepository({
    required this.initialSettings,
    required this.initialDelay,
  });

  final CalorieGoalSettings initialSettings;
  final Duration initialDelay;
  final StreamController<CalorieGoalSettings> _controller =
      StreamController<CalorieGoalSettings>.broadcast();

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.multi((controller) {
      final timer = Timer(initialDelay, () {
        if (!controller.isClosed) {
          controller.add(initialSettings);
        }
      });
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        timer.cancel();
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    return initialSettings;
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    _controller.add(settings);
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => true;

  @override
  Future<bool> clearDailyGoal() async => true;

  Future<void> dispose() {
    return _controller.close();
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

void main() {
  const labelStyle = TextStyle(fontSize: 12);

  test('doesCaloriesSummaryTextFitWidth detects fitting text', () {
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'FETT',
        style: labelStyle,
        maxWidth: 200,
      ),
      isTrue,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHlenhydrate',
        style: labelStyle,
        maxWidth: 8,
      ),
      isFalse,
    );
  });

  test('resolveMacroLabelForWidth keeps the full label when it fits', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 200,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'KOHLENHYDRATE');
  });

  test('resolveMacroLabelForWidth truncates and appends a dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isNot('KOHLENHYDRATE'));
    expect(resolvedLabel, endsWith('.'));
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHLENHYDRATE',
        style: labelStyle,
        maxWidth: 40,
      ),
      isFalse,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: resolvedLabel,
        style: labelStyle,
        maxWidth: 40,
      ),
      isTrue,
    );
  });

  test('resolveMacroLabelForWidth falls back to first letter and dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 1,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'K.');
  });

  test('resolveMacroLabelForWidth returns empty string for empty labels', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: '',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isEmpty);
  });

  testWidgets('switches between balance and classic summary modes', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(BurnWeekLiveOverview), findsOneWidget);
    expect(find.byType(ClassicSummaryHero), findsNothing);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('classic')));
    await tester.pumpAndSettle();

    expect(find.byType(BurnWeekLiveOverview), findsNothing);
    expect(find.byType(ClassicSummaryHero), findsOneWidget);
    expect(find.byType(ClassicSummaryGauge), findsOneWidget);

    await tester.tap(find.byKey(CaloriesPageKeys.summaryModeOption('balance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BurnWeekLiveOverview), findsOneWidget);
    expect(find.byType(ClassicSummaryHero), findsNothing);
  });

  testWidgets('switching to classic closes Burn Week zone dialogs', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final scope = tester.widget<UncontrolledProviderScope>(
      find.byType(UncontrolledProviderScope),
    );
    await scope.container
        .read(calorieSummaryViewModeControllerProvider.notifier)
        .setMode(CalorieSummaryViewMode.classic);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BurnWeekLiveOverview), findsNothing);
    expect(find.byType(ClassicSummaryHero), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    scope.container.dispose();
  });

  testWidgets('renders macro progress cards with current values and progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('carbs')),
      findsOneWidget,
    );
    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('protein')),
      findsOneWidget,
    );
    expect(
      find.byKey(CaloriesPageKeys.summaryMacroCard('fat')),
      findsOneWidget,
    );

    final carbsValue = _macroValue(tester, 'carbs');
    final proteinValue = _macroValue(tester, 'protein');
    final fatValue = _macroValue(tester, 'fat');

    expect(carbsValue.text.toPlainText(), '100 / 225g');
    expect(proteinValue.text.toPlainText(), '90 / 125g');
    expect(fatValue.text.toPlainText(), '40 / 67g');

    final theme = Theme.of(tester.element(find.byType(CaloriesSummaryCard)));
    expect(_currentValueColor(carbsValue), theme.colorScheme.onSurface);
    expect(_currentValueColor(proteinValue), theme.colorScheme.onSurface);
    expect(_currentValueColor(fatValue), theme.colorScheme.onSurface);

    expect(_macroBar(tester, 'carbs').widthFactor, closeTo(100 / 225, 0.0001));
    expect(_macroBar(tester, 'protein').widthFactor, closeTo(90 / 125, 0.0001));
    expect(_macroBar(tester, 'fat').widthFactor, closeTo(0.6, 0.0001));
  });

  testWidgets('highlights a macro value when the current amount is over goal', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(totalCarbs: 280),
    );
    await tester.pumpAndSettle();

    final carbsValue = _macroValue(tester, 'carbs');

    expect(carbsValue.text.toPlainText(), '280 / 225g');
    expect(_currentValueColor(carbsValue), const Color(0xFF3B82F6));
    expect(_macroBar(tester, 'carbs').widthFactor, 1.0);
  });

  testWidgets('balance summary opens Burn Week details dialog', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip('Show Burn Week details'));
    await tester.pumpAndSettle();

    expect(find.text('Burn Week details'), findsOneWidget);
    expect(find.textContaining('Balance recalculates'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('classic mode still syncs Burn live activity state', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      BurnWeekRunState(
        currentWeekStartDayKey: '${today.year}-${today.month}-${today.day}',
        lastActiveDayKey: '2026-04-01',
        runWeekNumber: 2,
        starCount: 1,
        heartCount: 2,
        heartCreditKcal: 0,
        starBrokeThisWeek: false,
        missedTrackingThisWeek: false,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        preferences: MemoryAppPreferences(
          initialStrings: const <String, String>{
            'calories_summary_view_mode': 'classic',
          },
        ),
        runStateRepository: runStateRepository,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(BurnWeekLiveOverview), findsNothing);
    expect(
      runStateRepository.state.lastActiveDayKey,
      '${today.year}-${today.month}-${today.day}',
    );
  });

  testWidgets('sync restarts stale Burn run from the active goal cycle', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = today.subtract(const Duration(days: 1));
    final logRepository = FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry('today', loggedAt: today, totalKcal: 1100),
      ],
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2000,
        calculatorProfile: null,
        effectiveDate: today,
      ),
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      BurnWeekRunState(
        currentWeekStartDayKey:
            '${yesterday.year}-${yesterday.month}-${yesterday.day}',
        runWeekNumber: 3,
        starCount: 2,
        heartCount: 1,
        heartCreditKcal: -500,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        calorieBalanceSummaryProvider.overrideWith(
          (ref) async => _balanceData(),
        ),
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
        child: const _BurnWeekLiveSyncTestBootstrap(
          child: MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 520,
                    child: CaloriesSummaryCard(
                      consumedKcal: 1100,
                      goalKcal: 2000,
                      remainingKcal: 900,
                      progress: 1100 / 2000,
                      totalProtein: 90,
                      totalCarbs: 100,
                      totalFat: 40,
                      consumedLabel: 'Consumed',
                      goalLabel: 'Goal',
                      remainingLabel: 'Remaining',
                      proteinLabel: 'Protein',
                      carbsLabel: 'Carbs',
                      fatLabel: 'Fat',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final todayKey = '${today.year}-${today.month}-${today.day}';
    expect(runStateRepository.state.currentWeekStartDayKey, todayKey);
    expect(runStateRepository.state.runWeekNumber, 1);
    expect(runStateRepository.state.starCount, 0);
    expect(runStateRepository.state.heartCount, 3);
  });

  testWidgets(
    'sync awards stars for multiple fully tracked closed weeks',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final oldestWeekStart = today.subtract(const Duration(days: 21));
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          for (var dayOffset = 21; dayOffset >= 1; dayOffset -= 1)
            _entry(
              'day-$dayOffset',
              loggedAt: today.subtract(Duration(days: dayOffset)),
              totalKcal: 1100,
            ),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: oldestWeekStart,
        ),
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        BurnWeekRunState(
          currentWeekStartDayKey:
              '${oldestWeekStart.year}-'
              '${oldestWeekStart.month}-${oldestWeekStart.day}',
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
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          calorieBalanceSummaryProvider.overrideWith(
            (ref) async => _balanceData(),
          ),
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
          child: const _BurnWeekLiveSyncTestBootstrap(
            child: MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: 520,
                      child: CaloriesSummaryCard(
                        consumedKcal: 1100,
                        goalKcal: 2000,
                        remainingKcal: 900,
                        progress: 1100 / 2000,
                        totalProtein: 90,
                        totalCarbs: 100,
                        totalFat: 40,
                        consumedLabel: 'Consumed',
                        goalLabel: 'Goal',
                        remainingLabel: 'Remaining',
                        proteinLabel: 'Protein',
                        carbsLabel: 'Carbs',
                        fatLabel: 'Fat',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      final todayKey = '${today.year}-${today.month}-${today.day}';
      expect(runStateRepository.state.currentWeekStartDayKey, todayKey);
      expect(runStateRepository.state.runWeekNumber, 4);
      expect(runStateRepository.state.starCount, 3);
      expect(runStateRepository.state.heartCount, 3);
    },
  );

  testWidgets(
    'sync waits for loaded goal settings before scoring skipped days',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final yesterday = today.subtract(const Duration(days: 1));
      final logRepository = FakeCalorieLogRepository();
      final settingsRepository = _DelayedCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: null,
          effectiveDate: yesterday,
        ).setSkippedIntakeDay(day: yesterday, isSkipped: true),
        initialDelay: const Duration(milliseconds: 200),
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        BurnWeekRunState(
          currentWeekStartDayKey:
              '${yesterday.year}-'
              '${yesterday.month}-${yesterday.day}',
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
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          calorieBalanceSummaryProvider.overrideWith(
            (ref) async => _balanceData(),
          ),
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
          child: const _BurnWeekLiveSyncTestBootstrap(
            child: MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: 520,
                      child: CaloriesSummaryCard(
                        consumedKcal: 1100,
                        goalKcal: 2000,
                        remainingKcal: 900,
                        progress: 1100 / 2000,
                        totalProtein: 90,
                        totalCarbs: 100,
                        totalFat: 40,
                        consumedLabel: 'Consumed',
                        goalLabel: 'Goal',
                        remainingLabel: 'Remaining',
                        proteinLabel: 'Protein',
                        carbsLabel: 'Carbs',
                        fatLabel: 'Fat',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(runStateRepository.saveCount, 0);
      expect(runStateRepository.state.missedTrackingThisWeek, isFalse);

      await tester.pump(const Duration(milliseconds: 250));

      expect(runStateRepository.state.missedTrackingThisWeek, isFalse);
    },
  );

  testWidgets(
    'classic summary uses error color when remaining drops below zero',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          preferences: MemoryAppPreferences(
            initialStrings: const <String, String>{
              'calories_summary_view_mode': 'classic',
            },
          ),
          balanceData: _balanceData(baseGoalKcal: 1500),
          consumedKcal: 1600,
          goalKcal: 1500,
          remainingKcal: -100,
        ),
      );
      await tester.pumpAndSettle();

      final classicHero = tester.widget<ClassicSummaryHero>(
        find.byType(ClassicSummaryHero),
      );
      final colorScheme = Theme.of(
        tester.element(find.byType(CaloriesSummaryCard)),
      ).colorScheme;

      expect(classicHero.remainingKcal, -100);
      expect(classicHero.color, colorScheme.error);
    },
  );

  testWidgets(
    'classic summary uses checkbox toggles below macros to update the circle',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          preferences: MemoryAppPreferences(
            initialStrings: const <String, String>{
              'calories_summary_view_mode': 'classic',
            },
          ),
          balanceData: _balanceData(
            activityDeltaKcal: 135,
            activityComparisonKcal: 135,
            carryoverKcal: 240,
            usedLearnedTdee: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(CaloriesPageKeys.summaryMetaSection), findsOneWidget);
      expect(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
        findsOneWidget,
      );
      expect(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
        findsOneWidget,
      );
      expect(find.byType(ClassicSummaryHero), findsOneWidget);
      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('+135'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
      );
      await tester.tap(find.byKey(CaloriesPageKeys.summaryCarryoverToggle));
      await tester.pumpAndSettle();

      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('+240'), findsOneWidget);
      expect(find.text('640'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
      );
      await tester.tap(find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle));
      await tester.pumpAndSettle();

      expect(find.byType(ClassicSummaryGauge), findsOneWidget);
      expect(find.text('505'), findsOneWidget);

      final macroBottom = tester.getBottomLeft(
        find.byKey(CaloriesPageKeys.summaryMacroCard('carbs')),
      );
      final metaTop = tester.getTopLeft(
        find.byKey(CaloriesPageKeys.summaryMetaSection),
      );
      expect(metaTop.dy, greaterThan(macroBottom.dy));
    },
  );

  testWidgets(
    'classic summary restores persisted global toggle selections',
    (tester) async {
      final preferences = MemoryAppPreferences(
        initialStrings: <String, String>{
          'calories_summary_view_mode': 'classic',
          'calories_summary_classic_include_activity_delta': 'false',
          'calories_summary_classic_include_carryover': 'true',
        },
      );

      await tester.pumpWidget(
        _buildHarness(
          preferences: preferences,
          balanceData: _balanceData(
            activityDeltaKcal: 135,
            activityComparisonKcal: 135,
            carryoverKcal: 240,
            usedLearnedTdee: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+240'), findsOneWidget);
      expect(find.text('+135'), findsNothing);
      expect(find.text('505'), findsOneWidget);

      final activityToggle = tester.widget<Checkbox>(
        find.byKey(CaloriesPageKeys.summaryActivityDeltaToggle),
      );
      final carryoverToggle = tester.widget<Checkbox>(
        find.byKey(CaloriesPageKeys.summaryCarryoverToggle),
      );

      expect(activityToggle.value, isFalse);
      expect(carryoverToggle.value, isTrue);
    },
  );
}

Widget _buildHarness({
  AppPreferences? preferences,
  CalorieBalanceSummaryData? balanceData,
  BurnWeekRunStateRepository? runStateRepository,
  double consumedKcal = 1600,
  double goalKcal = 2000,
  double remainingKcal = 400,
  double totalCarbs = 100,
  double totalProtein = 90,
  double totalFat = 40,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 12);
  final yesterday = today.subtract(const Duration(days: 1));
  final logRepository = FakeCalorieLogRepository(
    initialEntries: <CalorieEntry>[
      _entry('yesterday', loggedAt: yesterday, totalKcal: 900),
      _entry('today', loggedAt: today, totalKcal: 1100),
    ],
  );
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: today.subtract(const Duration(days: 6)),
    ),
  );
  final effectiveRunStateRepository =
      runStateRepository ??
      _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-04-21',
          runWeekNumber: 2,
          starCount: 1,
          heartCount: 2,
          heartCreditKcal: 0,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
      );
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(
        preferences ?? MemoryAppPreferences(),
      ),
      calorieBalanceSummaryProvider.overrideWith(
        (ref) async => balanceData ?? _balanceData(),
      ),
      burnWeekLiveSyncTickerPeriodProvider.overrideWithValue(null),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(
        effectiveRunStateRepository,
      ),
      healthConnectionControllerProvider.overrideWith(
        _FakeHealthConnectionController.new,
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: _BurnWeekLiveSyncTestBootstrap(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 520,
                child: CaloriesSummaryCard(
                  consumedKcal: consumedKcal,
                  goalKcal: goalKcal,
                  remainingKcal: remainingKcal,
                  progress: goalKcal <= 0 ? 0 : consumedKcal / goalKcal,
                  totalProtein: totalProtein,
                  totalCarbs: totalCarbs,
                  totalFat: totalFat,
                  consumedLabel: 'Consumed',
                  goalLabel: 'Goal',
                  remainingLabel: 'Remaining',
                  proteinLabel: 'Protein',
                  carbsLabel: 'Carbs',
                  fatLabel: 'Fat',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BurnWeekLiveSyncTestBootstrap extends ConsumerStatefulWidget {
  const _BurnWeekLiveSyncTestBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_BurnWeekLiveSyncTestBootstrap> createState() =>
      _BurnWeekLiveSyncTestBootstrapState();
}

class _BurnWeekLiveSyncTestBootstrapState
    extends ConsumerState<_BurnWeekLiveSyncTestBootstrap> {
  ProviderSubscription<Object?>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription = ref.listenManual<Object?>(
      burnWeekLiveSyncProvider,
      (_, __) {},
    );
  }

  @override
  void dispose() {
    _syncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

RichText _macroValue(WidgetTester tester, String macroId) {
  return tester.widget<RichText>(
    find.byKey(CaloriesPageKeys.summaryMacroValue(macroId)),
  );
}

FractionallySizedBox _macroBar(WidgetTester tester, String macroId) {
  return tester.widget<FractionallySizedBox>(
    find.byKey(CaloriesPageKeys.summaryMacroBar(macroId)),
  );
}

Color? _currentValueColor(RichText value) {
  final span = value.text as TextSpan;
  final children = span.children;
  if (children == null || children.isEmpty) {
    return null;
  }

  return (children.first as TextSpan).style?.color;
}

CalorieBalanceSummaryData _balanceData({
  double baseGoalKcal = 2000,
  double activityDeltaKcal = 0,
  double activityComparisonKcal = 0,
  double carryoverKcal = 0,
  bool usedLearnedTdee = false,
}) {
  final now = DateTime(2026, 4, 10, 14);
  return CalorieBalanceSummaryData(
    selectedDay: DateTime(2026, 4, 10),
    referenceNow: now,
    windowStartDate: now.subtract(const Duration(days: 6)),
    balanceStartDate: now.subtract(const Duration(days: 6)),
    paceWindowStart: DateTime(2026, 4, 10, 6),
    paceWindowEnd: DateTime(2026, 4, 10, 22),
    storedGoalKcal: baseGoalKcal - activityDeltaKcal,
    baseGoalKcal: baseGoalKcal,
    carryoverKcal: carryoverKcal,
    goalMode: CalorieGoalMode.maintain,
    flexibleGoalKcal: baseGoalKcal + carryoverKcal,
    pacedGoalKcal: (baseGoalKcal / 2) + carryoverKcal,
    consumedKcal: 1000,
    deltaKcal: 0,
    paceRatio: 0.5,
    deadZoneKcal: 60,
    rangeKcal: 600,
    activityDeltaKcal: activityDeltaKcal,
    activityComparisonKcal: activityComparisonKcal,
    usedLearnedTdee: usedLearnedTdee,
  );
}
