import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/application/'
    'daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/application/'
    'daily_learned_tdee_resolver.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'health_connection_controller.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'manual_health_weight_entries_controller.dart';

part 'daily_learned_tdee_provider.g.dart';

const _learnedTdeeLogName = 'DailyLearnedTdeeProvider';

/// Resolve optional learned TDEE overrides for multiple days.
@riverpod
Future<Map<String, DailyLearnedTdeeGoalData?>> dailyLearnedTdeeGoalsForDays(
  Ref ref,
  DailyLearnedTdeeGoalDaysRequest request,
) async {
  // Trigger recompute when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);
  final keepAliveLink = ref.keepAlive();
  try {
    final repository = ref.watch(calorieLogRepositoryProvider);
    final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
    final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final manualEntriesFuture = ref.watch(
      manualHealthWeightEntriesControllerProvider.future,
    );
    final healthWeightService = ref.watch(healthWeightServiceProvider);
    final diaryHealthService = ref.watch(diaryHealthServiceProvider);
    final result = <String, DailyLearnedTdeeGoalData?>{
      for (final dayRequest in request.days) diaryDayKey(dayRequest.day): null,
    };

    final settings = await settingsFuture;
    final runState = await runStateFuture;
    final heartDayKeys = runState.heartDayKeys.toSet();

    final contexts = [
      for (final dayRequest in request.days)
        DailyLearnedTdeeResolver.learnedTdeeDayContext(
          settings: settings,
          dayRequest: dayRequest,
          today: request.today,
        ),
    ].whereType<DailyLearnedTdeeDayContext>().toList(growable: false);
    if (contexts.isEmpty) {
      return Map<String, DailyLearnedTdeeGoalData?>.unmodifiable(result);
    }

    final firstLearningStartDate = DailyLearnedTdeeResolver.earliestDay(
      contexts.map((context) => context.firstLearningStartDate),
    );
    final lastLearningEndExclusive = nextDiaryDay(
      DailyLearnedTdeeResolver.latestDay(
        contexts.map((context) => context.lastWindow.windowEndDate),
      ),
    );
    final entries = await repository.readEntriesInRange(
      startInclusive: firstLearningStartDate,
      endExclusive: lastLearningEndExclusive,
    );
    if (entries.isEmpty) {
      return Map<String, DailyLearnedTdeeGoalData?>.unmodifiable(result);
    }

    final healthStatus = await healthStatusFuture;
    final manualEntries = await manualEntriesFuture;
    final healthWeights = await _loadHealthWeights(
      healthWeightService: healthWeightService,
      healthStatus: healthStatus,
      startDate: DailyLearnedTdeeResolver.earliestDay(
        contexts.map((context) => context.weightStartDate),
      ),
      endDateExclusive: nextDiaryDay(
        DailyLearnedTdeeResolver.latestDay(
          contexts.map((context) => context.lastWindow.nextBoundaryDay),
        ),
      ),
    );
    final activeKcalByDay = await _loadActiveKcalByDay(
      diaryHealthService: diaryHealthService,
      settings: settings,
      healthStatus: healthStatus,
      windows: DailyLearnedTdeeResolver.uniqueWindows(contexts),
    );
    final entriesByDay = entries.groupByDiaryDayKey();
    final manualWeightByDay = DailyLearnedTdeeResolver.manualWeightByDay(
      manualEntries,
    );
    final representativeWeightByDay =
        DailyLearnedTdeeResolver.representativeWeightByDay(
          healthWeights,
        );
    for (final context in contexts) {
      result[diaryDayKey(
        context.day,
      )] = DailyLearnedTdeeResolver.resolveLearnedTdeeGoalFromLoadedData(
        context: context,
        settings: settings,
        entriesByDay: entriesByDay,
        manualWeightByDay: manualWeightByDay,
        representativeWeightByDay: representativeWeightByDay,
        activeKcalByDay: activeKcalByDay,
        heartDayKeys: heartDayKeys,
      );
    }

    return Map<String, DailyLearnedTdeeGoalData?>.unmodifiable(result);
  } finally {
    keepAliveLink.close();
  }
}

/// Resolve optional learned TDEE override for [day].
@riverpod
Future<DailyLearnedTdeeGoalData?> dailyLearnedTdeeGoalForDay(
  Ref ref, {
  required DateTime day,
  required DateTime today,
  required double storedGoalKcal,
}) async {
  // Trigger recompute when calorie logs mutate through overview revision.
  ref.watch(calorieOverviewRevisionProvider);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final settingsFuture = ref.watch(calorieGoalControllerProvider.future);
  final runStateFuture = ref.watch(burnWeekRunControllerProvider.future);
  final healthStatusFuture = ref.watch(
    healthConnectionControllerProvider.future,
  );
  final manualEntriesFuture = ref.watch(
    manualHealthWeightEntriesControllerProvider.future,
  );
  final healthWeightService = ref.watch(healthWeightServiceProvider);
  final diaryHealthService = ref.watch(diaryHealthServiceProvider);

  final normalizedDay = normalizeDiaryDay(day);
  final normalizedToday = normalizeDiaryDay(today);
  final learningReferenceDay = normalizedDay.isAfter(normalizedToday)
      ? normalizedToday
      : normalizedDay;

  final settings = await settingsFuture;
  final runState = await runStateFuture;
  final heartDayKeys = runState.heartDayKeys.toSet();
  final anchorEntry = settings.cycleAnchorEntryForDay(normalizedDay);
  if (anchorEntry == null) {
    return null;
  }

  final windows = DailyLearnedTdeeResolver.weeklyLearnedWindowsForDay(
    anchorEntry: anchorEntry,
    day: learningReferenceDay,
  );
  if (windows.isEmpty) {
    return null;
  }

  final firstLearningStartDate =
      DailyLearnedTdeeResolver.learningStartDateForWindow(
        anchorEntry: anchorEntry,
        windowEndDate: windows.first.windowEndDate,
      );
  final lastWindow = windows.last;
  final entries = await repository.readEntriesInRange(
    startInclusive: firstLearningStartDate,
    endExclusive: nextDiaryDay(lastWindow.windowEndDate),
  );
  if (entries.isEmpty) {
    return null;
  }

  final healthStatus = await healthStatusFuture;
  final manualEntries = await manualEntriesFuture;
  final healthWeights = await _loadHealthWeights(
    healthWeightService: healthWeightService,
    healthStatus: healthStatus,
    startDate: DailyLearnedTdeeResolver.weightStartDateForLearning(
      anchorEntry: anchorEntry,
      firstLearningStartDate: firstLearningStartDate,
    ),
    endDateExclusive: nextDiaryDay(lastWindow.nextBoundaryDay),
  );
  final activeKcalByDay = await _loadActiveKcalByDay(
    diaryHealthService: diaryHealthService,
    settings: settings,
    healthStatus: healthStatus,
    windows: windows,
  );
  final entriesByDay = entries.groupByDiaryDayKey();
  final manualWeightByDay = DailyLearnedTdeeResolver.manualWeightByDay(
    manualEntries,
  );
  final representativeWeightByDay =
      DailyLearnedTdeeResolver.representativeWeightByDay(healthWeights);
  final context = DailyLearnedTdeeDayContext(
    day: normalizedDay,
    storedGoalKcal: storedGoalKcal,
    anchorEntry: anchorEntry,
    windows: windows,
    firstLearningStartDate: firstLearningStartDate,
    weightStartDate: DailyLearnedTdeeResolver.weightStartDateForLearning(
      anchorEntry: anchorEntry,
      firstLearningStartDate: firstLearningStartDate,
    ),
  );

  return DailyLearnedTdeeResolver.resolveLearnedTdeeGoalFromLoadedData(
    context: context,
    settings: settings,
    entriesByDay: entriesByDay,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: representativeWeightByDay,
    activeKcalByDay: activeKcalByDay,
    heartDayKeys: heartDayKeys,
  );
}

Future<List<HealthWeightSample>> _loadHealthWeights({
  required HealthWeightService healthWeightService,
  required HealthConnectionStatus healthStatus,
  required DateTime startDate,
  required DateTime endDateExclusive,
}) async {
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return const <HealthWeightSample>[];
  }
  return healthWeightService.loadWeightSamples(
    startInclusive: startDate,
    endExclusive: endDateExclusive,
  );
}

Future<Map<String, int>> _loadActiveKcalByDay({
  required DiaryHealthService diaryHealthService,
  required CalorieGoalSettings settings,
  required HealthConnectionStatus healthStatus,
  required List<WeeklyLearnedWindow> windows,
}) async {
  final activeKcalByDay = <String, int>{};
  for (final window in windows) {
    for (final day in window.windowDays) {
      activeKcalByDay[diaryDayKey(day)] = 0;
    }
  }
  if (healthStatus.accessState != HealthDataAccessState.ready) {
    return activeKcalByDay;
  }

  final days = {
    for (final window in windows)
      for (final windowDay in window.windowDays)
        if (settings.isActivityTrackingActiveForDay(windowDay))
          diaryDayKey(windowDay): windowDay,
  }.values.toList(growable: false);
  if (days.isEmpty) {
    return activeKcalByDay;
  }
  final loadedActiveKcalByDay = await loadHealthActivityKcalByDay(
    diaryHealthService: diaryHealthService,
    days: days,
    userHeightCm: settings.calculatorProfile?.heightCm,
    logName: _learnedTdeeLogName,
    aggregateFailureMessage:
        'Failed to load aggregate activity for learned TDEE.',
  );
  activeKcalByDay.addAll(loadedActiveKcalByDay);
  return activeKcalByDay;
}
