import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_state.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

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

    test('can start empty without changing default flow', () {
      final defaultState = CalorieGoalCalculatorFormState.initial(null);
      final emptyState = CalorieGoalCalculatorFormState.initial(
        null,
        useEmptyDefaults: true,
      );

      expect(defaultState.profile, isNotNull);
      expect(emptyState.sex, isNull);
      expect(emptyState.weightKgText, isEmpty);
      expect(emptyState.heightCmText, isEmpty);
      expect(emptyState.ageYearsText, isEmpty);
      expect(emptyState.profile, isNull);
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

    test('empty-defaults mode starts with empty required fields', () {
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
  });
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
