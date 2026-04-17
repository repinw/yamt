import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';

part 'calorie_goal_controller.g.dart';

const _goalControllerLogName = 'CalorieGoalController';

/// Defines calorie goal controller.
@riverpod
class CalorieGoalController extends _$CalorieGoalController {
  StreamSubscription<CalorieGoalSettings>? _settingsSubscription;

  @override
  FutureOr<CalorieGoalSettings> build() {
    ref.watch(calorieSettingsRepositoryProvider);
    ref.onDispose(_disposeSubscription);
    return _restartSubscription();
  }

  /// Set goal.
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

  /// Save calculated goal.
  Future<bool> saveCalculatedGoal(
    CalorieCalculatorProfile profile, {
    required DateTime goalStartAt,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
  }) async {
    if (eatingWindowStartMinuteOfDay != null &&
        eatingWindowEndMinuteOfDay != null &&
        !isValidEatingWindowMinutes(
          startMinuteOfDay: eatingWindowStartMinuteOfDay,
          endMinuteOfDay: eatingWindowEndMinuteOfDay,
        )) {
      return false;
    }

    final calculation = CalorieGoalCalculator.calculate(profile);
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    var nextSettings = previousSettings.applyGoalChange(
      changedAt: goalStartAt,
      dailyKcalGoal: calculation.finalGoalKcal,
      calculatorProfile: profile,
      source: CalorieGoalSource.calculator,
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
    final saved = await _persistSettings(nextSettings);
    if (!saved || !ref.mounted) {
      return saved;
    }
    await _seedCalculatorWeightIfMissing(
      day: goalStartAt,
      weightKg: profile.weightKg,
    );
    return true;
  }

  /// Shift goal start.
  Future<bool> shiftGoalStart({required DateTime goalStartAt}) {
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    if (!previousSettings.hasGoal) {
      return Future<bool>.value(false);
    }

    final anchorEntry =
        previousSettings.cycleAnchorEntryForDay(DateTime.now()) ??
        previousSettings.latestGoalEntry;
    final currentDailyKcalGoal =
        anchorEntry?.dailyKcalGoal ?? previousSettings.dailyKcalGoal;
    final currentCalculatorProfile =
        anchorEntry?.calculatorProfile ?? previousSettings.calculatorProfile;
    final currentSource = anchorEntry?.source ?? CalorieGoalSource.manual;
    final nextSettings = previousSettings.applyGoalChange(
      changedAt: goalStartAt,
      dailyKcalGoal: currentDailyKcalGoal,
      calculatorProfile: currentCalculatorProfile,
      source: currentSource,
      replaceFutureHistory: true,
    );
    return _persistSettings(nextSettings);
  }

  /// Clear goal.
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

  /// Set eating window.
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

  /// Set pending weekly check in.
  Future<bool> setPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) async {
    final previous = await _currentSettings();
    return _persistSettings(
      previous.copyWithPendingWeeklyCheckIn(pendingWeeklyCheckIn),
    );
  }

  /// Dismiss pending weekly check in.
  Future<bool> dismissPendingWeeklyCheckIn({DateTime? dismissedAt}) async {
    final previous = await _currentSettings();
    if (previous.pendingWeeklyCheckIn == null) {
      return Future<bool>.value(true);
    }
    return _persistSettings(
      previous.dismissPendingWeeklyCheckIn(dismissedAt ?? DateTime.now()),
    );
  }

  /// Set skipped intake day.
  Future<bool> setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) async {
    if (isSkipped) {
      final entries = await ref
          .read(calorieLogRepositoryProvider)
          .readEntriesForDay(day);
      if (entries.isNotEmpty) {
        return false;
      }
    }
    final previous = await _currentSettings();
    final nextSettings = previous.setSkippedIntakeDay(
      day: day,
      isSkipped: isSkipped,
    );
    return _persistSettings(nextSettings);
  }

  /// Clear skipped intake day.
  Future<bool> clearSkippedIntakeDay(DateTime day) async {
    final previous = await _currentSettings();
    if (!previous.isSkippedIntakeDay(day)) {
      return Future<bool>.value(true);
    }
    return setSkippedIntakeDay(day: day, isSkipped: false);
  }

  /// Save learned tdee goal.
  Future<bool> saveLearnedTdeeGoal({
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required DateTime goalStartAt,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
  }) async {
    final previousSettings = await _currentSettings();
    final learnedTdeeKcal = previousSettings.latestLearnedTdeeKcal;
    if (learnedTdeeKcal == null) {
      return Future<bool>.value(false);
    }
    final currentProfile =
        previousSettings.calculatorProfile ??
        const CalorieCalculatorProfile.defaults();
    final nextProfile = currentProfile.copyWith(
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalMode == CalorieGoalMode.maintain
          ? 0
          : goalSpeedKgPerWeek,
    );
    var nextSettings = previousSettings.applyGoalChange(
      changedAt: goalStartAt,
      dailyKcalGoal:
          CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
            learnedTdeeKcal: learnedTdeeKcal,
            goalSpeedKgPerWeek: goalSpeedKgPerWeek,
            isLosing: goalMode == CalorieGoalMode.lose,
            isGaining: goalMode == CalorieGoalMode.gain,
          ),
      calculatorProfile: nextProfile,
      source: CalorieGoalSource.calculator,
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

  /// Save weekly check in goal.
  Future<bool> saveWeeklyCheckInGoal({
    required DateTime completedAt,
    required double dailyKcalGoal,
    required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  }) async {
    final previousSettings = await _currentSettings();
    final nextSettings = previousSettings.applyGoalChange(
      changedAt: completedAt,
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: previousSettings.calculatorProfile,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
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
    } on Object catch (error, stackTrace) {
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

  Future<CalorieGoalSettings> _currentSettings() async {
    final currentSettings = state.asData?.value;
    if (currentSettings != null) {
      return currentSettings;
    }
    return ref.read(calorieSettingsRepositoryProvider).readSettings();
  }

  Future<void> _seedCalculatorWeightIfMissing({
    required DateTime day,
    required double weightKg,
  }) async {
    final normalizedDay = normalizeDiaryDay(day);
    final manualEntries = await ref.read(
      manualHealthWeightEntriesControllerProvider.future,
    );
    if (!ref.mounted) {
      return;
    }
    final hasManualWeight = manualEntries.any(
      (entry) => isSameDiaryDay(entry.day, normalizedDay),
    );
    if (hasManualWeight) {
      return;
    }

    final connectionStatus = await ref.read(
      healthConnectionControllerProvider.future,
    );
    if (!ref.mounted) {
      return;
    }
    if (connectionStatus.accessState == HealthDataAccessState.ready) {
      final healthSamples = await ref
          .read(healthWeightServiceProvider)
          .loadWeightSamples(
            startInclusive: normalizedDay,
            endExclusive: nextDiaryDay(normalizedDay),
          );
      if (!ref.mounted) {
        return;
      }
      final hasHealthWeight = healthSamples.any(
        (sample) => isSameDiaryDay(sample.recordedAt, normalizedDay),
      );
      if (hasHealthWeight) {
        return;
      }
    }

    await ref
        .read(manualHealthWeightEntriesControllerProvider.notifier)
        .saveEntry(day: normalizedDay, weightKg: weightKg);
  }
}
