import 'package:yamt/features/calories/application/'
    'daily_learned_tdee_models.dart';
import 'package:yamt/features/calories/domain/calorie_activity_adjustment.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart'
    show CalorieGoalMode;
import 'package:yamt/features/calories/domain/calorie_carryover_history.dart';
import 'package:yamt/features/calories/domain/calorie_domain_math.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_window_resolver.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

/// Context for a single day's learned TDEE resolution.
class DailyLearnedTdeeDayContext {
  /// Creates learned TDEE day context.
  const DailyLearnedTdeeDayContext({
    required this.day,
    required this.storedGoalKcal,
    required this.anchorEntry,
    required this.windows,
    required this.firstLearningStartDate,
    required this.weightStartDate,
  });

  /// The target diary day.
  final DateTime day;

  /// The stored goal in kcal.
  final double storedGoalKcal;

  /// The associated cycle anchor entry.
  final CalorieGoalHistoryEntry anchorEntry;

  /// List of resolved weekly windows leading to this day.
  final List<WeeklyLearnedWindow> windows;

  /// Start date of learning for the first window.
  final DateTime firstLearningStartDate;

  /// Start date for loading health weights.
  final DateTime weightStartDate;

  /// Gets the last window in this context.
  WeeklyLearnedWindow get lastWindow => windows.last;
}

/// A weekly window evaluated for daily learned goals.
class WeeklyLearnedWindow {
  /// Creates weekly learned window.
  const WeeklyLearnedWindow({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    required this.learningStartDate,
    required this.windowDays,
    required this.nextBoundaryDay,
    required this.previousBoundaryDay,
  });

  /// Start date of the window.
  final DateTime windowStartDate;

  /// End date of the window.
  final DateTime windowEndDate;

  /// Due date of the window.
  final DateTime dueDate;

  /// Learning range start date.
  final DateTime learningStartDate;

  /// Days included in the window.
  final List<DateTime> windowDays;

  /// Day index boundary for the next check-in.
  final DateTime nextBoundaryDay;

  /// Optional previous window boundary day.
  final DateTime? previousBoundaryDay;

  /// Resolves the day index offset from the learning start date.
  int dayIndexFor(DateTime day) {
    return normalizeDiaryDay(day).difference(learningStartDate).inDays;
  }
}

/// Handles business logic and math calculations for daily learned TDEE goals.
abstract final class DailyLearnedTdeeResolver {
  /// Resolves daily learned TDEE contexts for a list of requests.
  static DailyLearnedTdeeDayContext? learnedTdeeDayContext({
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

    final windows = weeklyLearnedWindowsForDay(
      anchorEntry: anchorEntry,
      day: learningReferenceDay,
    );
    if (windows.isEmpty) {
      return null;
    }

    final firstLearningStartDate = learningStartDateForWindow(
      anchorEntry: anchorEntry,
      windowEndDate: windows.first.windowEndDate,
    );
    return DailyLearnedTdeeDayContext(
      day: normalizedDay,
      storedGoalKcal: dayRequest.storedGoalKcal,
      anchorEntry: anchorEntry,
      windows: windows,
      firstLearningStartDate: firstLearningStartDate,
      weightStartDate: weightStartDateForLearning(
        anchorEntry: anchorEntry,
        firstLearningStartDate: firstLearningStartDate,
      ),
    );
  }

  /// Resolves learned TDEE goal data using loaded inputs.
  static DailyLearnedTdeeGoalData? resolveLearnedTdeeGoalFromLoadedData({
    required DailyLearnedTdeeDayContext context,
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
    var previousLearnedTdeeKcal = learnedTdeeSeed(
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
      final intakeKcalByDay = resolveLearningIntake(
        days: learningDays,
        entriesByDay: entriesByDay,
        settings: settings,
      );
      if (intakeKcalByDay == null) {
        return latest;
      }

      final weightPoints = weeklyWeightPoints(
        settings: settings,
        anchorEntry: context.anchorEntry,
        window: window,
        manualWeightByDay: manualWeightByDay,
        representativeWeightByDay: representativeWeightByDay,
      );
      if (weightPoints.length < 2) {
        return latest;
      }

      final goalMode = goalModeForDay(
        settings: settings,
        day: window.windowEndDate,
      );
      final goalSpeedKgPerWeek = goalMode == CalorieGoalMode.maintain
          ? 0.0
          : goalSpeedForDay(settings: settings, day: window.windowEndDate);
      final calculation = CalorieWeeklyCheckInCalculator.calculateLearnedGoal(
        previousGoalKcal: previousGoalKcal,
        previousLearnedTdeeKcal: previousLearnedTdeeKcal,
        goalSpeedKgPerWeek: goalSpeedKgPerWeek,
        isLosing: goalMode == CalorieGoalMode.lose,
        isGaining: goalMode == CalorieGoalMode.gain,
        intakeKcalByDay: intakeKcalByDay,
        rawActivityKcalByDay: activityKcalByDay(
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

  /// Finds earliest day in a collection.
  static DateTime earliestDay(Iterable<DateTime> days) {
    return days.reduce((current, day) => day.isBefore(current) ? day : current);
  }

  /// Finds latest day in a collection.
  static DateTime latestDay(Iterable<DateTime> days) {
    return days.reduce((current, day) => day.isAfter(current) ? day : current);
  }

  /// Filters unique windows from context list.
  static List<WeeklyLearnedWindow> uniqueWindows(
    List<DailyLearnedTdeeDayContext> contexts,
  ) {
    final windowsByKey = <String, WeeklyLearnedWindow>{};
    for (final context in contexts) {
      for (final window in context.windows) {
        windowsByKey[_windowKey(window)] = window;
      }
    }
    return List<WeeklyLearnedWindow>.unmodifiable(windowsByKey.values);
  }

  static String _windowKey(WeeklyLearnedWindow window) {
    return '${diaryDayKey(window.windowStartDate)}:'
        '${diaryDayKey(window.windowEndDate)}';
  }

  static bool _hasEntriesForAnyDay({
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

  /// Resolves all weekly learned windows leading up to [day].
  static List<WeeklyLearnedWindow> weeklyLearnedWindowsForDay({
    required CalorieGoalHistoryEntry anchorEntry,
    required DateTime day,
  }) {
    final windows = <WeeklyLearnedWindow>[];
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
      final learningStartDate = learningStartDateForWindow(
        anchorEntry: anchorEntry,
        windowEndDate: windowEndDate,
      );
      windows.add(
        WeeklyLearnedWindow(
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
    return List<WeeklyLearnedWindow>.unmodifiable(windows);
  }

  /// Resolves the learning start date for a window.
  static DateTime learningStartDateForWindow({
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

  /// Resolves weight start date for learning.
  static DateTime weightStartDateForLearning({
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

  /// Resolves logged and interpolated intake across learning range.
  static List<double>? resolveLearningIntake({
    required List<DateTime> days,
    required Map<String, List<CalorieEntry>> entriesByDay,
    required CalorieGoalSettings settings,
  }) {
    final loggedVals = <double>[];
    final missingDays = <DateTime>[];

    for (final day in days) {
      final dayEntries =
          entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
      if (dayEntries.isNotEmpty) {
        loggedVals.add(
          dayEntries.fold<double>(
            0,
            (sum, entry) => sum + entry.totalKcal,
          ),
        );
      } else {
        missingDays.add(day);
      }
    }

    if (loggedVals.isEmpty && missingDays.isNotEmpty) {
      return null;
    }

    final averageLogged = loggedVals.isEmpty
        ? 0.0
        : CalorieDomainMath.average(loggedVals);
    final intakeKcalByDay = <double>[];

    for (final day in days) {
      final dayEntries =
          entriesByDay[diaryDayKey(day)] ?? const <CalorieEntry>[];
      if (dayEntries.isNotEmpty) {
        intakeKcalByDay.add(
          dayEntries.fold<double>(
            0,
            (sum, entry) => sum + entry.totalKcal,
          ),
        );
      } else {
        if (!settings.isSkippedIntakeDay(day)) {
          return null;
        }
        intakeKcalByDay.add(averageLogged);
      }
    }
    return intakeKcalByDay;
  }

  /// Resolves weight points for a window.
  static List<CalorieWeeklyCheckInWeightPoint> weeklyWeightPoints({
    required CalorieGoalSettings settings,
    required CalorieGoalHistoryEntry anchorEntry,
    required WeeklyLearnedWindow window,
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
      decoupleWeightPointKey: true,
    );

    final weightPoints = weightPointsByDay.values.toList(growable: false)
      ..sort((left, right) => left.dayIndex.compareTo(right.dayIndex));
    return weightPoints;
  }

  static void _putBoundaryWeightPoint({
    required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
    required DateTime displayDay,
    required int dayIndex,
    required DateTime sourceDay,
    required Map<String, double> manualWeightByDay,
    required Map<String, double> representativeWeightByDay,
    bool decoupleWeightPointKey = false,
  }) {
    _putWeightPoint(
      pointsByDay: pointsByDay,
      displayDay: displayDay,
      dayIndex: dayIndex,
      weightKg:
          manualWeightByDay[diaryDayKey(sourceDay)] ??
          representativeWeightByDay[diaryDayKey(sourceDay)],
      weightPointKey: decoupleWeightPointKey ? diaryDayKey(sourceDay) : null,
    );
  }

  static void _putWeightPoint({
    required Map<String, CalorieWeeklyCheckInWeightPoint> pointsByDay,
    required DateTime displayDay,
    required int dayIndex,
    required double? weightKg,
    String? weightPointKey,
  }) {
    if (weightKg == null) {
      return;
    }
    final dayKey = diaryDayKey(displayDay);
    final ptKey = weightPointKey ?? dayKey;
    if (!pointsByDay.containsKey(ptKey)) {
      pointsByDay[ptKey] = CalorieWeeklyCheckInWeightPoint(
        dayIndex: dayIndex,
        weightKg: weightKg,
      );
    }
  }

  /// Calculates the expected TDEE seed.
  static double learnedTdeeSeed({
    required CalorieGoalSettings settings,
    required DateTime day,
    required double fallbackGoalKcal,
  }) {
    final calculatorProfile =
        CalorieWeeklyWindowResolver.calculatorProfileForDay(
          settings: settings,
          day: day,
        );
    if (calculatorProfile != null) {
      final result = CalorieGoalCalculator.calculate(calculatorProfile);
      if (settings.isActivityTrackingActiveForDay(day)) {
        return result.tdeeKcal -
            (result.expectedActivityKcal * importedActivityCorrectionFactor);
      }
      return result.tdeeKcal;
    }
    return fallbackGoalKcal;
  }

  /// Extracts activity values for days.
  static List<int> activityKcalByDay({
    required List<DateTime> days,
    required Map<String, int> activeKcalByDay,
  }) {
    return days
        .map((day) => activeKcalByDay[diaryDayKey(day)] ?? 0)
        .toList(growable: false);
  }

  /// Resolves the goal mode for a day.
  static CalorieGoalMode goalModeForDay({
    required CalorieGoalSettings settings,
    required DateTime day,
  }) {
    return settings.goalEntryForDay(day)?.calculatorProfile?.goalMode ??
        settings.calculatorProfile?.goalMode ??
        CalorieGoalMode.maintain;
  }

  /// Resolves goal speed for a day.
  static double goalSpeedForDay({
    required CalorieGoalSettings settings,
    required DateTime day,
  }) {
    return settings
            .goalEntryForDay(day)
            ?.calculatorProfile
            ?.goalSpeedKgPerWeek ??
        settings.calculatorProfile?.goalSpeedKgPerWeek ??
        0.0;
  }

  /// Formats manual weights.
  static Map<String, double> manualWeightByDay(
    List<ManualHealthWeightEntry> manualEntries,
  ) {
    return <String, double>{
      for (final entry in manualEntries) diaryDayKey(entry.day): entry.weightKg,
    };
  }

  /// Formats representative weights with median filtering.
  static Map<String, double> representativeWeightByDay(
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
}
