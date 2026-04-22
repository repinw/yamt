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
  StreamSubscription<CalorieGoalSettings>?
  _settingsSubscription; // ignore: cancel_subscriptions, because: Riverpod disposes it via ref.onDispose(_disposeSubscription).

  @override
  FutureOr<CalorieGoalSettings> build() {
    ref
      ..watch(calorieSettingsRepositoryProvider)
      ..onDispose(_disposeSubscription);
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
    required DateTime goalStartDate,
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
    final previousSettings = await _currentSettings();
    final currentGoalEntry =
        previousSettings.activeGoalEntryForDay(DateTime.now()) ??
        previousSettings.latestGoalEntry;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    if (normalizedGoalStartDate.isAfter(normalizeDiaryDay(DateTime.now()))) {
      return false;
    }
    final updatesEatingWindow =
        eatingWindowStartMinuteOfDay != null &&
        eatingWindowEndMinuteOfDay != null;
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != calculation.finalGoalKcal ||
        !_sameCalculatorProfile(currentGoalEntry?.calculatorProfile, profile) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;
    final eatingWindowChanged =
        updatesEatingWindow &&
        (previousSettings.normalizedEatingWindowStartMinuteOfDay !=
                eatingWindowStartMinuteOfDay ||
            previousSettings.normalizedEatingWindowEndMinuteOfDay !=
                eatingWindowEndMinuteOfDay);
    if (!goalChanged) {
      if (!eatingWindowChanged) {
        return true;
      }
      return setEatingWindow(
        startMinuteOfDay: eatingWindowStartMinuteOfDay,
        endMinuteOfDay: eatingWindowEndMinuteOfDay,
      );
    }
    var nextSettings = previousSettings.applyGoalChange(
      changedAt: normalizedGoalStartDate,
      dailyKcalGoal: calculation.finalGoalKcal,
      calculatorProfile: profile,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: currentGoalEntry?.weeklyCheckInSnapshot,
      replaceFutureHistory: true,
    );
    if (updatesEatingWindow) {
      nextSettings = nextSettings.applyEatingWindowChange(
        changedAt: normalizedGoalStartDate,
        startMinuteOfDay: eatingWindowStartMinuteOfDay,
        endMinuteOfDay: eatingWindowEndMinuteOfDay,
      );
    }
    final saved = await _persistSettings(nextSettings);
    if (!saved || !ref.mounted) {
      return saved;
    }
    await _seedCalculatorWeightIfMissing(
      day: normalizedGoalStartDate,
      weightKg: profile.weightKg,
    );
    return true;
  }

  /// Shift goal start.
  Future<bool> shiftGoalStart({
    required DateTime goalStartDate,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
  }) {
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    if (!previousSettings.hasGoal) {
      return Future<bool>.value(false);
    }
    final updatesEatingWindow =
        eatingWindowStartMinuteOfDay != null ||
        eatingWindowEndMinuteOfDay != null;
    if (updatesEatingWindow &&
        (eatingWindowStartMinuteOfDay == null ||
            eatingWindowEndMinuteOfDay == null ||
            !isValidEatingWindowMinutes(
              startMinuteOfDay: eatingWindowStartMinuteOfDay,
              endMinuteOfDay: eatingWindowEndMinuteOfDay,
            ))) {
      return Future<bool>.value(false);
    }

    final currentGoalEntry =
        previousSettings.activeGoalEntryForDay(DateTime.now()) ??
        previousSettings.latestGoalEntry;
    final currentDailyKcalGoal =
        currentGoalEntry?.dailyKcalGoal ?? previousSettings.dailyKcalGoal;
    final currentCalculatorProfile =
        currentGoalEntry?.calculatorProfile ??
        previousSettings.calculatorProfile;
    final currentSource = currentGoalEntry?.source ?? CalorieGoalSource.manual;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    if (normalizedGoalStartDate.isAfter(normalizeDiaryDay(DateTime.now()))) {
      return Future<bool>.value(false);
    }
    final goalStartChanged =
        currentGoalEntry?.effectiveDate != normalizedGoalStartDate;
    final eatingWindowChanged =
        updatesEatingWindow &&
        (previousSettings.normalizedEatingWindowStartMinuteOfDay !=
                eatingWindowStartMinuteOfDay ||
            previousSettings.normalizedEatingWindowEndMinuteOfDay !=
                eatingWindowEndMinuteOfDay);
    if (!goalStartChanged) {
      if (!eatingWindowChanged) {
        return Future<bool>.value(true);
      }
      return setEatingWindow(
        startMinuteOfDay: eatingWindowStartMinuteOfDay!,
        endMinuteOfDay: eatingWindowEndMinuteOfDay!,
      );
    }
    var nextSettings = previousSettings.applyGoalChange(
      changedAt: normalizedGoalStartDate,
      dailyKcalGoal: currentDailyKcalGoal,
      calculatorProfile: currentCalculatorProfile,
      source: currentSource,
      weeklyCheckInSnapshot: currentGoalEntry?.weeklyCheckInSnapshot,
      replaceFutureHistory: true,
    );
    if (updatesEatingWindow) {
      nextSettings = nextSettings.applyEatingWindowChange(
        changedAt: normalizedGoalStartDate,
        startMinuteOfDay: eatingWindowStartMinuteOfDay!,
        endMinuteOfDay: eatingWindowEndMinuteOfDay!,
      );
    }
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
    required DateTime goalStartDate,
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
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    if (normalizedGoalStartDate.isAfter(normalizeDiaryDay(DateTime.now()))) {
      return Future<bool>.value(false);
    }
    final currentGoalEntry =
        previousSettings.activeGoalEntryForDay(DateTime.now()) ??
        previousSettings.latestGoalEntry;
    final nextDailyKcalGoal =
        CalorieWeeklyCheckInCalculator.calculateGoalFromLearnedTdee(
          learnedTdeeKcal: learnedTdeeKcal,
          goalSpeedKgPerWeek: goalSpeedKgPerWeek,
          isLosing: goalMode == CalorieGoalMode.lose,
          isGaining: goalMode == CalorieGoalMode.gain,
        );
    final updatesEatingWindow =
        eatingWindowStartMinuteOfDay != null &&
        eatingWindowEndMinuteOfDay != null;
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != nextDailyKcalGoal ||
        !_sameCalculatorProfile(
          currentGoalEntry?.calculatorProfile,
          nextProfile,
        ) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;
    final eatingWindowChanged =
        updatesEatingWindow &&
        (previousSettings.normalizedEatingWindowStartMinuteOfDay !=
                eatingWindowStartMinuteOfDay ||
            previousSettings.normalizedEatingWindowEndMinuteOfDay !=
                eatingWindowEndMinuteOfDay);
    if (!goalChanged) {
      if (!eatingWindowChanged) {
        return Future<bool>.value(true);
      }
      return setEatingWindow(
        startMinuteOfDay: eatingWindowStartMinuteOfDay,
        endMinuteOfDay: eatingWindowEndMinuteOfDay,
      );
    }
    var nextSettings = previousSettings.applyGoalChange(
      changedAt: normalizedGoalStartDate,
      dailyKcalGoal: nextDailyKcalGoal,
      calculatorProfile: nextProfile,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot:
          currentGoalEntry?.weeklyCheckInSnapshot ??
          previousSettings.latestLearnedTdeeEntry?.weeklyCheckInSnapshot,
      replaceFutureHistory: true,
    );
    if (updatesEatingWindow) {
      nextSettings = nextSettings.applyEatingWindowChange(
        changedAt: normalizedGoalStartDate,
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

bool _sameCalculatorProfile(
  CalorieCalculatorProfile? left,
  CalorieCalculatorProfile? right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return left == right;
  }
  return left.sex == right.sex &&
      left.weightKg == right.weightKg &&
      left.heightCm == right.heightCm &&
      left.ageYears == right.ageYears &&
      left.activityLevel == right.activityLevel &&
      left.goalMode == right.goalMode &&
      left.goalSpeedKgPerWeek == right.goalSpeedKgPerWeek;
}
