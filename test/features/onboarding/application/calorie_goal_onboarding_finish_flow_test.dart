import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_catch_up_placeholder_writer.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';

import '../../calories/support/fake_calories_repositories.dart';

const _profile = CalorieCalculatorProfile.defaults();
const _placeholderName = 'Estimated meal';

ProviderContainer _buildHarness({
  required CalorieSettingsRepository settingsRepository,
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
  return container;
}

Future<void> _primeHarness(ProviderContainer container) async {
  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);
}

Future<bool> _saveOnboardingGoal(
  ProviderContainer container, {
  required DateTime goalStartDate,
  bool? countGoalStartDayForLearning,
  CalorieGoalOnboardingCatchUpEstimate? catchUpEstimate,
  String placeholderName = _placeholderName,
  DateTime? now,
}) {
  final flow = container.read(calorieGoalOnboardingFinishFlowProvider);
  return flow.saveGoal(
    CalorieGoalOnboardingFinishRequest(
      profile: _profile,
      dailyGoalKcal: CalorieGoalCalculator.calculate(_profile).finalGoalKcal,
      goalStartDate: goalStartDate,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
      catchUpEstimate: catchUpEstimate,
      placeholderName: placeholderName,
      now: now,
    ),
  );
}

CalorieEntry _todayLunchEntry(DateTime now, {double totalKcal = 400}) {
  return CalorieEntry.create(
    id: 'today',
    userId: 'user-1',
    name: 'Lunch',
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: 10,
    per100Carbs: 10,
    per100Fat: 10,
    loggedAt: now.subtract(const Duration(hours: 2)),
    createdAt: now.subtract(const Duration(hours: 2)),
    updatedAt: now.subtract(const Duration(hours: 2)),
  );
}

CalorieGoalSettings _learnedTdeeSettings(DateTime effectiveDate) {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 1800,
    calculatorProfile: const CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 70,
      heightCm: 170,
      ageYears: 30,
      activityLevel: 1.2,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    ),
    effectiveDate: effectiveDate,
    source: CalorieGoalSource.weeklyCheckIn,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: effectiveDate.subtract(const Duration(days: 7)),
      windowEndDate: effectiveDate.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.05,
      calculatedTrueTdeeKcal: 2100,
      averageActiveKcal: 120,
      lowConfidence: false,
    ),
  );
}

void main() {
  group('CalorieGoalOnboardingFinishFlow', () {
    test('watched provider keeps flow and goal controller alive', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository();
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);
      final subscription = container.listen(
        calorieGoalOnboardingFinishFlowProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.pump();
      final flow = container.read(calorieGoalOnboardingFinishFlowProvider);

      final saved = await flow.saveGoal(
        CalorieGoalOnboardingFinishRequest(
          profile: _profile,
          dailyGoalKcal: CalorieGoalCalculator.calculate(
            _profile,
          ).finalGoalKcal,
          goalStartDate: now,
          countGoalStartDayForLearning: null,
          catchUpEstimate: null,
          placeholderName: _placeholderName,
          now: now,
        ),
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
      expect((await settingsRepository.readSettings()).hasGoal, isTrue);
    });

    test('allows a future goal start and resets Burn Week', () async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository();
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-4-10',
          lastActiveDayKey: '2026-4-10',
          runWeekNumber: 2,
          starCount: 1,
          heartCount: 2,
          heartCreditKcal: 500,
          starBrokeThisWeek: false,
          missedTrackingThisWeek: false,
        ),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final futureGoalStart = DateTime.now().add(const Duration(days: 2));
      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: futureGoalStart,
      );

      expect(saved, isTrue);
      final settings = await settingsRepository.readSettings();
      expect(
        settings.nextGoalStartAfterDay(DateTime.now()),
        DateTime(
          futureGoalStart.year,
          futureGoalStart.month,
          futureGoalStart.day,
        ),
      );
      expect(runStateRepository.state.currentWeekStartDayKey, isNull);
      expect(runStateRepository.state.heartCreditKcal, 0);
      expect(runStateRepository.state.runWeekNumber, 1);
    });

    test('learned TDEE same-day goal starts Burn Week as game week', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: _learnedTdeeSettings(
          now.subtract(const Duration(days: 1)),
        ),
      );
      final logRepository = FakeCalorieLogRepository();
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        now: now,
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
      expect(
        runStateRepository.state.runWeekNumber,
        burnWeekFirstGameRunWeekNumber,
      );
      expect(runStateRepository.state.heartCreditKcal, 0);
    });

    test('learned TDEE future goal schedules game week start', () async {
      final now = DateTime(2026, 4, 22, 12);
      final futureGoalStart = DateTime(2026, 4, 24, 9);
      final settingsRepository = FakeCalorieSettingsRepository(
        initialSettings: _learnedTdeeSettings(
          now.subtract(const Duration(days: 1)),
        ),
      );
      final logRepository = FakeCalorieLogRepository();
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: futureGoalStart,
        now: now,
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-24');
      expect(
        runStateRepository.state.runWeekNumber,
        burnWeekFirstGameRunWeekNumber,
      );
    });

    test('same-day normal catch-up creates placeholder entries', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _todayLunchEntry(now),
        ],
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
        now: now,
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
      expect(runStateRepository.state.heartCreditKcal, 0);
      final placeholders = logRepository.entries
          .where((e) => e.name == _placeholderName)
          .toList();
      expect(placeholders, isNotEmpty);
      final totalPlaceholderKcal = placeholders.fold<double>(
        0,
        (sum, e) => sum + e.totalKcal,
      );
      expect(totalPlaceholderKcal, greaterThan(0));
    });

    test(
      'same-day exact start restarts Burn Week without placeholders',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final settingsRepository = FakeCalorieSettingsRepository();
        final logRepository = FakeCalorieLogRepository(
          initialEntries: <CalorieEntry>[
            _todayLunchEntry(now),
          ],
        );
        final runStateRepository = _FakeBurnWeekRunStateRepository(
          const BurnWeekRunState(
            currentWeekStartDayKey: '2026-4-1',
            lastActiveDayKey: '2026-4-8',
            runWeekNumber: 2,
            starCount: 2,
            heartCount: 1,
            heartCreditKcal: 600,
            starBrokeThisWeek: true,
            missedTrackingThisWeek: true,
          ),
        );
        addTearDown(settingsRepository.dispose);
        addTearDown(logRepository.dispose);
        final container = _buildHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );

        await _primeHarness(container);

        final saved = await _saveOnboardingGoal(
          container,
          goalStartDate: now,
          countGoalStartDayForLearning: true,
          now: now,
        );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.runWeekNumber, 1);
        expect(runStateRepository.state.heartCreditKcal, 0);
        expect(
          logRepository.entries.where((e) => e.name == _placeholderName),
          isEmpty,
        );
        final settings = await settingsRepository.readSettings();
        expect(
          settings.goalHistory.single.effectiveDate,
          DateTime(2026, 4, 22),
        );
        expect(
          settings.goalHistory.single.effectiveCountingStartDate,
          DateTime(2026, 4, 22),
        );
      },
    );

    test('catch-up ignores entries logged after current time', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _todayLunchEntry(now, totalKcal: 5000).copyWith(
            id: 'future',
            loggedAt: now.add(const Duration(hours: 1)),
          ),
        ],
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
        now: now,
      );

      expect(saved, isTrue);
      expect(
        logRepository.entries.where((e) => e.name == _placeholderName),
        isNotEmpty,
      );
    });

    test(
      'empty placeholder name skips catch-up entries but starts run',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final settingsRepository = FakeCalorieSettingsRepository();
        final logRepository = FakeCalorieLogRepository();
        final runStateRepository = _FakeBurnWeekRunStateRepository(
          const BurnWeekRunState.initial(),
        );
        addTearDown(settingsRepository.dispose);
        addTearDown(logRepository.dispose);
        final container = _buildHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );

        await _primeHarness(container);

        final saved = await _saveOnboardingGoal(
          container,
          goalStartDate: now,
          catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.high,
          placeholderName: '',
          now: now,
        );

        expect(saved, isTrue);
        expect(logRepository.entries, isEmpty);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, 0);
      },
    );

    test('aborts when catch-up placeholder save fails', () async {
      final now = DateTime(2026, 4, 22, 12);
      var saveCallCount = 0;
      final settingsRepository = FakeCalorieSettingsRepository()
        ..onSaveSettings = (_) async {
          saveCallCount += 1;
        };
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _todayLunchEntry(now),
        ],
      )..saveShouldFail = true;
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
        now: now,
      );

      expect(saved, isFalse);
      expect(saveCallCount, 1);
      expect(runStateRepository.state, const BurnWeekRunState.initial());
      expect((await settingsRepository.readSettings()).hasGoal, isTrue);
    });

    test(
      'does not start Burn Week or write placeholders when goal save fails',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final settingsRepository = FakeCalorieSettingsRepository()
          ..saveShouldFail = true;
        final logRepository = FakeCalorieLogRepository(
          initialEntries: <CalorieEntry>[
            _todayLunchEntry(now),
          ],
        );
        final runStateRepository = _FakeBurnWeekRunStateRepository(
          const BurnWeekRunState.initial(),
        );
        addTearDown(settingsRepository.dispose);
        addTearDown(logRepository.dispose);
        final container = _buildHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );

        await _primeHarness(container);

        final saved = await _saveOnboardingGoal(
          container,
          goalStartDate: now,
          catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
          now: now,
        );

        expect(saved, isFalse);
        expect(runStateRepository.state, const BurnWeekRunState.initial());
        expect(
          logRepository.entries.where((e) => e.name == _placeholderName),
          isEmpty,
        );
        expect((await settingsRepository.readSettings()).hasGoal, isFalse);
      },
    );

    test('aborts when unmounted after reading settings', () async {
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository();
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );
      await _primeHarness(container);
      final flow = CalorieGoalOnboardingFinishFlow(
        readSettings: () async {
          return settingsRepository.readSettings();
        },
        goalController: container.read(calorieGoalControllerProvider.notifier),
        burnWeekController: container.read(
          burnWeekRunControllerProvider.notifier,
        ),
        catchUpPlaceholderWriter: CalorieGoalOnboardingCatchUpPlaceholderWriter(
          logRepository: logRepository,
          isMounted: () => false,
        ),
        isMounted: () => false,
      );

      final saved = await flow.saveGoal(
        CalorieGoalOnboardingFinishRequest(
          profile: _profile,
          dailyGoalKcal: CalorieGoalCalculator.calculate(
            _profile,
          ).finalGoalKcal,
          goalStartDate: DateTime(2026, 4, 22, 12),
          countGoalStartDayForLearning: null,
          catchUpEstimate: null,
          placeholderName: _placeholderName,
        ),
      );

      expect(saved, isFalse);
      expect(runStateRepository.state, const BurnWeekRunState.initial());
      expect((await settingsRepository.readSettings()).hasGoal, isFalse);
    });

    test('aborts when unmounted after reading catch-up entries', () async {
      final now = DateTime(2026, 4, 22, 12);
      var mounted = true;
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository =
          FakeCalorieLogRepository(
              initialEntries: <CalorieEntry>[
                _todayLunchEntry(now),
              ],
            )
            ..onReadEntriesForDay = (day) async {
              mounted = false;
              return <CalorieEntry>[_todayLunchEntry(now)];
            };
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );
      await _primeHarness(container);
      final flow = CalorieGoalOnboardingFinishFlow(
        readSettings: settingsRepository.readSettings,
        goalController: container.read(calorieGoalControllerProvider.notifier),
        burnWeekController: container.read(
          burnWeekRunControllerProvider.notifier,
        ),
        catchUpPlaceholderWriter: CalorieGoalOnboardingCatchUpPlaceholderWriter(
          logRepository: logRepository,
          isMounted: () => mounted,
        ),
        isMounted: () => mounted,
      );

      final saved = await flow.saveGoal(
        CalorieGoalOnboardingFinishRequest(
          profile: _profile,
          dailyGoalKcal: CalorieGoalCalculator.calculate(
            _profile,
          ).finalGoalKcal,
          goalStartDate: now,
          countGoalStartDayForLearning: null,
          catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.normal,
          placeholderName: _placeholderName,
          now: now,
        ),
      );

      expect(saved, isFalse);
      expect(runStateRepository.state, const BurnWeekRunState.initial());
      expect(
        logRepository.entries.where((e) => e.name == _placeholderName),
        isEmpty,
      );
      expect((await settingsRepository.readSettings()).hasGoal, isTrue);
    });

    test('same-day low catch-up keeps placeholders optional', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _todayLunchEntry(now),
        ],
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.low,
        now: now,
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
      expect(runStateRepository.state.heartCreditKcal, 0);
      final placeholders = logRepository.entries
          .where((e) => e.name == _placeholderName)
          .toList();
      for (final p in placeholders) {
        expect(p.totalKcal, greaterThan(0));
      }
    });

    test('same-day high catch-up creates placeholder kcal', () async {
      final now = DateTime(2026, 4, 22, 12);
      final settingsRepository = FakeCalorieSettingsRepository();
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _todayLunchEntry(now),
        ],
      );
      final runStateRepository = _FakeBurnWeekRunStateRepository(
        const BurnWeekRunState.initial(),
      );
      addTearDown(settingsRepository.dispose);
      addTearDown(logRepository.dispose);
      final container = _buildHarness(
        settingsRepository: settingsRepository,
        logRepository: logRepository,
        runStateRepository: runStateRepository,
      );

      await _primeHarness(container);

      final saved = await _saveOnboardingGoal(
        container,
        goalStartDate: now,
        catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.high,
        now: now,
      );

      expect(saved, isTrue);
      expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
      expect(runStateRepository.state.heartCreditKcal, 0);
      final totalPlaceholderKcal = logRepository.entries
          .where((e) => e.name == _placeholderName)
          .fold<double>(0, (sum, e) => sum + e.totalKcal);
      expect(totalPlaceholderKcal, greaterThan(0));
      expect(totalPlaceholderKcal, lessThan(5000));
    });

    test(
      'future start resets Burn Week even with catch-up selection',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final settingsRepository = FakeCalorieSettingsRepository();
        final logRepository = FakeCalorieLogRepository(
          initialEntries: <CalorieEntry>[
            _todayLunchEntry(now),
          ],
        );
        final runStateRepository = _FakeBurnWeekRunStateRepository(
          const BurnWeekRunState(
            currentWeekStartDayKey: '2026-4-10',
            lastActiveDayKey: '2026-4-10',
            runWeekNumber: 3,
            starCount: 2,
            heartCount: 1,
            heartCreditKcal: 900,
            starBrokeThisWeek: true,
            missedTrackingThisWeek: true,
          ),
        );
        addTearDown(settingsRepository.dispose);
        addTearDown(logRepository.dispose);
        final container = _buildHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );

        await _primeHarness(container);

        final saved = await _saveOnboardingGoal(
          container,
          goalStartDate: now.add(const Duration(days: 2)),
          catchUpEstimate: CalorieGoalOnboardingCatchUpEstimate.high,
          now: now,
        );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, isNull);
        expect(runStateRepository.state.lastActiveDayKey, isNull);
        expect(runStateRepository.state.runWeekNumber, 1);
        expect(runStateRepository.state.starCount, 0);
        expect(runStateRepository.state.heartCount, burnWeekInitialHeartCount);
        expect(runStateRepository.state.heartCreditKcal, 0);
      },
    );
  });
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
