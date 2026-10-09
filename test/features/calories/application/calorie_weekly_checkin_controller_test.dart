import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test(
    'syncPendingWeeklyCheckIn skips save when same pending exists',
    () async {
      final pendingWeeklyCheckIn = _pendingWeeklyCheckIn();
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: _settingsWithGoal().copyWithPendingWeeklyCheckIn(
          pendingWeeklyCheckIn,
        ),
      )..saveShouldFail = true;
      addTearDown(settingsRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final synced = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .syncPendingWeeklyCheckIn(pendingWeeklyCheckIn);

      expect(synced, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(
        settings.pendingWeeklyCheckIn?.windowKey,
        pendingWeeklyCheckIn.windowKey,
      );
    },
  );

  test('syncPendingWeeklyCheckIn reports a failed read as an error', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    )..readError = Exception('client is offline');
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    final states = <AsyncValue<void>>[];
    container.listen(
      calorieWeeklyCheckInControllerProvider,
      (previous, next) => states.add(next),
    );

    final synced = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncPendingWeeklyCheckIn(_pendingWeeklyCheckIn());

    expect(synced, isFalse);
    expect(states.last, isA<AsyncError<void>>());
  });

  test('showPendingWeeklyCheckInAgain clears pending dismissal and reloads '
      'the check-in data', () async {
    final dismissedPending = _pendingWeeklyCheckIn().copyWith(
      dismissedAt: DateTime(2026, 4, 15, 10),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal().copyWithPendingWeeklyCheckIn(
        dismissedPending,
      ),
    );
    addTearDown(settingsRepository.dispose);
    var dataBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieWeeklyCheckInDataProvider.overrideWith((ref) {
          dataBuilds += 1;
          return _weeklyCheckInData(pendingWeeklyCheckIn: dismissedPending);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(calorieWeeklyCheckInDataProvider, (_, _) {});
    await container.read(calorieGoalControllerProvider.future);
    await container.read(calorieWeeklyCheckInDataProvider.future);

    final shown = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .showPendingWeeklyCheckInAgain(dismissedPending);
    await container.read(calorieWeeklyCheckInDataProvider.future);

    expect(shown, isTrue);
    expect(dataBuilds, 2);
    final settings = await settingsRepository.readSettings();
    expect(
      settings.pendingWeeklyCheckIn?.windowKey,
      dismissedPending.windowKey,
    );
    expect(settings.pendingWeeklyCheckIn?.isDismissed, isFalse);
    expect(
      container.read(calorieWeeklyCheckInControllerProvider).hasError,
      isFalse,
    );
  });

  test('syncLearnedTdeeCache ignores blocked or incomplete datas', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    )..saveShouldFail = true;
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    final incomplete = await controller.syncLearnedTdeeCache(
      _weeklyCheckInData(
        pendingWeeklyCheckIn: _pendingWeeklyCheckIn(),
        withoutCalculation: true,
      ),
    );
    final blocked = await controller.syncLearnedTdeeCache(
      _weeklyCheckInData(
        pendingWeeklyCheckIn: _pendingWeeklyCheckIn(),
        blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
      ),
    );

    expect(incomplete, isTrue);
    expect(blocked, isTrue);
    expect((await settingsRepository.readSettings()).hasLearnedTdee, isFalse);
  });

  test('applyWeeklyCheckIn reports learned cache save failure', () async {
    final pendingWeeklyCheckIn = _pendingWeeklyCheckIn();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal().copyWithPendingWeeklyCheckIn(
        pendingWeeklyCheckIn,
      ),
    )..saveShouldFail = true;
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final applied = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .applyWeeklyCheckIn(
          _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
        );

    expect(applied, isFalse);
    expect(
      container.read(calorieWeeklyCheckInControllerProvider).hasError,
      isTrue,
    );
  });

  test('applyWeeklyCheckIn returns false for blocked data', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);

    final applied = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .applyWeeklyCheckIn(
          _weeklyCheckInData(
            pendingWeeklyCheckIn: _pendingWeeklyCheckIn(),
            blockedReason: CalorieWeeklyCheckInBlockedReason.missingIntakeDays,
          ),
        );

    expect(applied, isFalse);
  });

  test('applyWeeklyCheckIn stores learned cache and updates active goal for '
      'due date', () async {
    final goalStart = DateTime(2026, 4, 8);
    final dueDate = DateTime(2026, 4, 15);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2426.875,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 84,
          heightCm: 172,
          ageYears: 31,
          activityLevel: 1.375,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: goalStart,
        source: CalorieGoalSource.calculator,
      ),
    );
    addTearDown(settingsRepository.dispose);
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-8',
        runWeekNumber: 2,
        starCount: 1,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .applyWeeklyCheckIn(
          _weeklyCheckInData(
            pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
              windowStartDate: goalStart,
              windowEndDate: DateTime(2026, 4, 14),
              dueDate: dueDate,
              dismissedAt: DateTime(2026, 4, 27, 10),
            ),
          ),
        );

    expect(saved, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.goalKcalForDay(DateTime(2026, 4, 14)), 2426.875);
    expect(settings.goalKcalForDay(dueDate), 2626.875);
    expect(settings.latestGoalEntry?.effectiveDate, goalStart);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
    expect(settings.pendingWeeklyCheckIn, isNull);
    expect(settings.hasLearnedTdee, isTrue);
    expect(settings.latestLearnedTdeeKcal, 2665.82);
    final snapshot = settings.latestLearnedTdeeEntry?.weeklyCheckInSnapshot;
    expect(snapshot?.windowStartDate, goalStart);
    expect(snapshot?.windowEndDate, DateTime(2026, 4, 14));
    expect(snapshot?.macroWeightKg, 82.4);
    expect(settings.macroWeightKgForDay(DateTime(2026, 4, 14)), 84);
    expect(settings.macroWeightKgForDay(dueDate), 82.4);
  });

  group('training days of the next run', () {
    final goalStart = DateTime(2026, 4, 8);
    final dueDate = DateTime(2026, 4, 15);
    final trainingDays = {DateTime(2026, 4, 16), DateTime(2026, 4, 18)};

    Future<
      ({ProviderContainer container, FakeCalorieSettingsRepository repository})
    >
    start() async {
      final repository = FakeCalorieSettingsRepository(
        initialSettings: CalorieGoalSettings.single(
          dailyKcalGoal: 2400,
          calculatorProfile: null,
          effectiveDate: goalStart,
        ),
      );
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => dueDate),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);
      return (container: container, repository: repository);
    }

    CalorieWeeklyCheckInData data() => _weeklyCheckInData(
      pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: dueDate,
      ),
    );

    test('apply saves them with the decision in one write', () async {
      final (:container, :repository) = await start();
      var writes = 0;
      repository.onSaveSettings = (_) async => writes += 1;

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .applyWeeklyCheckIn(
            data(),
            training: (runDay: dueDate, trainingDays: trainingDays),
          );

      expect(saved, isTrue);
      final settings = await repository.readSettings();
      expect(settings.isTrainingDay(DateTime(2026, 4, 16)), isTrue);
      expect(settings.isTrainingDay(DateTime(2026, 4, 17)), isFalse);
      expect(settings.isTrainingDay(DateTime(2026, 4, 18)), isTrue);
      expect(settings.pendingWeeklyCheckIn, isNull);
      expect(writes, 1);
    });

    test('a run that has ended decides nothing', () async {
      final (:container, :repository) = await start();

      // The sheet planned the run of Apr 8–14; the clock is in the next one.
      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .applyWeeklyCheckIn(
            data(),
            training: (runDay: goalStart, trainingDays: {goalStart}),
          );

      expect(saved, isFalse);
      final settings = await repository.readSettings();
      expect(settings.trainingDayOverrides, isEmpty);
      expect(settings.goalHistory, hasLength(1));
    });

    test('a failed save leaves nothing half applied', () async {
      final (:container, :repository) = await start();
      repository.saveShouldFail = true;

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .rejectWeeklyCheckIn(
            data(),
            training: (runDay: dueDate, trainingDays: trainingDays),
          );

      expect(saved, isFalse);
      final settings = await repository.readSettings();
      expect(settings.isTrainingDay(DateTime(2026, 4, 16)), isFalse);
      expect(settings.goalHistory, hasLength(1));
      expect(
        container.read(calorieWeeklyCheckInControllerProvider).hasError,
        isTrue,
      );
    });
  });

  test('rejectWeeklyCheckIn preserves previous goal, marks snapshot rejected, '
      'and clears pending', () async {
    final goalStart = DateTime(2026, 4, 8);
    final dueDate = DateTime(2026, 4, 15);
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2426.875,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 84,
          heightCm: 172,
          ageYears: 31,
          activityLevel: 1.375,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: goalStart,
        source: CalorieGoalSource.calculator,
      ),
    );
    addTearDown(settingsRepository.dispose);
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      const BurnWeekRunState(
        currentWeekStartDayKey: '2026-4-8',
        runWeekNumber: 2,
        starCount: 1,
        starBrokeThisWeek: true,
        missedTrackingThisWeek: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          runStateRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final checkInData = _weeklyCheckInData(
      pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: dueDate,
      ),
    );

    final saved = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .rejectWeeklyCheckIn(checkInData);

    expect(saved, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.goalKcalForDay(DateTime(2026, 4, 14)), 2426.875);
    expect(settings.goalKcalForDay(dueDate), 2426.875);
    expect(settings.pendingWeeklyCheckIn, isNull);
    final history = settings.sortedGoalHistory;
    final checkInEntry = history.firstWhere((e) => e.isWeeklyCheckIn);
    expect(checkInEntry.weeklyCheckInSnapshot?.isRejected, isTrue);
    expect(checkInEntry.hasLearnedTdee, isFalse);
    // A rejected goal change still moves the macros to the new weight.
    expect(checkInEntry.weeklyCheckInSnapshot?.macroWeightKg, 82.4);
    expect(settings.macroWeightKgForDay(dueDate), 82.4);
  });

  test('syncLearnedTdeeCache keeps the latest due check-in open', () async {
    final today = DateTime(2026, 4, 15);
    final goalStart = DateTime(2026, 4, 8);
    final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: goalStart,
      windowEndDate: DateTime(2026, 4, 14),
      dueDate: DateTime(2026, 4, 15),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2426.875,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 84,
          heightCm: 172,
          ageYears: 31,
          activityLevel: 1.375,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: goalStart,
        source: CalorieGoalSource.calculator,
      ).copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => today),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncLearnedTdeeCache(
          _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
        );

    expect(saved, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(
      settings.pendingWeeklyCheckIn?.windowKey,
      pendingWeeklyCheckIn.windowKey,
    );
    expect(settings.pendingWeeklyCheckIn?.isDismissed, isFalse);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
    expect(settings.hasLearnedTdee, isFalse);
    expect(
      resolvePendingCalorieWeeklyCheckIn(
        settings: settings,
        today: pendingWeeklyCheckIn.dueDate,
      )?.windowKey,
      pendingWeeklyCheckIn.windowKey,
    );
  });

  test('syncLearnedTdeeCache saves an older missed window', () async {
    final today = DateTime(2026, 4, 29);
    final goalStart = DateTime(2026, 4, 8);
    final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: goalStart,
      windowEndDate: DateTime(2026, 4, 14),
      dueDate: DateTime(2026, 4, 15),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2426.875,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 84,
          heightCm: 172,
          ageYears: 31,
          activityLevel: 1.375,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: goalStart,
        source: CalorieGoalSource.calculator,
      ).copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        clockProvider.overrideWithValue(() => today),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final saved = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncLearnedTdeeCache(
          _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
        );

    expect(saved, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.hasLearnedTdee, isTrue);
    expect(settings.latestLearnedTdeeKcal, 2665.82);
  });

  test(
    'applyWeeklyCheckIn saves the goal after an earlier rejection',
    () async {
      final goalStart = DateTime(2026, 4, 8);
      final dueDate = DateTime(2026, 4, 15);
      final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: dueDate,
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings:
            CalorieGoalSettings.single(
                  dailyKcalGoal: 2426.875,
                  calculatorProfile: null,
                  effectiveDate: goalStart,
                  source: CalorieGoalSource.calculator,
                )
                .applyGoalChange(
                  changedAt: dueDate,
                  dailyKcalGoal: 2426.875,
                  calculatorProfile: null,
                  source: CalorieGoalSource.weeklyCheckIn,
                  weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
                    windowStartDate: goalStart,
                    windowEndDate: DateTime(2026, 4, 14),
                    trendWeightChangePerDay: 0,
                    calculatedTdeeKcal: 2500,
                    lowConfidence: false,
                    isRejected: true,
                  ),
                )
                .copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
      );
      addTearDown(settingsRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .applyWeeklyCheckIn(
            _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
          );

      expect(saved, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(settings.goalKcalForDay(dueDate), 2626.875);
      expect(settings.pendingWeeklyCheckIn, isNull);
    },
  );

  test('applyWeeklyCheckIn replaces a stale snapshot of its window', () async {
    final goalStart = DateTime(2026, 4, 8);
    final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: goalStart,
      windowEndDate: DateTime(2026, 4, 14),
      dueDate: DateTime(2026, 4, 15),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2426.875,
        calculatorProfile: const CalorieCalculatorProfile(
          sex: CalorieCalculatorSex.male,
          weightKg: 84,
          heightCm: 172,
          ageYears: 31,
          activityLevel: 1.375,
          goalMode: CalorieGoalMode.maintain,
          goalSpeedKgPerWeek: 0,
        ),
        effectiveDate: goalStart,
        source: CalorieGoalSource.calculator,
      ).copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final goalController = container.read(
      calorieGoalControllerProvider.notifier,
    );
    final savedStaleSnapshot = await goalController.saveWeeklyCheckInGoal(
      completedAt: pendingWeeklyCheckIn.dueDate,
      dailyKcalGoal: 2500,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.02,
        calculatedTdeeKcal: 2500,
        lowConfidence: false,
      ),
    );

    final refreshed = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .applyWeeklyCheckIn(
          _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
        );

    expect(savedStaleSnapshot, isTrue);
    expect(refreshed, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.latestLearnedTdeeKcal, 2665.82);
    expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
    final snapshots = settings.goalHistory
        .map((entry) => entry.weeklyCheckInSnapshot)
        .whereType<CalorieGoalWeeklyCheckInSnapshot>()
        .toList(growable: false);
    expect(snapshots, hasLength(1));
    expect(snapshots.single.calculatedTdeeKcal, 2665.82);
  });

  test('syncLearnedTdeeCache refreshes hidden cache-only window', () async {
    final goalStart = DateTime(2026, 4, 8);
    final cacheWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: goalStart,
      windowEndDate: DateTime(2026, 4, 14),
      dueDate: DateTime(2026, 4, 15),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings:
          CalorieGoalSettings.single(
            dailyKcalGoal: 2426.875,
            calculatorProfile: const CalorieCalculatorProfile(
              sex: CalorieCalculatorSex.male,
              weightKg: 84,
              heightCm: 172,
              ageYears: 31,
              activityLevel: 1.375,
              goalMode: CalorieGoalMode.maintain,
              goalSpeedKgPerWeek: 0,
            ),
            effectiveDate: goalStart,
            source: CalorieGoalSource.calculator,
          ).applyGoalChange(
            changedAt: cacheWeeklyCheckIn.dueDate,
            dailyKcalGoal: 2500,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: goalStart,
              windowEndDate: DateTime(2026, 4, 14),
              trendWeightChangePerDay: -0.02,
              calculatedTdeeKcal: 2500,
              lowConfidence: false,
            ),
          ),
    );
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final refreshed = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncLearnedTdeeCache(
          _weeklyCheckInData(cacheWeeklyCheckIn: cacheWeeklyCheckIn),
        );

    expect(refreshed, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.pendingWeeklyCheckIn, isNull);
    expect(settings.latestLearnedTdeeKcal, 2665.82);
  });

  test('syncLearnedTdeeCache skips save for matching cache snapshot', () async {
    final goalStart = DateTime(2026, 4, 8);
    final cacheWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: goalStart,
      windowEndDate: DateTime(2026, 4, 14),
      dueDate: DateTime(2026, 4, 15),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings:
          CalorieGoalSettings.single(
            dailyKcalGoal: 2426.875,
            calculatorProfile: const CalorieCalculatorProfile(
              sex: CalorieCalculatorSex.male,
              weightKg: 84,
              heightCm: 172,
              ageYears: 31,
              activityLevel: 1.375,
              goalMode: CalorieGoalMode.maintain,
              goalSpeedKgPerWeek: 0,
            ),
            effectiveDate: goalStart,
            source: CalorieGoalSource.calculator,
          ).applyGoalChange(
            changedAt: cacheWeeklyCheckIn.dueDate,
            dailyKcalGoal: _defaultWeeklyCheckInCalculation.newGoalKcal,
            calculatorProfile: null,
            source: CalorieGoalSource.weeklyCheckIn,
            weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
              windowStartDate: cacheWeeklyCheckIn.windowStartDate,
              windowEndDate: cacheWeeklyCheckIn.windowEndDate,
              trendWeightChangePerDay:
                  _defaultWeeklyCheckInCalculation.trendWeightChangePerDay,
              measuredTdeeKcal:
                  _defaultWeeklyCheckInCalculation.measuredTdeeKcal,
              calculatedTdeeKcal:
                  _defaultWeeklyCheckInCalculation.calculatedTdeeKcal,
              baseGoalKcal: _defaultWeeklyCheckInCalculation.newGoalKcal,
              lowConfidence: false,
              macroWeightKg: 82.4,
            ),
          ),
    )..saveShouldFail = true;
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final synced = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncLearnedTdeeCache(
          _weeklyCheckInData(cacheWeeklyCheckIn: cacheWeeklyCheckIn),
        );

    expect(synced, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.latestLearnedTdeeKcal, 2665.82);
  });

  test(
    'syncLearnedTdeeCache does not refresh copied same-window snapshots',
    () async {
      final goalStart = DateTime(2026, 4, 8);
      final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        dueDate: DateTime(2026, 4, 15),
      );
      final staleSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.02,
        calculatedTdeeKcal: 2500,
        lowConfidence: false,
      );
      final freshSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.10893,
        measuredTdeeKcal: _defaultWeeklyCheckInCalculation.measuredTdeeKcal,
        calculatedTdeeKcal: _defaultWeeklyCheckInCalculation.calculatedTdeeKcal,
        baseGoalKcal: _defaultWeeklyCheckInCalculation.newGoalKcal,
        lowConfidence: false,
      );
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings:
            CalorieGoalSettings.single(
                  dailyKcalGoal: 2426.875,
                  calculatorProfile: const CalorieCalculatorProfile(
                    sex: CalorieCalculatorSex.male,
                    weightKg: 84,
                    heightCm: 172,
                    ageYears: 31,
                    activityLevel: 1.375,
                    goalMode: CalorieGoalMode.maintain,
                    goalSpeedKgPerWeek: 0,
                  ),
                  effectiveDate: goalStart,
                  source: CalorieGoalSource.calculator,
                )
                .applyGoalChange(
                  changedAt: pendingWeeklyCheckIn.dueDate,
                  dailyKcalGoal: 2500,
                  calculatorProfile: null,
                  source: CalorieGoalSource.weeklyCheckIn,
                  weeklyCheckInSnapshot: freshSnapshot,
                )
                .applyGoalChange(
                  changedAt: pendingWeeklyCheckIn.dueDate.add(
                    const Duration(hours: 9),
                  ),
                  dailyKcalGoal: 2500,
                  calculatorProfile: const CalorieCalculatorProfile.defaults(),
                  source: CalorieGoalSource.calculator,
                  weeklyCheckInSnapshot: staleSnapshot,
                ),
      );
      addTearDown(settingsRepository.dispose);
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final refreshed = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .syncLearnedTdeeCache(
            _weeklyCheckInData(pendingWeeklyCheckIn: pendingWeeklyCheckIn),
          );

      expect(refreshed, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(settings.latestLearnedTdeeKcal, 2500);
      expect(
        settings.latestGoalEntry?.weeklyCheckInSnapshot?.calculatedTdeeKcal,
        2500,
      );
      final weeklyCheckInEntry = settings.goalHistory.firstWhere(
        (entry) => entry.isWeeklyCheckIn,
      );
      expect(
        weeklyCheckInEntry.weeklyCheckInSnapshot?.calculatedTdeeKcal,
        2665.82,
      );
    },
  );
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}

CalorieWeeklyCheckInData _weeklyCheckInData({
  PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  PendingCalorieGoalWeeklyCheckIn? cacheWeeklyCheckIn,
  bool withoutCalculation = false,
  CalorieWeeklyCheckInCalculation? calculation,
  CalorieWeeklyCheckInBlockedReason? blockedReason,
  double? macroWeightKg = 82.4,
}) {
  assert(
    pendingWeeklyCheckIn != null || cacheWeeklyCheckIn != null,
    'A pending or cache weekly check-in is required.',
  );
  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    cacheWeeklyCheckIn: cacheWeeklyCheckIn,
    shouldAutoOpen: false,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: withoutCalculation
        ? null
        : calculation ?? _defaultWeeklyCheckInCalculation,
    blockedReason: blockedReason,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
    macroWeightKg: macroWeightKg,
  );
}

PendingCalorieGoalWeeklyCheckIn _pendingWeeklyCheckIn() {
  final goalStart = DateTime(2026, 4, 8);
  return PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: goalStart,
    windowEndDate: DateTime(2026, 4, 14),
    dueDate: DateTime(2026, 4, 15),
  );
}

CalorieGoalSettings _settingsWithGoal() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2426.875,
    calculatorProfile: const CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.male,
      weightKg: 84,
      heightCm: 172,
      ageYears: 31,
      activityLevel: 1.375,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    ),
    effectiveDate: DateTime(2026, 4, 8),
    source: CalorieGoalSource.calculator,
  );
}

const _defaultWeeklyCheckInCalculation = CalorieWeeklyCheckInCalculation(
  previousTdeeKcal: 2000,
  trendWeightChangePerDay: -0.10893,
  averageIntakeKcal: 2460.85,
  measuredTdeeKcal: 3223.35,
  calculatedTdeeKcal: 2665.82,
  newGoalKcal: 2626.875,
  dynamicGoalTodayKcal: 2626.875,
);
