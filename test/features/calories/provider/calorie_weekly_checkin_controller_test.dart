import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';

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

  test('dismissPendingWeeklyCheckIn syncs and dismisses pending', () async {
    final pendingWeeklyCheckIn = _pendingWeeklyCheckIn();
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
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

    final dismissed = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .dismissPendingWeeklyCheckIn(pendingWeeklyCheckIn);

    expect(dismissed, isTrue);
    final settings = await settingsRepository.readSettings();
    expect(settings.pendingWeeklyCheckIn?.isDismissed, isTrue);
    expect(
      container.read(calorieWeeklyCheckInControllerProvider).hasError,
      isFalse,
    );
  });

  test('showPendingWeeklyCheckInAgain clears pending dismissal', () async {
    final dismissedPending = _pendingWeeklyCheckIn().copyWith(
      dismissedAt: DateTime(2026, 4, 15, 10),
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal().copyWithPendingWeeklyCheckIn(
        dismissedPending,
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

    final shown = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .showPendingWeeklyCheckInAgain(dismissedPending);

    expect(shown, isTrue);
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

  test('dismissPendingWeeklyCheckIn reports sync failure', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: _settingsWithGoal(),
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

    final dismissed = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .dismissPendingWeeklyCheckIn(_pendingWeeklyCheckIn());

    expect(dismissed, isFalse);
    expect(
      container.read(calorieWeeklyCheckInControllerProvider).hasError,
      isTrue,
    );
  });

  test(
    'syncLearnedTdeeCache ignores blocked or incomplete datas',
    () async {
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: _settingsWithGoal(),
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
    },
  );

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
        calorieSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(calorieGoalControllerProvider.future);

    final applied = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .applyWeeklyCheckIn(
          _weeklyCheckInData(
            pendingWeeklyCheckIn: pendingWeeklyCheckIn,
          ),
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
        calorieSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
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

  test(
    'applyWeeklyCheckIn stores learned cache without changing active goal',
    () async {
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
          heartCount: 0,
          heartCreditKcal: 0,
          starBrokeThisWeek: true,
          missedTrackingThisWeek: false,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
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
      expect(settings.goalKcalForDay(dueDate), 2426.875);
      expect(settings.latestGoalEntry?.effectiveDate, goalStart);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.pendingWeeklyCheckIn?.isDismissed, isTrue);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2665.82);
      final snapshot = settings.latestLearnedTdeeEntry?.weeklyCheckInSnapshot;
      expect(snapshot?.windowStartDate, goalStart);
      expect(snapshot?.windowEndDate, DateTime(2026, 4, 14));
      expect(runStateRepository.state.heartCount, burnWeekInitialHeartCount);
    },
  );

  test(
    'syncLearnedTdeeCache stores learned cache without dismissing hint',
    () async {
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
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(calorieGoalControllerProvider.future);

      final saved = await container
          .read(calorieWeeklyCheckInControllerProvider.notifier)
          .syncLearnedTdeeCache(
            _weeklyCheckInData(
              pendingWeeklyCheckIn: pendingWeeklyCheckIn,
            ),
          );

      expect(saved, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(
        settings.pendingWeeklyCheckIn?.windowKey,
        pendingWeeklyCheckIn.windowKey,
      );
      expect(settings.pendingWeeklyCheckIn?.isDismissed, isFalse);
      expect(settings.latestGoalEntry?.source, CalorieGoalSource.calculator);
      expect(settings.hasLearnedTdee, isTrue);
      expect(settings.latestLearnedTdeeKcal, 2665.82);
    },
  );

  test('syncLearnedTdeeCache refreshes stale same-window cache', () async {
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
        calorieSettingsRepositoryProvider.overrideWithValue(
          settingsRepository,
        ),
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
        calculatedTrueTdeeKcal: 2500,
        averageActiveKcal: 200,
        lowConfidence: false,
      ),
    );

    final refreshed = await container
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .syncLearnedTdeeCache(
          _weeklyCheckInData(
            pendingWeeklyCheckIn: pendingWeeklyCheckIn,
          ),
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
    expect(snapshots.single.averageActiveKcal, 300);
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
              calculatedTrueTdeeKcal: 2500,
              averageActiveKcal: 200,
              lowConfidence: false,
            ),
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
              measuredTotalTdeeKcal:
                  _defaultWeeklyCheckInCalculation.measuredTotalTdeeKcal,
              measuredBaseTdeeKcal:
                  _defaultWeeklyCheckInCalculation.measuredBaseTdeeKcal,
              calculatedBaseTdeeKcal:
                  _defaultWeeklyCheckInCalculation.calculatedTrueTdeeKcal,
              averageCreditedActivityKcal:
                  _defaultWeeklyCheckInCalculation.lastWeekAverageActiveKcal,
              baseGoalKcal: _defaultWeeklyCheckInCalculation.newGoalKcal,
              lowConfidence: false,
            ),
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
        calculatedTrueTdeeKcal: 2500,
        averageActiveKcal: 200,
        lowConfidence: false,
      );
      final freshSnapshot = CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: goalStart,
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.10893,
        measuredTotalTdeeKcal:
            _defaultWeeklyCheckInCalculation.measuredTotalTdeeKcal,
        measuredBaseTdeeKcal:
            _defaultWeeklyCheckInCalculation.measuredBaseTdeeKcal,
        calculatedBaseTdeeKcal:
            _defaultWeeklyCheckInCalculation.calculatedTrueTdeeKcal,
        averageCreditedActivityKcal:
            _defaultWeeklyCheckInCalculation.lastWeekAverageActiveKcal,
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
            _weeklyCheckInData(
              pendingWeeklyCheckIn: pendingWeeklyCheckIn,
            ),
          );

      expect(refreshed, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(settings.latestLearnedTdeeKcal, 2500);
      expect(
        settings.latestGoalEntry?.weeklyCheckInSnapshot?.calculatedTrueTdeeKcal,
        2500,
      );
      final weeklyCheckInEntry = settings.goalHistory.firstWhere(
        (entry) => entry.isWeeklyCheckIn,
      );
      expect(
        weeklyCheckInEntry.weeklyCheckInSnapshot?.calculatedTrueTdeeKcal,
        2665.82,
      );
    },
  );
}

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

CalorieWeeklyCheckInData _weeklyCheckInData({
  PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  PendingCalorieGoalWeeklyCheckIn? cacheWeeklyCheckIn,
  bool withoutCalculation = false,
  CalorieWeeklyCheckInCalculation? calculation,
  CalorieWeeklyCheckInBlockedReason? blockedReason,
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
  trendWeightChangePerDay: -0.10893,
  averageIntakeKcal: 2460.85,
  measuredTrueTdeeKcal: 3223.35,
  calculatedTrueTdeeKcal: 2665.82,
  newGoalKcal: 2626.875,
  lastWeekAverageActiveKcal: 300,
  todayActiveKcal: 8,
  activityDeltaKcal: 0,
  dynamicGoalTodayKcal: 2626.875,
);
