import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/application/'
    'daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_budget_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_balance_now_provider.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/provider/daily_learned_tdee_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';

part 'calorie_resolved_goal_provider.g.dart';

const _resolvedGoalLogName = 'ResolvedCalorieGoalProvider';
const _dayKeyListEquality = ListEquality<String>();
const _activityTrackingBackfillDayCount = 30;

/// Defines resolved calorie goal data.
class ResolvedCalorieGoalData {
  /// The resolved calorie goal data.
  const ResolvedCalorieGoalData({
    required this.day,
    required this.storedGoalKcal,
    required this.goalKcal,
    required this.activityDeltaKcal,
    required this.lastWeekAverageActiveKcal,
    required this.todayActiveKcal,
    required this.usedLearnedTdee,
    required this.usesPreLearningActivityBonus,
    required this.wasClampedToMinimum,
    this.correctedActivityKcal = 0,
    this.activityCapKcal = 0,
    this.wasActivityCapped = false,
    this.activityComparisonKcal = 0,
    this.expectedActivityKcal = 0,
    this.isActivityTrackingActive = false,
  });

  /// The day.
  final DateTime day;

  /// The stored goal kcal.
  final double storedGoalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The activity delta kcal.
  final double activityDeltaKcal;

  /// The signed activity comparison against the learned baseline.
  final double activityComparisonKcal;

  /// Activity kcal after import correction.
  final double correctedActivityKcal;

  /// Activity kcal cap for this day.
  final double activityCapKcal;

  /// Whether the activity cap lowered the credited kcal.
  final bool wasActivityCapped;

  /// Expected daily activity kcal baseline.
  final double expectedActivityKcal;

  /// Whether health/activity tracking is active for this day.
  final bool isActivityTrackingActive;

  /// The last week average active kcal.
  final double lastWeekAverageActiveKcal;

  /// The selected day active kcal.
  final int todayActiveKcal;

  /// The used learned tdee.
  final bool usedLearnedTdee;

  /// Whether using a pre-learning activity bonus.
  final bool usesPreLearningActivityBonus;

  /// Whether clamped to minimum.
  final bool wasClampedToMinimum;
}

/// Stable request key for resolving goals for multiple days.
@immutable
class ResolvedCalorieGoalDaysRequest {
  /// Creates request from diary days.
  factory ResolvedCalorieGoalDaysRequest.fromDays(
    Iterable<DateTime> days,
  ) {
    final daysByKey = <String, DateTime>{};
    for (final day in days) {
      final normalizedDay = normalizeDiaryDay(day);
      daysByKey[diaryDayKey(normalizedDay)] = normalizedDay;
    }
    return ResolvedCalorieGoalDaysRequest._(
      List<DateTime>.unmodifiable(daysByKey.values),
      List<String>.unmodifiable(daysByKey.keys),
    );
  }

  const ResolvedCalorieGoalDaysRequest._(this.days, this._dayKeys);

  /// Normalized days to resolve.
  final List<DateTime> days;

  final List<String> _dayKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResolvedCalorieGoalDaysRequest &&
        _dayKeyListEquality.equals(_dayKeys, other._dayKeys);
  }

  @override
  int get hashCode => _dayKeyListEquality.hash(_dayKeys);
}

/// Resolved calorie goals keyed by diary day key.
@riverpod
Future<Map<String, ResolvedCalorieGoalData>> resolvedCalorieGoalsForDays(
  Ref ref,
  ResolvedCalorieGoalDaysRequest request,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    // Trigger recompute when calorie logs mutate through overview revision.
    ref.watch(calorieOverviewRevisionProvider);
    final referenceNow = ref.watch(calorieBalanceNowProvider)();
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
    final diaryHealthService = ref.watch(diaryHealthServiceProvider);
    final now = normalizeDiaryDay(referenceNow);
    final healthStatus = await healthStatusFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    var settings = await settingsFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    if (healthStatus.accessState == HealthDataAccessState.ready &&
        settings.activityTrackingStartDate == null) {
      settings = settings.markActivityTrackingStarted(
        _activityTrackingStartDate(referenceNow),
      );
    }

    final storedGoalsByDay = <String, double>{};
    final learnedRequests = <DailyLearnedTdeeGoalDayRequest>[];
    for (final day in request.days) {
      final normalizedDay = normalizeDiaryDay(day);
      final storedGoalKcal = settings.goalKcalForDay(normalizedDay);
      storedGoalsByDay[diaryDayKey(normalizedDay)] = storedGoalKcal;
      if (storedGoalKcal > 0) {
        learnedRequests.add(
          DailyLearnedTdeeGoalDayRequest(
            day: normalizedDay,
            storedGoalKcal: storedGoalKcal,
          ),
        );
      }
    }

    final learnedGoalsFuture = learnedRequests.isEmpty
        ? Future<Map<String, DailyLearnedTdeeGoalData?>>.value(
            const <String, DailyLearnedTdeeGoalData?>{},
          )
        : ref.read(
            dailyLearnedTdeeGoalsForDaysProvider(
              DailyLearnedTdeeGoalDaysRequest(
                today: now,
                days: learnedRequests,
              ),
            ).future,
          );
    final selectedDayKey = request.days.isEmpty
        ? null
        : diaryDayKey(request.days.last);
    final forceRefreshDayKeys = <String>{
      for (final learnedRequest in learnedRequests)
        if (diaryDayKey(learnedRequest.day) == selectedDayKey ||
            isSameDiaryDay(learnedRequest.day, now))
          diaryDayKey(learnedRequest.day),
    };
    final dayActivityByKey = await _loadActivityDataByDay(
      diaryHealthService: diaryHealthService,
      days: learnedRequests.map((request) => request.day),
      settings: settings,
      healthStatus: healthStatus,
      userHeightCm: settings.calculatorProfile?.heightCm,
      forceRefreshDayKeys: forceRefreshDayKeys,
    );
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    final learnedGoals = await learnedGoalsFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goals disposed.');
    }
    final goalsByDay = <String, ResolvedCalorieGoalData>{};

    for (final day in request.days) {
      final normalizedDay = normalizeDiaryDay(day);
      final dayKey = diaryDayKey(normalizedDay);
      final storedGoalKcal = storedGoalsByDay[dayKey] ?? 0;
      if (storedGoalKcal <= 0) {
        goalsByDay[dayKey] = ResolvedCalorieGoalData(
          day: normalizedDay,
          storedGoalKcal: storedGoalKcal,
          goalKcal: storedGoalKcal,
          activityDeltaKcal: 0,
          lastWeekAverageActiveKcal: 0,
          todayActiveKcal: 0,
          usedLearnedTdee: false,
          usesPreLearningActivityBonus: false,
          wasClampedToMinimum: false,
        );
        continue;
      }

      goalsByDay[dayKey] = _resolveGoalDataFromLoadedInputs(
        day: normalizedDay,
        storedGoalKcal: storedGoalKcal,
        settings: settings,
        dayActivity:
            dayActivityByKey[dayKey] ??
            const _ResolvedDayActivityData(
              todayActiveKcal: 0,
              isTrackingActive: false,
            ),
        learnedGoal: learnedGoals[dayKey],
      );
    }

    return Map<String, ResolvedCalorieGoalData>.unmodifiable(goalsByDay);
  } finally {
    keepAliveLink.close();
  }
}

/// Resolved calorie goal for day.
@riverpod
Future<ResolvedCalorieGoalData> resolvedCalorieGoalForDay(
  Ref ref,
  DateTime day,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    // Trigger recompute when calorie logs mutate through overview revision.
    ref.watch(calorieOverviewRevisionProvider);
    final normalizedDay = normalizeDiaryDay(day);
    final referenceNow = ref.watch(calorieBalanceNowProvider)();
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
    final diaryHealthService = ref.watch(diaryHealthServiceProvider);
    final now = normalizeDiaryDay(referenceNow);
    final healthStatus = await healthStatusFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goal disposed.');
    }
    var settings = await settingsFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goal disposed.');
    }
    if (healthStatus.accessState == HealthDataAccessState.ready &&
        settings.activityTrackingStartDate == null) {
      settings = settings.markActivityTrackingStarted(
        _activityTrackingStartDate(referenceNow),
      );
    }
    final storedGoalKcal = settings.goalKcalForDay(normalizedDay);
    if (!kReleaseMode) {
      final profileJson = settings.calculatorProfile?.toJson();
      final message =
          'CALC_GOAL_DEBUG '
          'day=${diaryDayKey(normalizedDay)} '
          'now=${diaryDayKey(now)} '
          'storedGoalKcal=${storedGoalKcal.toStringAsFixed(2)} '
          'hasLearnedTdee=${settings.hasLearnedTdee} '
          'latestLearnedTdeeKcal='
          '${settings.latestLearnedTdeeKcal?.toStringAsFixed(2) ?? 'null'} '
          'calculatorProfile=$profileJson';
      log(message, name: _resolvedGoalLogName);
    }

    if (storedGoalKcal <= 0) {
      return ResolvedCalorieGoalData(
        day: normalizedDay,
        storedGoalKcal: storedGoalKcal,
        goalKcal: storedGoalKcal,
        activityDeltaKcal: 0,
        lastWeekAverageActiveKcal: 0,
        todayActiveKcal: 0,
        usedLearnedTdee: false,
        usesPreLearningActivityBonus: false,
        wasClampedToMinimum: false,
      );
    }

    final learnedGoalFuture = ref.read(
      dailyLearnedTdeeGoalForDayProvider(
        day: normalizedDay,
        today: now,
        storedGoalKcal: storedGoalKcal,
      ).future,
    );
    final dayActivityByKey = await _loadActivityDataByDay(
      diaryHealthService: diaryHealthService,
      days: [normalizedDay],
      settings: settings,
      healthStatus: healthStatus,
      userHeightCm: settings.calculatorProfile?.heightCm,
      forceRefreshDayKeys: {diaryDayKey(normalizedDay)},
    );
    final dayActivity =
        dayActivityByKey[diaryDayKey(normalizedDay)] ??
        const _ResolvedDayActivityData(
          todayActiveKcal: 0,
          isTrackingActive: false,
        );
    final learnedGoal = await learnedGoalFuture;
    if (!ref.mounted) {
      throw StateError('Resolved calorie goal disposed.');
    }
    if (learnedGoal == null) {
      final activityCredit = dayActivity.isTrackingActive
          ? calculateActivityCredit(
              rawActivityKcal: dayActivity.todayActiveKcal,
            )
          : const CalorieActivityCreditBreakdown(
              rawActivityKcal: 0,
              correctedActivityKcal: 0,
              activityCapKcal: 0,
              creditedActivityKcal: 0,
              wasCapped: false,
            );
      final activityDeltaKcal = activityCredit.creditedActivityKcal;
      final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
        storedGoalKcal: storedGoalKcal,
        activityDeltaKcal: activityDeltaKcal,
      );
      if (!kReleaseMode) {
        final message =
            'CALC_GOAL_DEBUG '
            'day=${diaryDayKey(normalizedDay)} '
            'isActivityTrackingActive=${dayActivity.isTrackingActive} '
            'todayActiveKcal=${dayActivity.todayActiveKcal} '
            'correctedActivityKcal='
            '${activityCredit.correctedActivityKcal.toStringAsFixed(2)} '
            'activityCapKcal='
            '${activityCredit.activityCapKcal.toStringAsFixed(2)} '
            'activityDeltaKcal='
            '${activityDeltaKcal.toStringAsFixed(2)} '
            'resolvedGoalKcal=${goalBreakdown.goalKcal.toStringAsFixed(2)}';
        log(message, name: _resolvedGoalLogName);
      }

      return ResolvedCalorieGoalData(
        day: normalizedDay,
        storedGoalKcal: storedGoalKcal,
        goalKcal: goalBreakdown.goalKcal,
        activityDeltaKcal: activityDeltaKcal,
        activityComparisonKcal: activityDeltaKcal,
        correctedActivityKcal: activityCredit.correctedActivityKcal,
        activityCapKcal: activityCredit.activityCapKcal,
        wasActivityCapped: activityCredit.wasCapped,
        expectedActivityKcal: storedGoalKcal,
        lastWeekAverageActiveKcal: 0,
        todayActiveKcal: dayActivity.todayActiveKcal,
        usedLearnedTdee: false,
        usesPreLearningActivityBonus: false,
        isActivityTrackingActive: dayActivity.isTrackingActive,
        wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
      );
    }

    final baseTdeeKcal = learnedGoal.calculatedBaseTdeeKcal;
    final averageCreditedActivityKcal = learnedGoal.averageCreditedActivityKcal;
    final activityCredit = dayActivity.isTrackingActive
        ? calculateActivityCredit(
            rawActivityKcal: dayActivity.todayActiveKcal,
          )
        : const CalorieActivityCreditBreakdown(
            rawActivityKcal: 0,
            correctedActivityKcal: 0,
            activityCapKcal: 0,
            creditedActivityKcal: 0,
            wasCapped: false,
          );
    final activityDeltaKcal = activityCredit.creditedActivityKcal;
    final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
      storedGoalKcal: learnedGoal.newGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
    );
    if (!kReleaseMode) {
      final message =
          'CALC_GOAL_DEBUG '
          'day=${diaryDayKey(normalizedDay)} '
          'calculatedBaseTdeeKcal=${baseTdeeKcal.toStringAsFixed(2)} '
          'averageCreditedActivityKcal='
          '${averageCreditedActivityKcal.toStringAsFixed(2)} '
          'todayActiveKcal=${dayActivity.todayActiveKcal} '
          'correctedActivityKcal='
          '${activityCredit.correctedActivityKcal.toStringAsFixed(2)} '
          'activityCapKcal='
          '${activityCredit.activityCapKcal.toStringAsFixed(2)} '
          'activityDeltaKcal=${activityDeltaKcal.toStringAsFixed(2)} '
          'learnedTargetKcal=${learnedGoal.newGoalKcal.toStringAsFixed(2)} '
          'resolvedGoalKcal=${goalBreakdown.goalKcal.toStringAsFixed(2)}';
      log(message, name: _resolvedGoalLogName);
    }

    return ResolvedCalorieGoalData(
      day: normalizedDay,
      storedGoalKcal: learnedGoal.newGoalKcal,
      goalKcal: goalBreakdown.goalKcal,
      activityDeltaKcal: activityDeltaKcal,
      activityComparisonKcal: activityDeltaKcal,
      correctedActivityKcal: activityCredit.correctedActivityKcal,
      activityCapKcal: activityCredit.activityCapKcal,
      wasActivityCapped: activityCredit.wasCapped,
      expectedActivityKcal: baseTdeeKcal,
      lastWeekAverageActiveKcal: averageCreditedActivityKcal,
      todayActiveKcal: dayActivity.todayActiveKcal,
      usedLearnedTdee: true,
      usesPreLearningActivityBonus: false,
      isActivityTrackingActive: dayActivity.isTrackingActive,
      wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
    );
  } finally {
    keepAliveLink.close();
  }
}

ResolvedCalorieGoalData _resolveGoalDataFromLoadedInputs({
  required DateTime day,
  required double storedGoalKcal,
  required CalorieGoalSettings settings,
  required _ResolvedDayActivityData dayActivity,
  required DailyLearnedTdeeGoalData? learnedGoal,
}) {
  if (learnedGoal == null) {
    final activityCredit = dayActivity.isTrackingActive
        ? calculateActivityCredit(
            rawActivityKcal: dayActivity.todayActiveKcal,
          )
        : const CalorieActivityCreditBreakdown(
            rawActivityKcal: 0,
            correctedActivityKcal: 0,
            activityCapKcal: 0,
            creditedActivityKcal: 0,
            wasCapped: false,
          );
    final activityDeltaKcal = activityCredit.creditedActivityKcal;
    final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
      storedGoalKcal: storedGoalKcal,
      activityDeltaKcal: activityDeltaKcal,
    );

    return ResolvedCalorieGoalData(
      day: day,
      storedGoalKcal: storedGoalKcal,
      goalKcal: goalBreakdown.goalKcal,
      activityDeltaKcal: activityDeltaKcal,
      activityComparisonKcal: activityDeltaKcal,
      correctedActivityKcal: activityCredit.correctedActivityKcal,
      activityCapKcal: activityCredit.activityCapKcal,
      wasActivityCapped: activityCredit.wasCapped,
      expectedActivityKcal: storedGoalKcal,
      lastWeekAverageActiveKcal: 0,
      todayActiveKcal: dayActivity.todayActiveKcal,
      usedLearnedTdee: false,
      usesPreLearningActivityBonus: false,
      isActivityTrackingActive: dayActivity.isTrackingActive,
      wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
    );
  }

  final baseTdeeKcal = learnedGoal.calculatedBaseTdeeKcal;
  final averageCreditedActivityKcal = learnedGoal.averageCreditedActivityKcal;
  final activityCredit = dayActivity.isTrackingActive
      ? calculateActivityCredit(
          rawActivityKcal: dayActivity.todayActiveKcal,
        )
      : const CalorieActivityCreditBreakdown(
          rawActivityKcal: 0,
          correctedActivityKcal: 0,
          activityCapKcal: 0,
          creditedActivityKcal: 0,
          wasCapped: false,
        );
  final activityDeltaKcal = activityCredit.creditedActivityKcal;
  final goalBreakdown = CalorieBudgetCalculator.resolveDailyGoal(
    storedGoalKcal: learnedGoal.newGoalKcal,
    activityDeltaKcal: activityDeltaKcal,
  );

  return ResolvedCalorieGoalData(
    day: day,
    storedGoalKcal: learnedGoal.newGoalKcal,
    goalKcal: goalBreakdown.goalKcal,
    activityDeltaKcal: activityDeltaKcal,
    activityComparisonKcal: activityDeltaKcal,
    correctedActivityKcal: activityCredit.correctedActivityKcal,
    activityCapKcal: activityCredit.activityCapKcal,
    wasActivityCapped: activityCredit.wasCapped,
    expectedActivityKcal: baseTdeeKcal,
    lastWeekAverageActiveKcal: averageCreditedActivityKcal,
    todayActiveKcal: dayActivity.todayActiveKcal,
    usedLearnedTdee: true,
    usesPreLearningActivityBonus: false,
    isActivityTrackingActive: dayActivity.isTrackingActive,
    wasClampedToMinimum: goalBreakdown.wasClampedToMinimum,
  );
}

class _ResolvedDayActivityData {
  const _ResolvedDayActivityData({
    required this.todayActiveKcal,
    required this.isTrackingActive,
  });

  final int todayActiveKcal;
  final bool isTrackingActive;
}

Future<Map<String, _ResolvedDayActivityData>> _loadActivityDataByDay({
  required DiaryHealthService diaryHealthService,
  required Iterable<DateTime> days,
  required CalorieGoalSettings settings,
  required HealthConnectionStatus healthStatus,
  double? userHeightCm,
  Set<String> forceRefreshDayKeys = const <String>{},
}) async {
  final normalizedDaysByKey = <String, DateTime>{
    for (final day in days)
      diaryDayKey(normalizeDiaryDay(day)): normalizeDiaryDay(day),
  };
  final activityByDay = <String, _ResolvedDayActivityData>{
    for (final dayKey in normalizedDaysByKey.keys)
      dayKey: const _ResolvedDayActivityData(
        todayActiveKcal: 0,
        isTrackingActive: false,
      ),
  };
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return activityByDay;
  }

  final activeDays = normalizedDaysByKey.values
      .where(settings.isActivityTrackingActiveForDay)
      .toList(growable: false);
  if (activeDays.isEmpty) {
    return activityByDay;
  }

  final activeKcalByDay = await loadHealthActivityKcalByDay(
    diaryHealthService: diaryHealthService,
    days: activeDays,
    logName: _resolvedGoalLogName,
    aggregateFailureMessage: 'Failed to load aggregate activity for goals.',
    userHeightCm: userHeightCm,
    forceRefreshDayKeys: forceRefreshDayKeys,
  );
  for (final day in activeDays) {
    final dayKey = diaryDayKey(day);
    activityByDay[dayKey] = _ResolvedDayActivityData(
      todayActiveKcal: activeKcalByDay[dayKey] ?? 0,
      isTrackingActive: true,
    );
  }
  return activityByDay;
}

DateTime _activityTrackingStartDate(DateTime now) {
  return addDiaryDays(
    normalizeDiaryDay(now),
    -(_activityTrackingBackfillDayCount - 1),
  );
}
