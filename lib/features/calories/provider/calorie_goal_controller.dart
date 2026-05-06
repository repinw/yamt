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

/// Result for saving a learned TDEE goal.
typedef LearnedTdeeGoalSaveResult = ({bool saved, bool goalChanged});

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
    bool allowFutureGoalStart = false,
    bool? countGoalStartDayForLearning,
  }) async {
    final calculation = CalorieGoalCalculator.calculate(profile);
    final previousSettings = await _currentSettings();
    final normalizedToday = normalizeDiaryDay(DateTime.now());
    final currentGoalEntry =
        previousSettings.activeGoalEntryForDay(DateTime.now()) ??
        previousSettings.latestGoalEntry;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    if (!allowFutureGoalStart &&
        normalizedGoalStartDate.isAfter(normalizedToday)) {
      return false;
    }
    final normalizedEffectiveDate =
        normalizedGoalStartDate.isAfter(
          normalizedToday,
        )
        ? normalizedToday
        : normalizedGoalStartDate;
    final changedAt = _goalChangeTimestamp(
      normalizedEffectiveDate: normalizedEffectiveDate,
      normalizedToday: normalizedToday,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    final expectedActivityChanged =
        currentGoalEntry?.expectedActivityKcal != null &&
        currentGoalEntry?.expectedActivityKcal !=
            calculation.expectedActivityKcal;
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate !=
            normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != calculation.finalGoalKcal ||
        _goalStartDayTrackingChanged(
          currentGoalEntry: currentGoalEntry,
          normalizedGoalStartDate: normalizedGoalStartDate,
          countGoalStartDayForLearning: countGoalStartDayForLearning,
        ) ||
        expectedActivityChanged ||
        !_sameCalculatorProfile(currentGoalEntry?.calculatorProfile, profile) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;
    if (!goalChanged) {
      return true;
    }
    final nextSettings = previousSettings.applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: calculation.finalGoalKcal,
      calculatorProfile: profile,
      expectedActivityKcal: calculation.expectedActivityKcal,
      countingStartDate: normalizedGoalStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: currentGoalEntry?.learnedTdeeSnapshot,
      replaceFutureHistory: true,
    );
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
  }) {
    final previousSettings =
        state.asData?.value ?? const CalorieGoalSettings.empty();
    if (!previousSettings.hasGoal) {
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
    final currentExpectedActivityKcal =
        currentGoalEntry?.expectedActivityKcal ??
        previousSettings.expectedActivityKcal;
    final currentSource = currentGoalEntry?.source ?? CalorieGoalSource.manual;
    final normalizedGoalStartDate = normalizeDiaryDay(goalStartDate);
    final normalizedToday = normalizeDiaryDay(DateTime.now());
    final normalizedEffectiveDate =
        normalizedGoalStartDate.isAfter(
          normalizedToday,
        )
        ? normalizedToday
        : normalizedGoalStartDate;
    final changedAt = _goalChangeTimestamp(
      normalizedEffectiveDate: normalizedEffectiveDate,
      normalizedToday: normalizedToday,
    );
    final goalStartChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate != normalizedGoalStartDate;
    if (!goalStartChanged) {
      return Future<bool>.value(true);
    }
    final nextSettings = previousSettings.applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: currentDailyKcalGoal,
      calculatorProfile: currentCalculatorProfile,
      expectedActivityKcal: currentExpectedActivityKcal,
      countingStartDate: normalizedGoalStartDate,
      source: currentSource,
      weeklyCheckInSnapshot:
          currentGoalEntry?.learnedTdeeSnapshot ??
          previousSettings.latestLearnedTdeeEntry?.learnedTdeeSnapshot,
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
    if (previous.isSkippedIntakeDay(day) == isSkipped) {
      return true;
    }
    final nextSettings = previous
        .setSkippedIntakeDay(
          day: day,
          isSkipped: isSkipped,
        )
        .invalidateWeeklyCheckInSnapshotsFromDay(
          day: day,
          invalidatedAt: DateTime.now(),
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

  /// Mark weekly check-in snapshots dirty from a changed diary day.
  Future<bool> invalidateWeeklyCheckInSnapshotsFromDay(DateTime day) async {
    final previous = await _currentSettings();
    final nextSettings = previous.invalidateWeeklyCheckInSnapshotsFromDay(
      day: day,
      invalidatedAt: DateTime.now(),
    );
    if (identical(previous, nextSettings)) {
      return true;
    }
    return _persistSettings(nextSettings);
  }

  /// Mark health activity tracking as active from a day.
  Future<bool> markActivityTrackingStarted({DateTime? startedAt}) async {
    final previous = await _currentSettings();
    final nextSettings = previous.markActivityTrackingStarted(
      startedAt ?? DateTime.now(),
    );
    if (identical(previous, nextSettings)) {
      return Future<bool>.value(true);
    }
    return _persistSettings(nextSettings);
  }

  /// Save learned tdee goal.
  Future<bool> saveLearnedTdeeGoal({
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required DateTime goalStartDate,
    bool? countGoalStartDayForLearning,
  }) async {
    final result = await saveLearnedTdeeGoalWithResult(
      goalMode: goalMode,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      goalStartDate: goalStartDate,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
    return result.saved;
  }

  /// Save learned tdee goal and report whether goal data changed.
  Future<LearnedTdeeGoalSaveResult> saveLearnedTdeeGoalWithResult({
    required CalorieGoalMode goalMode,
    required double goalSpeedKgPerWeek,
    required DateTime goalStartDate,
    bool? countGoalStartDayForLearning,
  }) async {
    final previousSettings = await _currentSettings();
    final learnedTdeeKcal = previousSettings.latestLearnedTdeeKcal;
    if (learnedTdeeKcal == null) {
      return (saved: false, goalChanged: false);
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
    final normalizedToday = normalizeDiaryDay(DateTime.now());
    final normalizedEffectiveDate =
        normalizedGoalStartDate.isAfter(
          normalizedToday,
        )
        ? normalizedToday
        : normalizedGoalStartDate;
    final changedAt = _goalChangeTimestamp(
      normalizedEffectiveDate: normalizedEffectiveDate,
      normalizedToday: normalizedToday,
      countGoalStartDayForLearning: countGoalStartDayForLearning,
    );
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
    final currentLearnedSnapshot = currentGoalEntry?.learnedTdeeSnapshot;
    final latestLearnedSnapshot =
        previousSettings.latestLearnedTdeeEntry?.learnedTdeeSnapshot;
    final nextExpectedActivityKcal =
        currentLearnedSnapshot?.averageActiveKcal ??
        latestLearnedSnapshot?.averageActiveKcal ??
        currentGoalEntry?.expectedActivityKcal ??
        previousSettings.expectedActivityKcal;
    final expectedActivityChanged =
        currentGoalEntry?.expectedActivityKcal != null &&
        currentGoalEntry?.expectedActivityKcal != nextExpectedActivityKcal;
    final goalChanged =
        currentGoalEntry?.effectiveDate != normalizedEffectiveDate ||
        currentGoalEntry?.effectiveCountingStartDate !=
            normalizedGoalStartDate ||
        currentGoalEntry?.dailyKcalGoal != nextDailyKcalGoal ||
        _goalStartDayTrackingChanged(
          currentGoalEntry: currentGoalEntry,
          normalizedGoalStartDate: normalizedGoalStartDate,
          countGoalStartDayForLearning: countGoalStartDayForLearning,
        ) ||
        expectedActivityChanged ||
        !_sameCalculatorProfile(
          currentGoalEntry?.calculatorProfile,
          nextProfile,
        ) ||
        currentGoalEntry?.source != CalorieGoalSource.calculator;
    if (!goalChanged) {
      return (saved: true, goalChanged: false);
    }
    final nextSettings = previousSettings.applyGoalChange(
      changedAt: changedAt,
      dailyKcalGoal: nextDailyKcalGoal,
      calculatorProfile: nextProfile,
      expectedActivityKcal: nextExpectedActivityKcal,
      countingStartDate: normalizedGoalStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: currentLearnedSnapshot ?? latestLearnedSnapshot,
      replaceFutureHistory: true,
    );
    final saved = await _persistSettings(nextSettings);
    return (saved: saved, goalChanged: saved);
  }

  /// Save weekly check in goal.
  Future<bool> saveWeeklyCheckInGoal({
    required DateTime completedAt,
    required double dailyKcalGoal,
    required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
  }) async {
    final previousSettings = await _currentSettings();
    final snapshotSettings = previousSettings.applyGoalChange(
      changedAt: completedAt,
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: previousSettings.calculatorProfile,
      expectedActivityKcal: weeklyCheckInSnapshot.averageActiveKcal,
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: weeklyCheckInSnapshot,
    );
    final nextSettings = CalorieGoalSettings(
      dailyKcalGoal: previousSettings.dailyKcalGoal,
      calculatorProfile: previousSettings.calculatorProfile,
      calorieMathVersion: snapshotSettings.calorieMathVersion,
      expectedActivityKcal: previousSettings.expectedActivityKcal,
      activityTrackingStartDate: snapshotSettings.activityTrackingStartDate,
      updatedAt: snapshotSettings.updatedAt,
      goalHistory: _refreshCopiedWeeklyCheckInSnapshots(
        entries: snapshotSettings.goalHistory,
        weeklyCheckInSnapshot: weeklyCheckInSnapshot,
      ),
      pendingWeeklyCheckIn: previousSettings.pendingWeeklyCheckIn,
      skippedIntakeDayKeys: snapshotSettings.skippedIntakeDayKeys,
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

List<CalorieGoalHistoryEntry> _refreshCopiedWeeklyCheckInSnapshots({
  required List<CalorieGoalHistoryEntry> entries,
  required CalorieGoalWeeklyCheckInSnapshot weeklyCheckInSnapshot,
}) {
  return List<CalorieGoalHistoryEntry>.unmodifiable([
    for (final entry in entries)
      if (!entry.isWeeklyCheckIn &&
          _isSameWeeklyCheckInWindow(
            entry.weeklyCheckInSnapshot,
            weeklyCheckInSnapshot,
          ))
        CalorieGoalHistoryEntry(
          dailyKcalGoal: entry.dailyKcalGoal,
          calculatorProfile: entry.calculatorProfile,
          expectedActivityKcal: entry.expectedActivityKcal,
          effectiveDate: entry.effectiveDate,
          changedAt: entry.changedAt,
          countingStartDate: entry.countingStartDate,
          source: entry.source,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        )
      else
        entry,
  ]);
}

bool _isSameWeeklyCheckInWindow(
  CalorieGoalWeeklyCheckInSnapshot? left,
  CalorieGoalWeeklyCheckInSnapshot right,
) {
  if (left == null) {
    return false;
  }
  return isSameDiaryDay(left.windowStartDate, right.windowStartDate) &&
      isSameDiaryDay(left.windowEndDate, right.windowEndDate);
}

DateTime _goalChangeTimestamp({
  required DateTime normalizedEffectiveDate,
  required DateTime normalizedToday,
  bool? countGoalStartDayForLearning,
}) {
  if (isSameDiaryDay(normalizedEffectiveDate, normalizedToday)) {
    if (countGoalStartDayForLearning == true) {
      return normalizedEffectiveDate;
    }
    return DateTime.now();
  }
  return normalizedEffectiveDate;
}

bool _goalStartDayTrackingChanged({
  required CalorieGoalHistoryEntry? currentGoalEntry,
  required DateTime normalizedGoalStartDate,
  required bool? countGoalStartDayForLearning,
}) {
  if (countGoalStartDayForLearning == null || currentGoalEntry == null) {
    return false;
  }
  if (!isSameDiaryDay(
    currentGoalEntry.effectiveCountingStartDate,
    normalizedGoalStartDate,
  )) {
    return false;
  }
  return _goalEntryCountsStartDay(currentGoalEntry) !=
      countGoalStartDayForLearning;
}

bool _goalEntryCountsStartDay(CalorieGoalHistoryEntry entry) {
  if (!isSameDiaryDay(entry.effectiveDate, entry.effectiveCountingStartDate)) {
    return true;
  }
  final changedAt = entry.effectiveChangedAt;
  return changedAt.hour == 0 &&
      changedAt.minute == 0 &&
      changedAt.second == 0 &&
      changedAt.millisecond == 0 &&
      changedAt.microsecond == 0;
}
