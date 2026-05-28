import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_health_loader.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_input_hash.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_intake_resolver.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_weight_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_window_resolver.dart';
import 'package:yamt/features/calories/application/'
    'calorie_weekly_learning_seed_resolver.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'manual_health_weight_entries_controller.dart';

const _weeklyCheckInProviderLogName = 'CalorieWeeklyCheckInProvider';

/// Build calorie weekly check-in data.
Future<CalorieWeeklyCheckInData> buildCalorieWeeklyCheckInData(
  Ref ref,
) async {
  // Trigger recompute when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);

  final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
  final balanceNow = ref.watch(calorieBalanceNowProvider);
  final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
  final manualEntriesFuture = ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  final calorieLogRepository = ref.watch(calorieLogRepositoryProvider);
  final healthStatusFuture = ref.watch(
    healthConnectionControllerProvider.future,
  );
  final healthWeightService = ref.watch(healthWeightServiceProvider);
  final diaryHealthService = ref.watch(diaryHealthServiceProvider);

  final settings = await settingsFuture;
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final today = normalizeDiaryDay(balanceNow());
  final pendingWeeklyCheckIn = resolvePendingCalorieWeeklyCheckIn(
    settings: settings,
    today: today,
  );
  final freshness = resolveCalorieLearnedTdeeFreshness(
    settings: settings,
    today: today,
  );
  final shouldLoadPendingWindow =
      pendingWeeklyCheckIn != null && !pendingWeeklyCheckIn.isDismissed;
  final shouldRefreshStaleCache =
      pendingWeeklyCheckIn == null &&
      (freshness == CalorieLearnedTdeeFreshness.stale ||
          freshness == CalorieLearnedTdeeFreshness.urgent);
  final cacheWeeklyCheckIn = shouldLoadPendingWindow
      ? pendingWeeklyCheckIn
      : shouldRefreshStaleCache
      ? resolveLatestCompletedCalorieWeeklyCheckIn(
          settings: settings,
          today: today,
        )
      : null;

  if (cacheWeeklyCheckIn == null) {
    return _emptyWeeklyCheckInData(
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      freshness: freshness,
      latestLearnedTdeeAt: settings.latestLearnedTdeeChangedAt,
    );
  }

  final runState = await runStateFuture;
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final heartDayKeys = runState.heartDayKeys.toSet();
  final dayData = await _loadWindowDayData(
    ref: ref,
    calorieLogRepository: calorieLogRepository,
    manualEntriesFuture: manualEntriesFuture,
    healthStatusFuture: healthStatusFuture,
    healthWeightService: healthWeightService,
    diaryHealthService: diaryHealthService,
    settings: settings,
    pendingWeeklyCheckIn: cacheWeeklyCheckIn,
    today: today,
    heartDayKeys: heartDayKeys,
  );

  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    cacheWeeklyCheckIn: cacheWeeklyCheckIn,
    shouldAutoOpen: pendingWeeklyCheckIn?.isDismissed == false,
    days: dayData.days,
    calculation: dayData.calculation,
    blockedReason: dayData.blockedReason,
    missingIntakeDays: dayData.missingIntakeDays,
    missingWeightDays: dayData.missingWeightDays,
    freshness: freshness,
    latestLearnedTdeeAt: settings.latestLearnedTdeeChangedAt,
    lowConfidence: dayData.lowConfidence,
    usesHealthActivity: dayData.usesHealthActivity,
    inputHash: dayData.inputHash,
  );
}

CalorieWeeklyCheckInData _emptyWeeklyCheckInData({
  required PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  required CalorieLearnedTdeeFreshness freshness,
  required DateTime? latestLearnedTdeeAt,
}) {
  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: false,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: freshness,
    latestLearnedTdeeAt: latestLearnedTdeeAt,
    lowConfidence: false,
  );
}

Future<CalorieWeeklyCheckInDayData> _loadWindowDayData({
  required Ref ref,
  required CalorieLogRepositoryContract calorieLogRepository,
  required Future<List<ManualHealthWeightEntry>> manualEntriesFuture,
  required Future<HealthConnectionStatus> healthStatusFuture,
  required HealthWeightService healthWeightService,
  required DiaryHealthService diaryHealthService,
  required CalorieGoalSettings settings,
  required PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  required DateTime today,
  required Set<String> heartDayKeys,
}) async {
  final dates = resolveCalorieWeeklyCheckInWindowDates(
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
  );
  final calorieEntriesByDay = await readCheckInCalorieEntriesByDay(
    calorieLogRepository: calorieLogRepository,
    startInclusive: dates.learningStartDate,
    endExclusive: nextDiaryDay(pendingWeeklyCheckIn.windowEndDate),
  );
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final manualEntries = await manualEntriesFuture;
  if (!ref.mounted) {
    throw StateError('Calorie weekly check-in disposed.');
  }
  final healthData = await loadCalorieWeeklyCheckInHealthData(
    healthStatusFuture: healthStatusFuture,
    healthWeightService: healthWeightService,
    diaryHealthService: diaryHealthService,
    settings: settings,
    dates: dates,
    today: today,
    isMounted: () => ref.mounted,
  );
  final manualWeightByDayMap = manualWeightByDay(manualEntries);
  final weightData = mergeWeeklyCheckInWeights(
    dates: dates,
    anchorEntry: dates.anchorEntry,
    manualWeightByDay: manualWeightByDayMap,
    representativeWeightByDay: healthData.representativeWeightByDay,
  );
  final windowIntakeData = resolveWeeklyWindowIntakeData(
    days: dates.windowDays,
    calorieEntriesByDay: calorieEntriesByDay,
    settings: settings,
    activeKcalByDay: healthData.activeKcalByDay,
    weightByDay: weightData.weightByDay,
    heartDayKeys: heartDayKeys,
  );
  if (windowIntakeData.blockedReason != null) {
    return CalorieWeeklyCheckInDayData(
      days: windowIntakeData.days,
      calculation: null,
      blockedReason: windowIntakeData.blockedReason,
      missingIntakeDays: windowIntakeData.missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: false,
      usesHealthActivity: healthData.usesHealthActivity,
      inputHash: null,
    );
  }

  final learningIntakeData = resolveWeeklyLearningIntakeData(
    days: dates.learningDays,
    calorieEntriesByDay: calorieEntriesByDay,
    settings: settings,
    heartDayKeys: heartDayKeys,
  );
  if (learningIntakeData.blockedReason != null) {
    return CalorieWeeklyCheckInDayData(
      days: windowIntakeData.days,
      calculation: null,
      blockedReason: learningIntakeData.blockedReason,
      missingIntakeDays: learningIntakeData.missingIntakeDays,
      missingWeightDays: const <DateTime>[],
      lowConfidence: false,
      usesHealthActivity: healthData.usesHealthActivity,
      inputHash: null,
    );
  }

  final weightBlockedData = validateWeeklyCheckInWeightData(
    dates: dates,
    weightData: weightData,
    windowDays: windowIntakeData.days,
    missingIntakeDays: windowIntakeData.missingIntakeDays,
    usesHealthActivity: healthData.usesHealthActivity,
  );
  if (weightBlockedData != null) {
    return weightBlockedData;
  }

  final previousLearningSeed = resolveCascadedPreviousLearningSeedForWindow(
    settings: settings,
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    dates: dates,
    calorieEntriesByDay: calorieEntriesByDay,
    manualWeightByDay: manualWeightByDayMap,
    representativeWeightByDay: healthData.representativeWeightByDay,
    activeKcalByDay: healthData.activeKcalByDay,
    heartDayKeys: heartDayKeys,
  );
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: pendingWeeklyCheckIn.windowEndDate,
  );
  final calculation = CalorieWeeklyCheckInCalculator.calculate(
    previousGoalKcal: previousLearningSeed.previousGoalKcal,
    previousLearnedTdeeKcal: previousLearningSeed.previousLearnedTdeeKcal,
    goalMode: calculatorProfile?.goalMode ?? CalorieGoalMode.maintain,
    goalSpeedKgPerWeek: calculatorProfile?.goalSpeedKgPerWeek ?? 0,
    intakeKcalByDay: learningIntakeData.intakeKcalByDay,
    lastWeekActiveKcalByDay: windowIntakeData.days
        .where((day) => !day.isHeartDay)
        .map((day) => day.activeKcal)
        .toList(growable: false),
    learningActiveKcalByDay: activityKcalByDay(
      days: dates.learningDays,
      activeKcalByDay: healthData.activeKcalByDay,
    ),
    todayActiveKcal: healthData.todayActiveKcal,
    weightPoints: weightData.weightPoints,
  );
  final inputHash = weeklyCheckInInputHash(
    weeklyCheckIn: pendingWeeklyCheckIn,
    dates: dates,
    previousLearningSeed: previousLearningSeed,
    calorieEntriesByDay: calorieEntriesByDay,
    settings: settings,
    weightData: weightData,
    activeKcalByDay: healthData.activeKcalByDay,
    heartDayKeys: heartDayKeys,
  );
  if (!kReleaseMode) {
    final daysLabel = windowIntakeData.days
        .map((day) {
          return '${diaryDayKey(day.day)}'
              ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
              ',resolved='
              '${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
              ',active=${day.activeKcal}'
              ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
              ',skipped=${day.isSkippedIntakeDay}';
        })
        .join(' | ');
    final message =
        'WEEKLY_TDEE_WINDOW_DEBUG '
        'window=${diaryDayKey(pendingWeeklyCheckIn.windowStartDate)}'
        '..${diaryDayKey(pendingWeeklyCheckIn.windowEndDate)} '
        'learningWindow=${diaryDayKey(dates.learningStartDate)}'
        '..${diaryDayKey(pendingWeeklyCheckIn.windowEndDate)} '
        'today=${diaryDayKey(today)} '
        'previousGoalKcal='
        '${previousLearningSeed.previousGoalKcal.toStringAsFixed(2)} '
        'days=[$daysLabel]';
    log(message, name: _weeklyCheckInProviderLogName);
  }

  return CalorieWeeklyCheckInDayData(
    days: windowIntakeData.days,
    calculation: calculation,
    blockedReason: null,
    missingIntakeDays: windowIntakeData.missingIntakeDays,
    missingWeightDays: const <DateTime>[],
    lowConfidence: weightData.weightPoints.length <= 2,
    usesHealthActivity: healthData.usesHealthActivity,
    inputHash: inputHash,
  );
}
