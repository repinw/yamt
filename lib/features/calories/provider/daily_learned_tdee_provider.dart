import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_activity_kcal_reader.dart';
import 'package:yamt/features/calories/application/'
    'daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_extensions.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_overview_revision_provider.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/health/presentation/controllers/health_connection_controller.dart';
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
    final healthStatusFuture = ref.watch(
      healthConnectionControllerProvider.future,
    );
    final manualEntriesFuture = ref.watch(
      manualHealthWeightEntriesControllerProvider.future,
    );
    final healthWeightService = ref.watch(healthWeightServiceProvider);
    final diaryHealthService = ref.watch(diaryHealthServiceProvider);

    final settings = await settingsFuture;
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }

    final contexts = [
      for (final dayRequest in request.days)
        _learnedTdeeDayContext(
          settings: settings,
          dayRequest: dayRequest,
          today: request.today,
        ),
    ].whereType<_LearnedTdeeDayContext>().toList(growable: false);
    final result = <String, DailyLearnedTdeeGoalData?>{
      for (final dayRequest in request.days) diaryDayKey(dayRequest.day): null,
    };
    if (contexts.isEmpty) {
      return Map<String, DailyLearnedTdeeGoalData?>.unmodifiable(result);
    }

    final firstLearningStartDate = _earliestDay(
      contexts.map((context) => context.firstLearningStartDate),
    );
    final lastLearningEndExclusive = nextDiaryDay(
      _latestDay(
        contexts.map((context) => context.lastWindow.windowEndDate),
      ),
    );
    final entries = await repository.readEntriesInRange(
      startInclusive: firstLearningStartDate,
      endExclusive: lastLearningEndExclusive,
    );
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }
    if (entries.isEmpty) {
      return Map<String, DailyLearnedTdeeGoalData?>.unmodifiable(result);
    }

    final healthStatus = await healthStatusFuture;
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }
    final manualEntries = await manualEntriesFuture;
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }
    final healthWeights = await _loadHealthWeights(
      healthWeightService: healthWeightService,
      healthStatus: healthStatus,
      startDate: _earliestDay(
        contexts.map((context) => context.weightStartDate),
      ),
      endDateExclusive: nextDiaryDay(
        _latestDay(
          contexts.map((context) => context.lastWindow.nextBoundaryDay),
        ),
      ),
    );
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }
    final activeKcalByDay = await _loadActiveKcalByDay(
      diaryHealthService: diaryHealthService,
      settings: settings,
      healthStatus: healthStatus,
      windows: _uniqueWindows(contexts),
    );
    if (!ref.mounted) {
      throw StateError('Weekly learned TDEE disposed.');
    }

    final entriesByDay = entries.groupByDiaryDayKey();
    final manualWeightByDay = _manualWeightByDay(manualEntries);
    final representativeWeightByDay = _representativeWeightByDay(
      healthWeights,
    );
    for (final context in contexts) {
      result[diaryDayKey(context.day)] = _resolveLearnedTdeeGoalFromLoadedData(
        context: context,
        settings: settings,
        entriesByDay: entriesByDay,
        manualWeightByDay: manualWeightByDay,
        representativeWeightByDay: representativeWeightByDay,
        activeKcalByDay: activeKcalByDay,
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
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final anchorEntry = settings.cycleAnchorEntryForDay(normalizedDay);
  if (anchorEntry == null) {
    return null;
  }

  final windows = _weeklyLearnedWindowsForDay(
    anchorEntry: anchorEntry,
    day: learningReferenceDay,
  );
  if (windows.isEmpty) {
    return null;
  }

  final firstLearningStartDate = _learningStartDateForWindow(
    anchorEntry: anchorEntry,
    windowEndDate: windows.first.windowEndDate,
  );
  final lastWindow = windows.last;
  final entries = await repository.readEntriesInRange(
    startInclusive: firstLearningStartDate,
    endExclusive: nextDiaryDay(lastWindow.windowEndDate),
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  if (entries.isEmpty) {
    return null;
  }

  final healthStatus = await healthStatusFuture;
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final manualEntries = await manualEntriesFuture;
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final healthWeights = await _loadHealthWeights(
    healthWeightService: healthWeightService,
    healthStatus: healthStatus,
    startDate: _weightStartDateForLearning(
      anchorEntry: anchorEntry,
      firstLearningStartDate: firstLearningStartDate,
    ),
    endDateExclusive: nextDiaryDay(lastWindow.nextBoundaryDay),
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }
  final activeKcalByDay = await _loadActiveKcalByDay(
    diaryHealthService: diaryHealthService,
    settings: settings,
    healthStatus: healthStatus,
    windows: windows,
  );
  if (!ref.mounted) {
    throw StateError('Weekly learned TDEE disposed.');
  }

  final entriesByDay = entries.groupByDiaryDayKey();
  final manualWeightByDay = _manualWeightByDay(manualEntries);
  final representativeWeightByDay = _representativeWeightByDay(healthWeights);
  var previousGoalKcal = settings.goalKcalForDay(
    previousDiaryDay(windows.first.windowStartDate),
  );
  if (previousGoalKcal <= 0) {
    previousGoalKcal = storedGoalKcal;
  }
  var previousLearnedTdeeKcal = _learnedTdeeSeed(
    settings: settings,
    day: windows.first.windowStartDate,
    fallbackGoalKcal: previousGoalKcal,
  );
  DailyLearnedTdeeGoalData? latest;

  for (final window in windows) {
    final learningDays = buildCalorieCarryoverDateRange(
      startInclusive: window.learningStartDate,
      endExclusive: nextDiaryDay(window.windowEndDate),
    );
    final intakeKcalByDay = _resolveLearningIntake(
      days: learningDays,
      entriesByDay: entriesByDay,
      settings: settings,
    );
    if (intakeKcalByDay == null) {
      return latest;
    }

    final weightPoints = _weeklyWeightPoints(
      settings: settings,
      anchorEntry: anchorEntry,
      window: window,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
    if (weightPoints.length < 2) {
      return latest;
    }

    final goalMode = _goalModeForDay(
      settings: settings,
      day: window.windowEndDate,
    );
    final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
        ? 0.0
        : _goalSpeedForDay(settings: settings, day: window.windowEndDate);
    final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      isLosing: goalMode == CalorieGoalMode.lose,
      isGaining: goalMode == CalorieGoalMode.gain,
      intakeKcalByDay: intakeKcalByDay,
      rawActivityKcalByDay: _activityKcalByDay(
        days: learningDays,
        activeKcalByDay: activeKcalByDay,
      ),
      weightPoints: weightPoints,
    );
    latest = DailyLearnedTdeeGoalData(
      measured: calculation.measured,
      calculatedBaseTdeeKcal: calculation.calculatedBaseTdeeKcal,
      newBaseGoalKcal: calculation.newBaseGoalKcal,
      averageCreditedActivityKcal:
          calculation.measured.averageCreditedActivityKcal,
    );
    previousGoalKcal = calculation.newGoalKcal;
    previousLearnedTdeeKcal = calculation.calculatedBaseTdeeKcal;
  }

  return latest;
}

_LearnedTdeeDayContext? _learnedTdeeDayContext({
  required CalorieGoalSettings settings,
  required DailyLearnedTdeeGoalDayRequest dayRequest,
  required DateTime today,
}) {
  final normalizedDay = normalizeDiaryDay(dayRequest.day);
  final normalizedToday = normalizeDiaryDay(today);
  final learningReferenceDay = normalizedDay.isAfter(normalizedToday)
      ? normalizedToday
      : normalizedDay;
  final anchorEntry = settings.cycleAnchorEntryForDay(normalizedDay);
  if (anchorEntry == null) {
    return null;
  }

  final windows = _weeklyLearnedWindowsForDay(
    anchorEntry: anchorEntry,
    day: learningReferenceDay,
  );
  if (windows.isEmpty) {
    return null;
  }

  final firstLearningStartDate = _learningStartDateForWindow(
    anchorEntry: anchorEntry,
    windowEndDate: windows.first.windowEndDate,
  );
  return _LearnedTdeeDayContext(
    day: normalizedDay,
    storedGoalKcal: dayRequest.storedGoalKcal,
    anchorEntry: anchorEntry,
    windows: windows,
    firstLearningStartDate: firstLearningStartDate,
    weightStartDate: _weightStartDateForLearning(
      anchorEntry: anchorEntry,
      firstLearningStartDate: firstLearningStartDate,
    ),
  );
}

DailyLearnedTdeeGoalData? _resolveLearnedTdeeGoalFromLoadedData({
  required _LearnedTdeeDayContext context,
  required CalorieGoalSettings settings,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
  required Map<String, int> activeKcalByDay,
}) {
  final contextLearningDays = buildCalorieCarryoverDateRange(
    startInclusive: context.firstLearningStartDate,
    endExclusive: nextDiaryDay(context.lastWindow.windowEndDate),
  );
  if (!_hasEntriesForAnyDay(
    days: contextLearningDays,
    entriesByDay: entriesByDay,
  )) {
    return null;
  }

  var previousGoalKcal = settings.goalKcalForDay(
    previousDiaryDay(context.windows.first.windowStartDate),
  );
  if (previousGoalKcal <= 0) {
    previousGoalKcal = context.storedGoalKcal;
  }
  var previousLearnedTdeeKcal = _learnedTdeeSeed(
    settings: settings,
    day: context.windows.first.windowStartDate,
    fallbackGoalKcal: previousGoalKcal,
  );
  DailyLearnedTdeeGoalData? latest;

  for (final window in context.windows) {
    final learningDays = buildCalorieCarryoverDateRange(
      startInclusive: window.learningStartDate,
      endExclusive: nextDiaryDay(window.windowEndDate),
    );
    final intakeKcalByDay = _resolveLearningIntake(
      days: learningDays,
      entriesByDay: entriesByDay,
      settings: settings,
    );
    if (intakeKcalByDay == null) {
      return latest;
    }

    final weightPoints = _weeklyWeightPoints(
      settings: settings,
      anchorEntry: context.anchorEntry,
      window: window,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
    if (weightPoints.length < 2) {
      return latest;
    }

    final goalMode = _goalModeForDay(
      settings: settings,
      day: window.windowEndDate,
    );
    final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
        ? 0.0
        : _goalSpeedForDay(settings: settings, day: window.windowEndDate);
    final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
      previousGoalKcal: previousGoalKcal,
      previousLearnedTdeeKcal: previousLearnedTdeeKcal,
      goalSpeedKgPerWeek: goalSpeedKgPerWeek,
      isLosing: goalMode == CalorieGoalMode.lose,
      isGaining: goalMode == CalorieGoalMode.gain,
      intakeKcalByDay: intakeKcalByDay,
      rawActivityKcalByDay: _activityKcalByDay(
        days: learningDays,
        activeKcalByDay: activeKcalByDay,
      ),
      weightPoints: weightPoints,
    );
    latest = DailyLearnedTdeeGoalData(
      measured: calculation.measured,
      calculatedBaseTdeeKcal: calculation.calculatedBaseTdeeKcal,
      newBaseGoalKcal: calculation.newBaseGoalKcal,
      averageCreditedActivityKcal:
          calculation.measured.averageCreditedActivityKcal,
    );
    previousGoalKcal = calculation.newGoalKcal;
    previousLearnedTdeeKcal = calculation.calculatedBaseTdeeKcal;
  }

  return latest;
}

DateTime _earliestDay(Iterable<DateTime> days) {
  return days.reduce((current, day) => day.isBefore(current) ? day : current);
}

DateTime _latestDay(Iterable<DateTime> days) {
  return days.reduce((current, day) => day.isAfter(current) ? day : current);
}

List<_WeeklyLearnedWindow> _uniqueWindows(
  List<_LearnedTdeeDayContext> contexts,
) {
  final windowsByKey = <String, _WeeklyLearnedWindow>{};
  for (final context in contexts) {
    for (final window in context.windows) {
      windowsByKey[_windowKey(window)] = window;
    }
  }
  return List<_WeeklyLearnedWindow>.unmodifiable(windowsByKey.values);
}

String _windowKey(_WeeklyLearnedWindow window) {
  return '${diaryDayKey(window.windowStartDate)}:'
      '${diaryDayKey(window.windowEndDate)}';
}

bool _hasEntriesForAnyDay({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
}) {
  for (final day in days) {
    final entries = entriesByDay[diaryDayKey(day)];
    if (entries != null && entries.isNotEmpty) {
      return true;
    }
  }
  return false;
}

List<_WeeklyLearnedWindow> _weeklyLearnedWindowsForDay({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime day,
}) {
  final windows = <_WeeklyLearnedWindow>[];
  var windowStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  while (true) {
    final windowLengthDays =
        CalorieWeeklyWindowResolver.windowLengthDaysForStart(
          anchorEntry: anchorEntry,
          windowStartDate: windowStartDate,
        );
    final dueDate = addDiaryDays(windowStartDate, windowLengthDays);
    if (dueDate.isAfter(day)) {
      break;
    }
    final windowEndDate = addDiaryDays(windowStartDate, windowLengthDays - 1);
    final learningStartDate = _learningStartDateForWindow(
      anchorEntry: anchorEntry,
      windowEndDate: windowEndDate,
    );
    windows.add(
      _WeeklyLearnedWindow(
        windowStartDate: windowStartDate,
        windowEndDate: windowEndDate,
        dueDate: dueDate,
        learningStartDate: learningStartDate,
        windowDays: buildCalorieCarryoverDateRange(
          startInclusive: windowStartDate,
          endExclusive: dueDate,
        ),
        nextBoundaryDay: nextDiaryDay(windowEndDate),
        previousBoundaryDay: windows.isEmpty
            ? null
            : previousDiaryDay(windowStartDate),
      ),
    );
    windowStartDate = nextDiaryDay(windowEndDate);
  }
  return List<_WeeklyLearnedWindow>.unmodifiable(windows);
}

DateTime _learningStartDateForWindow({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime windowEndDate,
}) {
  final anchorStartDate = CalorieWeeklyWindowResolver.firstWindowStartDate(
    anchorEntry,
  );
  final oldestAllowedStartDate = windowEndDate.subtract(
    const Duration(days: dailyLearnedTdeeMaximumLookbackDays - 1),
  );
  if (anchorStartDate.isBefore(oldestAllowedStartDate)) {
    return normalizeDiaryDay(oldestAllowedStartDate);
  }
  return normalizeDiaryDay(anchorStartDate);
}

DateTime _weightStartDateForLearning({
  required CalorieGoalHistoryEntry anchorEntry,
  required DateTime firstLearningStartDate,
}) {
  final anchorWeightSourceDay =
      CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
        anchorEntry: anchorEntry,
        windowStartDate: CalorieWeeklyWindowResolver.firstWindowStartDate(
          anchorEntry,
        ),
      );
  if (anchorWeightSourceDay != null &&
      anchorWeightSourceDay.isBefore(firstLearningStartDate)) {
    return anchorWeightSourceDay;
  }
  return firstLearningStartDate;
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
  required List<_WeeklyLearnedWindow> windows,
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
        diaryDayKey(windowDay): windowDay,
  }.values.toList(growable: false);
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

List<double>? _resolveLearningIntake({
  required List<DateTime> days,
  required Map<String, List<CalorieEntry>> entriesByDay,
  required CalorieGoalSettings settings,
}) {
  final intakeKcalByDay = <double>[];
  for (final day in days) {
    final dayEntries = entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
    if (dayEntries.isNotEmpty) {
      intakeKcalByDay.add(
        dayEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.totalKcal,
        ),
      );
      continue;
    }
    if (!settings.isSkippedIntakeDay(day) || intakeKcalByDay.isEmpty) {
      return null;
    }
    intakeKcalByDay.add(CalorieDomainMath.average(intakeKcalByDay));
  }
  return intakeKcalByDay;
}

List<CalorieWeeklyCheckInWeightPoint> _weeklyWeightPoints({
  required CalorieGoalSettings settings,
  required CalorieGoalHistoryEntry anchorEntry,
  required _WeeklyLearnedWindow window,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  final weightPointsByDay = <String, CalorieWeeklyCheckInWeightPoint>{};
  for (
    var day = window.learningStartDate;
    !day.isAfter(window.windowEndDate);
    day = nextDiaryDay(day)
  ) {
    _putWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: day,
      dayIndex: window.dayIndexFor(day),
      weightKg:
          manualWeightByDay[diaryDayKey(day)] ??
          representativeWeightByDay[diaryDayKey(day)],
    );
  }

  if (CalorieWeeklyWindowResolver.isFirstWindowStart(
    anchorEntry: anchorEntry,
    windowStartDate: window.windowStartDate,
  )) {
    final anchorWeightSourceDay =
        CalorieWeeklyWindowResolver.anchorWeightSourceDayForWindow(
          anchorEntry: anchorEntry,
          windowStartDate: window.windowStartDate,
        );
    final anchorWeightKey = anchorWeightSourceDay == null
        ? null
        : diaryDayKey(anchorWeightSourceDay);
    _putWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: window.windowStartDate,
      dayIndex: window.dayIndexFor(window.windowStartDate),
      weightKg:
          (anchorWeightKey == null
              ? null
              : manualWeightByDay[anchorWeightKey] ??
                    representativeWeightByDay[anchorWeightKey]) ??
          anchorEntry.calculatorProfile?.weightKg ??
          settings.calculatorProfile?.weightKg,
    );
  }

  final previousBoundaryDay = window.previousBoundaryDay;
  if (previousBoundaryDay != null) {
    _putBoundaryWeightPoint(
      pointsByDay: weightPointsByDay,
      displayDay: window.windowStartDate,
      dayIndex: window.dayIndexFor(window.windowStartDate),
      sourceDay: previousBoundaryDay,
      manualWeightByDay: manualWeightByDay,
      representativeWeightByDay: representativeWeightByDay,
    );
  }
  _putBoundaryWeightPoint(
    pointsByDay: weightPointsByDay,
    displayDay: window.windowEndDate,
    dayIndex: window.dayIndexFor(window.nextBoundaryDay),
    sourceDay: window.nextBoundaryDay,
    manualWeightByDay: manualWeightByDay,
    representativeWeightByDay: representativeWeightByDay,
  );

  final weightPoints = weightPointsByDay.values.toList(growable: false)
    ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
  return weightPoints;
}

void _putBoundaryWeightPoint({
  required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
  required DateTime displayDay,
  required int dayIndex,
  required DateTime sourceDay,
  required Map<String, double> manualWeightByDay,
  required Map<String, double> representativeWeightByDay,
}) {
  _putWeightPoint(
    pointsByDay: pointsByDay,
    displayDay: displayDay,
    dayIndex: dayIndex,
    weightKg:
        manualWeightByDay[diaryDayKey(sourceDay)] ??
        representativeWeightByDay[diaryDayKey(sourceDay)],
  );
}

void _putWeightPoint({
  required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
  required DateTime displayDay,
  required int dayIndex,
  required double? weightKg,
}) {
  if (weightKg == null) {
    return;
  }
  final dayKey = diaryDayKey(displayDay);
  if (pointsByDay.containsKey(dayKey)) {
    return;
  }
  pointsByDay[dayKey] = CalorieWeeklyCheckInWeightPoint(
    dayIndex: dayIndex,
    weightKg: weightKg,
  );
}

double _learnedTdeeSeed({
  required CalorieGoalSettings settings,
  required DateTime day,
  required double fallbackGoalKcal,
}) {
  final calculatorProfile = CalorieWeeklyWindowResolver.calculatorProfileForDay(
    settings: settings,
    day: day,
  );
  if (calculatorProfile != null) {
    return CalorieGoalCalculator.calculate(calculatorProfile).tdeeKcal;
  }
  return fallbackGoalKcal;
}

List<int> _activityKcalByDay({
  required List<DateTime> days,
  required Map<String, int> activeKcalByDay,
}) {
  return days
      .map((day) => activeKcalByDay[diaryDayKey(day)] ?? 0)
      .toList(growable: false);
}

Map<String, double> _manualWeightByDay(
  List<ManualHealthWeightEntry> manualEntries,
) {
  return <String, double>{
    for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
  };
}

Map<String, double> _representativeWeightByDay(
  List<HealthWeightSample> samples,
) {
  final samplesByDay = <String, List<double>>{};
  for (final sample in samples) {
    final key = diaryDayKey(sample.recordedAt);
    samplesByDay.putIfAbsent(key, () => <double>[]).add(sample.weightKg);
  }
  return {
    for (final entry in samplesByDay.entries)
      entry.key: CalorieDomainMath.median(entry.value),
  };
}

CalorieGoalMode _goalModeForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalMode ??
      settings.calculatorProfile?.goalMode ??
      CalorieGoalMode.maintain;
}

double _goalSpeedForDay({
  required CalorieGoalSettings settings,
  required DateTime day,
}) {
  return settings.goalEntryForDay(day)?.calculatorProfile?.goalSpeedKgPerWeek ??
      settings.calculatorProfile?.goalSpeedKgPerWeek ??
      0.0;
}

class _LearnedTdeeDayContext {
  const _LearnedTdeeDayContext({
    required this.day,
    required this.storedGoalKcal,
    required this.anchorEntry,
    required this.windows,
    required this.firstLearningStartDate,
    required this.weightStartDate,
  });

  final DateTime day;
  final double storedGoalKcal;
  final CalorieGoalHistoryEntry anchorEntry;
  final List<_WeeklyLearnedWindow> windows;
  final DateTime firstLearningStartDate;
  final DateTime weightStartDate;

  _WeeklyLearnedWindow get lastWindow => windows.last;
}

class _WeeklyLearnedWindow {
  const _WeeklyLearnedWindow({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    required this.learningStartDate,
    required this.windowDays,
    required this.nextBoundaryDay,
    required this.previousBoundaryDay,
  });

  final DateTime windowStartDate;
  final DateTime windowEndDate;
  final DateTime dueDate;
  final DateTime learningStartDate;
  final List<DateTime> windowDays;
  final DateTime nextBoundaryDay;
  final DateTime? previousBoundaryDay;

  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}
