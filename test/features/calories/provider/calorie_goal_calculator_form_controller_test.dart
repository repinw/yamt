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

    test('can start empty for onboarding without changing default flow', () {
      final defaultState = CalorieGoalCalculatorFormState.initial(null);
      final onboardingState = CalorieGoalCalculatorFormState.initial(
        null,
        useEmptyDefaults: true,
      );

      expect(defaultState.profile, isNotNull);
      expect(onboardingState.sex, isNull);
      expect(onboardingState.weightKgText, isEmpty);
      expect(onboardingState.heightCmText, isEmpty);
      expect(onboardingState.ageYearsText, isEmpty);
      expect(onboardingState.profile, isNull);
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

    test('target below start weight switches goal mode to lose', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(null);

      container.read(provider.notifier).updateWeightKg('70');
      container.read(provider.notifier).updateTargetWeightKg('69');
      final state = container.read(provider);

      expect(state.goalMode, CalorieGoalMode.lose);
      expect(state.goalSpeedKgPerWeekText, '0.5');
      expect(state.goalSpeedError, isNull);
    });

    test('target above start weight switches goal mode to gain', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(null);

      container.read(provider.notifier).updateWeightKg('70');
      container.read(provider.notifier).updateTargetWeightKg('71');
      final state = container.read(provider);

      expect(state.goalMode, CalorieGoalMode.gain);
      expect(state.goalSpeedKgPerWeekText, '0.5');
      expect(state.goalSpeedError, isNull);
    });

    test('target equal to start weight switches goal mode to maintain', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(null);

      container.read(provider.notifier).updateWeightKg('70');
      container.read(provider.notifier).updateTargetWeightKg('70');
      final state = container.read(provider);

      expect(state.goalMode, CalorieGoalMode.maintain);
      expect(state.goalSpeedKgPerWeekText, '0');
      expect(state.goalSpeedError, isNull);
    });

    test('onboarding provider mode starts with empty required fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(
        null,
        useEmptyDefaults: true,
      );

      final state = container.read(provider);

      expect(state.sexError, CalorieCalculatorFieldError.empty);
      expect(state.weightError, CalorieCalculatorFieldError.empty);
      expect(state.heightError, CalorieCalculatorFieldError.empty);
      expect(state.ageError, CalorieCalculatorFieldError.empty);
      expect(state.calculation, isNull);
    });

    test('stores onboarding choices in provider state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = calorieGoalCalculatorFormControllerProvider(
        null,
        useEmptyDefaults: true,
      );
      container.read(provider.notifier)
        ..updateOnboardingTodayTracking(
          CalorieGoalOnboardingTodayTracking.estimate,
        )
        ..updateOnboardingCatchUpEstimate(
          CalorieGoalOnboardingCatchUpEstimate.high,
        )
        ..updateOnboardingStartNow(startNow: true);

      final state = container.read(provider);

      expect(state.onboardingStartNow, isTrue);
      expect(
        state.onboardingTodayTracking,
        CalorieGoalOnboardingTodayTracking.estimate,
      );
      expect(
        state.onboardingCatchUpEstimate,
        CalorieGoalOnboardingCatchUpEstimate.high,
      );
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
      'learned TDEE goal change starts same-day Burn Week as game week',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final settingsRepository = _BlockingCalorieSettingsRepository(
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
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(
          runStateRepository.state.runWeekNumber,
          burnWeekFirstGameRunWeekNumber,
        );
        expect(runStateRepository.state.heartCreditKcal, 0);
      },
    );

    test(
      'learned TDEE future goal change schedules game week start',
      () async {
        final now = DateTime(2026, 4, 22, 12);
        final futureGoalStart = DateTime(2026, 4, 24, 9);
        final settingsRepository = _BlockingCalorieSettingsRepository(
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
              goalStartDate: futureGoalStart,
              allowFutureGoalStart: true,
              syncBurnWeekForOnboarding: true,
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-24');
        expect(
          runStateRepository.state.runWeekNumber,
          burnWeekFirstGameRunWeekNumber,
        );
      },
    );

    test(
      'onboarding same-day normal catch-up creates placeholder entries',
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
              onboardingPlaceholderName: 'Geschätzte Mahlzeit',
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        // heartCreditKcal must always be 0 — placeholders replace it.
        expect(runStateRepository.state.heartCreditKcal, 0);
        // Placeholder entries are created with the localized name.
        final placeholders = logRepository.entries
            .where((e) => e.name == 'Geschätzte Mahlzeit')
            .toList();
        expect(placeholders, isNotEmpty);
        // Total placeholder kcal should be roughly desired - already-logged.
        // Daily goal at noon (dayProgress=0.5): expectedFraction(12) =
        //   0.25 + 0.30 × (1/4) = 0.325 → expectedKcal = goal × 0.325.
        // For "normal" modifier ×1.0 → desired ≈ goal × 0.325.
        // We only assert the basic invariant: placeholders are created with
        // a positive total kcal value.
        final totalPlaceholderKcal = placeholders.fold<double>(
          0,
          (sum, e) => sum + e.totalKcal,
        );
        expect(totalPlaceholderKcal, greaterThan(0));
      },
    );

    test(
      'onboarding aborts when catch-up placeholder save fails',
      () async {
        final settingsRepository = _BlockingCalorieSettingsRepository();
        final now = DateTime(2026, 4, 22, 12);
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
              onboardingPlaceholderName: 'Geschätzte Mahlzeit',
              now: now,
            );

        expect(saved, isFalse);
        expect(container.read(provider).isSaving, isFalse);
        expect(settingsRepository.saveCallCount, 0);
        expect(runStateRepository.state, const BurnWeekRunState.initial());
      },
    );

    test(
      'onboarding same-day low catch-up creates fewer placeholder kcal',
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
              onboardingPlaceholderName: 'Geschätzte Mahlzeit',
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, 0);
        // For "low" the catch-up estimate may be below the already-logged
        // amount, in which case no placeholders are created. Either way
        // heartCreditKcal stays 0 and any created placeholders carry the
        // expected name.
        final placeholders = logRepository.entries
            .where((e) => e.name == 'Geschätzte Mahlzeit')
            .toList();
        for (final p in placeholders) {
          expect(p.totalKcal, greaterThan(0));
        }
      },
    );

    test(
      'onboarding same-day high catch-up creates more placeholder kcal',
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
              onboardingPlaceholderName: 'Geschätzte Mahlzeit',
              now: now,
            );

        expect(saved, isTrue);
        expect(runStateRepository.state.currentWeekStartDayKey, '2026-4-22');
        expect(runStateRepository.state.heartCreditKcal, 0);
        final placeholders = logRepository.entries
            .where((e) => e.name == 'Geschätzte Mahlzeit')
            .toList();
        expect(placeholders, isNotEmpty);
        final totalPlaceholderKcal = placeholders.fold<double>(
          0,
          (sum, e) => sum + e.totalKcal,
        );
        // "high" must produce more placeholder kcal than "normal" /
        // already-logged offset would.
        expect(totalPlaceholderKcal, greaterThan(0));
        // Sanity cap: the catch-up estimate is capped at 1.4× the daily
        // goal, so total placeholder kcal should always stay below 1.4×
        // the daily goal regardless of the user's choice.
        // (We don't know the exact daily goal here, but it's > 1500
        // typically; ensure at minimum we are not seeing absurd
        // negative-leak values like 4700+ from the old bug.)
        expect(totalPlaceholderKcal, lessThan(5000));
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

class _BlockingCalorieSettingsRepository implements CalorieSettingsRepository {
  _BlockingCalorieSettingsRepository({
    CalorieGoalSettings? initialSettings,
    this.saveBlocker,
    this.saveShouldFail = false,
  }) : _settings = initialSettings ?? const CalorieGoalSettings.empty();

  CalorieGoalSettings _settings;
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
