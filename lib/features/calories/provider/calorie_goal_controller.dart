import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

part 'calorie_goal_controller.g.dart';

const _goalControllerLogName = 'CalorieGoalController';

@riverpod
class CalorieGoalController extends _$CalorieGoalController {
  StreamSubscription<CalorieGoalSettings>? _settingsSubscription;

  @override
  FutureOr<CalorieGoalSettings> build() {
    ref.watch(calorieSettingsRepositoryProvider);
    ref.onDispose(_disposeSubscription);
    return _restartSubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<bool> setGoal(double dailyKcalGoal) async {
    if (dailyKcalGoal <= 0) {
      return false;
    }

    final previous = state.asData?.value ?? const CalorieGoalSettings.empty();
    final now = DateTime.now();
    final nextSettings = previous.applyGoalChange(
      changedAt: now,
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: null,
    );
    return _persistSettings(nextSettings);
  }

  Future<bool> saveCalculatedGoal(
    CalorieCalculatorProfile profile, {
    required DateTime goalStartAt,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
  }) {
    if (eatingWindowStartMinuteOfDay != null &&
        eatingWindowEndMinuteOfDay != null &&
        !isValidEatingWindowMinutes(
          startMinuteOfDay: eatingWindowStartMinuteOfDay,
          endMinuteOfDay: eatingWindowEndMinuteOfDay,
        )) {
      return Future<bool>.value(false);
    }

    final calculation = CalorieGoalCalculator.calculate(profile);
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    final baseSettings = previousSettings.withoutLatestGoalEntry();
    var nextSettings = baseSettings.applyGoalChange(
      changedAt: goalStartAt,
      dailyKcalGoal: calculation.finalGoalKcal,
      calculatorProfile: profile,
      replaceFutureHistory: true,
    );
    if (eatingWindowStartMinuteOfDay != null &&
        eatingWindowEndMinuteOfDay != null) {
      nextSettings = nextSettings.applyEatingWindowChange(
        changedAt: goalStartAt,
        startMinuteOfDay: eatingWindowStartMinuteOfDay,
        endMinuteOfDay: eatingWindowEndMinuteOfDay,
      );
    }
    return _persistSettings(nextSettings);
  }

  Future<bool> shiftGoalStart({required DateTime goalStartAt}) {
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    if (!previousSettings.hasGoal) {
      return Future<bool>.value(false);
    }

    final currentDailyKcalGoal = previousSettings.dailyKcalGoal;
    final currentCalculatorProfile = previousSettings.calculatorProfile;
    final baseSettings = previousSettings.withoutLatestGoalEntry();
    final nextSettings = baseSettings.applyGoalChange(
      changedAt: goalStartAt,
      dailyKcalGoal: currentDailyKcalGoal,
      calculatorProfile: currentCalculatorProfile,
      replaceFutureHistory: true,
    );
    return _persistSettings(nextSettings);
  }

  Future<bool> clearGoal() async {
    final previous = state.asData?.value ?? const CalorieGoalSettings.empty();
    final now = DateTime.now();
    return _persistSettings(
      previous.applyGoalChange(
        changedAt: now,
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  Future<bool> setEatingWindow({
    required int startMinuteOfDay,
    required int endMinuteOfDay,
  }) async {
    if (!isValidEatingWindowMinutes(
      startMinuteOfDay: startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay,
    )) {
      return false;
    }

    final previous = state.asData?.value ?? const CalorieGoalSettings.empty();
    final now = DateTime.now();
    final nextSettings = previous.applyEatingWindowChange(
      changedAt: now,
      startMinuteOfDay: startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay,
    );
    return _persistSettings(nextSettings);
  }

  Future<CalorieGoalSettings> _restartSubscription() {
    final initial = Completer<CalorieGoalSettings>();
    final repository = ref.read(calorieSettingsRepositoryProvider);
    _disposeSubscription();

    _settingsSubscription = repository.watchSettings().listen(
      (settings) {
        if (!initial.isCompleted) {
          initial.complete(settings);
          return;
        }
        _onRealtimeSettings(settings);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initial.isCompleted) {
          initial.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initial.future;
  }

  void _disposeSubscription() {
    final currentSubscription = _settingsSubscription;
    _settingsSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
  }

  void _onRealtimeSettings(CalorieGoalSettings settings) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(settings);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }

  Future<bool> _persistSettings(CalorieGoalSettings nextSettings) async {
    final previous = state.asData?.value ?? const CalorieGoalSettings.empty();
    if (ref.mounted) {
      state = AsyncData(nextSettings);
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    try {
      final saved = await repository.saveSettings(nextSettings);
      if (saved && nextSettings.hasGoal) {
        await markCalorieGoalOnboardingCompleted(ref);
      }
      if (!saved && ref.mounted) {
        state = AsyncData(previous);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to persist calorie goal settings.',
        name: _goalControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = AsyncData(previous);
      }
      return false;
    }
  }
}
