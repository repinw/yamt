import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/'
    'burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

import '../support/fake_calories_repositories.dart';

ProviderContainer _buildOnboardingSaveHarness({
  required _BlockingCalorieSettingsRepository settingsRepository,
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

Future<void> _primeOnboardingSaveHarness(ProviderContainer container) async {
  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);
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

void main() {
  group('CalorieGoalCalculatorFormState validation', () {
    test('sets empty errors for missing required fields', () {
      final state = CalorieGoalCalculatorFormState.initial(null).copyWith(
        weightKgText: '',
        heightCmText: ' ',
        ageYearsText: '',
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeekText: '',
      );

      expect(state.weightError, CalorieCalculatorFieldError.empty);
      expect(state.heightError, CalorieCalculatorFieldError.empty);
      expect(state.ageError, CalorieCalculatorFieldError.empty);
      expect(state.goalSpeedError, CalorieCalculatorFieldError.empty);
      expect(state.calculation, isNull);
      expect(state.profile, isNull);
    });

    test('sets invalid errors for malformed numeric fields', () {
      final state = CalorieGoalCalculatorFormState.initial(null).copyWith(
        weightKgText: 'abc',
        heightCmText: '-170',
        ageYearsText: '1.5',
        goalMode: CalorieGoalMode.gain,
        goalSpeedKgPerWeekText: '-0.5',
      );

      expect(state.weightError, CalorieCalculatorFieldError.invalid);
      expect(state.heightError, CalorieCalculatorFieldError.invalid);
      expect(state.ageError, CalorieCalculatorFieldError.invalid);
      expect(state.goalSpeedError, CalorieCalculatorFieldError.invalid);
      expect(state.calculation, isNull);
      expect(state.profile, isNull);
    });
  });

  group('CalorieGoalCalculatorFormState activity level mapping', () {
    test('defaults to sedentary activity at PAL 1.2', () {
      final state = CalorieGoalCalculatorFormState.initial(null);

      expect(state.activityLevelOption, CalorieActivityLevelOption.none);
      expect(state.profile?.activityLevel, 1.2);
    });

    test('maps saved PAL values to the nearest option', () {
      const initialProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 29,
        activityLevel: 1.5,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );

      final state = CalorieGoalCalculatorFormState.initial(initialProfile);

      expect(state.activityLevelOption, CalorieActivityLevelOption.medium);
      expect(state.profile?.activityLevel, 1.55);
    });
  });

  group('CalorieGoalCalculatorFormController goal mode transitions', () {
    test('switching to maintain preserves the previous goal speed', () {
      const initialProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.2,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.75,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(
        initialProfile,
      );

      container
          .read(provider.notifier)
          .updateGoalMode(CalorieGoalMode.maintain);
      final maintainState = container.read(provider);

      expect(maintainState.goalMode, CalorieGoalMode.maintain);
      expect(maintainState.goalSpeedKgPerWeekText, '0');
      expect(maintainState.lastNonMaintainGoalSpeedText, '0.75');

      container.read(provider.notifier).updateGoalMode(CalorieGoalMode.gain);
      final gainState = container.read(provider);

      expect(gainState.goalMode, CalorieGoalMode.gain);
      expect(gainState.goalSpeedKgPerWeekText, '0.75');
      expect(gainState.goalSpeedError, isNull);
    });

    test('restores fallback goal speed of 0.5 from maintain mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(null);

      expect(container.read(provider).goalMode, CalorieGoalMode.maintain);
      expect(container.read(provider).goalSpeedKgPerWeekText, '0');

      container.read(provider.notifier).updateGoalMode(CalorieGoalMode.lose);
      final loseState = container.read(provider);

      expect(loseState.goalMode, CalorieGoalMode.lose);
      expect(loseState.goalSpeedKgPerWeekText, '0.5');
      expect(loseState.lastNonMaintainGoalSpeedText, '0.5');
      expect(loseState.goalSpeedError, isNull);
    });

    test('changing activity option updates the PAL value in the profile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(null);

      container
          .read(provider.notifier)
          .updateActivityLevel(CalorieActivityLevelOption.high);

      final state = container.read(provider);

      expect(state.activityLevelOption, CalorieActivityLevelOption.high);
      expect(state.profile?.activityLevel, 1.725);
    });
  });

  group('CalorieGoalCalculatorFormController save', () {
    test(
      'save toggles isSaving and persists through goal controller',
      () async {
        final repository = _BlockingCalorieSettingsRepository(
          saveBlocker: Completer<void>(),
        );
        addTearDown(repository.dispose);
        final container = ProviderContainer(
          overrides: [
            calorieSettingsRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final provider = calorieGoalCalculatorFormControllerProvider(null);
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);
        final goalStartDate = DateTime(2026, 4, 10, 16, 30);

        await container.read(calorieGoalControllerProvider.future);

        final saveFuture = container
            .read(provider.notifier)
            .save(goalStartDate: goalStartDate);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(provider).isSaving, isTrue);
        expect(repository.saveCallCount, 1);

        repository.saveBlocker!.complete();
        final saved = await saveFuture;

        expect(saved, isTrue);
        expect(container.read(provider).isSaving, isFalse);
        final settings = await repository.readSettings();
        expect(settings.dailyKcalGoal, 2136);
        expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.maintain);
        expect(settings.goalHistory.single.changedAt, DateTime(2026, 4, 10));
      },
    );

    test(
      'save resets isSaving when goal controller persistence fails',
      () async {
        final repository = _BlockingCalorieSettingsRepository(
          saveBlocker: Completer<void>(),
          saveShouldFail: true,
        );
        addTearDown(repository.dispose);
        final container = ProviderContainer(
          overrides: [
            calorieSettingsRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final provider = calorieGoalCalculatorFormControllerProvider(null);
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);

        await container.read(calorieGoalControllerProvider.future);

        final saveFuture = container
            .read(provider.notifier)
            .save(goalStartDate: DateTime(2026, 4, 10, 18));

        expect(container.read(provider).isSaving, isTrue);

        repository.saveBlocker!.complete();
        final saved = await saveFuture;

        expect(saved, isFalse);
        expect(container.read(provider).isSaving, isFalse);
        final settings = await repository.readSettings();
        expect(settings.hasGoal, isFalse);
      },
    );

    test(
      'save still returns success after provider disposal during save',
      () async {
        final repository = _BlockingCalorieSettingsRepository(
          saveBlocker: Completer<void>(),
        );
        addTearDown(repository.dispose);
        final container = ProviderContainer(
          overrides: [
            calorieSettingsRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);

        await container.read(calorieGoalControllerProvider.future);

        final saveFuture = container
            .read(provider.notifier)
            .save(goalStartDate: DateTime(2026, 4, 10, 18));
        await Future<void>.delayed(Duration.zero);

        expect(repository.saveCallCount, 1);

        container.dispose();
        repository.saveBlocker!.complete();

        final saved = await saveFuture;

        expect(saved, isTrue);
        final settings = await repository.readSettings();
        expect(settings.dailyKcalGoal, 2136);
      },
    );

    test(
      'onboarding save allows a future goal start and resets Burn Week',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
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
        final container = _buildOnboardingSaveHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);

        await _primeOnboardingSaveHarness(container);

        final futureGoalStart = DateTime.now().add(const Duration(days: 2));
        final saved = await container
            .read(provider.notifier)
            .save(
              goalStartDate: futureGoalStart,
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
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
      },
    );

    test(
      'onboarding same-day normal catch-up seeds Burn Week credit',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
        final now = DateTime(2026, 4, 22, 12);
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
        final container = _buildOnboardingSaveHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);

        await _primeOnboardingSaveHarness(container);

        final saved = await container
            .read(provider.notifier)
            .save(
              goalStartDate: now,
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
              onboardingCatchUpEstimate:
                  CalorieGoalOnboardingCatchUpEstimate.normal,
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, closeTo(668, 0.001));
      },
    );

    test(
      'onboarding same-day low catch-up seeds the left safe-zone edge',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
        final now = DateTime(2026, 4, 22, 12);
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
        final container = _buildOnboardingSaveHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);

        await _primeOnboardingSaveHarness(container);

        final saved = await container
            .read(provider.notifier)
            .save(
              goalStartDate: now,
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
              onboardingCatchUpEstimate:
                  CalorieGoalOnboardingCatchUpEstimate.low,
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, closeTo(-400, 0.001));
      },
    );

    test(
      'onboarding same-day high catch-up seeds the right safe-zone edge',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
        final now = DateTime(2026, 4, 22, 12);
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
        final container = _buildOnboardingSaveHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);

        await _primeOnboardingSaveHarness(container);

        final saved = await container
            .read(provider.notifier)
            .save(
              goalStartDate: now,
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
              onboardingCatchUpEstimate:
                  CalorieGoalOnboardingCatchUpEstimate.high,
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, closeTo(2804, 0.001));
      },
    );

    test(
      'future onboarding start resets Burn Week even with catch-up selection',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
        final now = DateTime(2026, 4, 22, 12);
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
        final container = _buildOnboardingSaveHarness(
          settingsRepository: settingsRepository,
          logRepository: logRepository,
          runStateRepository: runStateRepository,
        );
        final provider = calorieGoalCalculatorFormControllerProvider(null);

        await _primeOnboardingSaveHarness(container);

        final saved = await container
            .read(provider.notifier)
            .save(
              goalStartDate: now.add(const Duration(days: 2)),
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
              onboardingCatchUpEstimate:
                  CalorieGoalOnboardingCatchUpEstimate.high,
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, isNull);
        expect(runStateRepository.state.lastActiveDayKey, isNull);
        expect(runStateRepository.state.runWeekNumber, 1);
        expect(runStateRepository.state.starCount, 0);
        expect(runStateRepository.state.heartCount, 3);
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

class _BlockingCalorieSettingsRepository implements CalorieSettingsRepository {
  _BlockingCalorieSettingsRepository({
    this.saveBlocker,
    this.saveShouldFail = false,
  });

  CalorieGoalSettings _settings = const CalorieGoalSettings.empty();
  final StreamController<CalorieGoalSettings> _controller =
      StreamController<CalorieGoalSettings>.broadcast();

  final Completer<void>? saveBlocker;
  final bool saveShouldFail;
  int saveCallCount = 0;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.multi((controller) {
      controller.add(_settings);
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    return _settings;
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    saveCallCount += 1;
    final blocker = saveBlocker;
    if (blocker != null) {
      await blocker.future;
    }
    if (saveShouldFail) {
      return false;
    }
    _settings = settings;
    _controller.add(settings);
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) {
    return saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 3, 29, 10),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(
      const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 3, 29, 10),
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  Future<void> dispose() {
    return _controller.close();
  }
}
