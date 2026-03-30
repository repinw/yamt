import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_calculator_form_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

void main() {
  group('CalorieGoalCalculatorFormState validation', () {
    test('sets empty errors for missing required fields', () {
      final state = CalorieGoalCalculatorFormState.initial(null).copyWith(
        weightKgText: '',
        heightCmText: ' ',
        ageYearsText: '',
        activityLevelText: '',
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeekText: '',
      );

      expect(state.weightError, CalorieCalculatorFieldError.empty);
      expect(state.heightError, CalorieCalculatorFieldError.empty);
      expect(state.ageError, CalorieCalculatorFieldError.empty);
      expect(state.activityLevelError, CalorieCalculatorFieldError.empty);
      expect(state.goalSpeedError, CalorieCalculatorFieldError.empty);
      expect(state.calculation, isNull);
      expect(state.profile, isNull);
    });

    test('sets invalid errors for malformed numeric fields', () {
      final state = CalorieGoalCalculatorFormState.initial(null).copyWith(
        weightKgText: 'abc',
        heightCmText: '-170',
        ageYearsText: '1.5',
        activityLevelText: '0',
        goalMode: CalorieGoalMode.gain,
        goalSpeedKgPerWeekText: '-0.5',
      );

      expect(state.weightError, CalorieCalculatorFieldError.invalid);
      expect(state.heightError, CalorieCalculatorFieldError.invalid);
      expect(state.ageError, CalorieCalculatorFieldError.invalid);
      expect(state.activityLevelError, CalorieCalculatorFieldError.invalid);
      expect(state.goalSpeedError, CalorieCalculatorFieldError.invalid);
      expect(state.calculation, isNull);
      expect(state.profile, isNull);
    });
  });

  group('CalorieGoalCalculatorFormController goal mode transitions', () {
    test('switching to maintain preserves the previous goal speed', () {
      const initialProfile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        activityLevel: 1.4,
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

        await container.read(calorieGoalControllerProvider.future);

        final saveFuture = container.read(provider.notifier).save();

        expect(container.read(provider).isSaving, isTrue);
        expect(repository.saveCallCount, 1);

        repository.saveBlocker!.complete();
        final saved = await saveFuture;

        expect(saved, isTrue);
        expect(container.read(provider).isSaving, isFalse);
        final settings = await repository.readSettings();
        expect(settings.dailyKcalGoal, 2492);
        expect(settings.calculatorProfile?.goalMode, CalorieGoalMode.maintain);
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

        await container.read(calorieGoalControllerProvider.future);

        final saveFuture = container.read(provider.notifier).save();

        expect(container.read(provider).isSaving, isTrue);

        repository.saveBlocker!.complete();
        final saved = await saveFuture;

        expect(saved, isFalse);
        expect(container.read(provider).isSaving, isFalse);
        final settings = await repository.readSettings();
        expect(settings.hasGoal, isFalse);
      },
    );
  });
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
  var saveCallCount = 0;

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
