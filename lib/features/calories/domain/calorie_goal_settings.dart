import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_settings.g.dart';

/// The default daily calorie goal kcal.
const defaultDailyCalorieGoalKcal = 2500.0;

/// The current calorie math data version.
const currentCalorieMathVersion = 2;

/// Legacy version used when stored settings have no version.
const legacyCalorieMathVersion = 1;

const _keepValue = Object();

/// Defines calorie goal source.
@JsonEnum(valueField: 'jsonValue')
enum CalorieGoalSource {
  /// Manual.
  manual('manual'),

  /// Calculator.
  calculator('calculator'),

  /// Weekly check in.
  weeklyCheckIn('weekly_checkin')
  ;

  const CalorieGoalSource(this.jsonValue);

  /// The json value.
  final String jsonValue;
}

/// Defines calorie goal weekly check in snapshot.
@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieGoalWeeklyCheckInSnapshot {
  /// The calorie goal weekly check in snapshot.
  const CalorieGoalWeeklyCheckInSnapshot({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.trendWeightChangePerDay,
    required this.calculatedTrueTdeeKcal,
    required this.averageActiveKcal,
    required this.lowConfidence,
  });

  /// Creates a [CalorieGoalWeeklyCheckInSnapshot] for from json.
  factory CalorieGoalWeeklyCheckInSnapshot.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalWeeklyCheckInSnapshotFromJson(json);
  }

  /// The window start date.
  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;

  /// The window end date.
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;

  /// The trend weight change per day.
  @FlexibleDoubleConverter()
  final double trendWeightChangePerDay;

  /// The calculated true tdee kcal.
  @FlexibleDoubleConverter()
  final double calculatedTrueTdeeKcal;

  /// The average active kcal.
  @FlexibleDoubleConverter()
  final double averageActiveKcal;

  /// The low confidence.
  final bool lowConfidence;

  /// To json.
  Map<String, dynamic> toJson() {
    return _$CalorieGoalWeeklyCheckInSnapshotToJson(this);
  }
}

/// Defines pending calorie goal weekly check in.
@JsonSerializable(fieldRename: FieldRename.snake)
class PendingCalorieGoalWeeklyCheckIn {
  /// The pending calorie goal weekly check in.
  const PendingCalorieGoalWeeklyCheckIn({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    this.dismissedAt,
  });

  /// Creates a [PendingCalorieGoalWeeklyCheckIn] for from json.
  factory PendingCalorieGoalWeeklyCheckIn.fromJson(Map<String, dynamic> json) {
    return _$PendingCalorieGoalWeeklyCheckInFromJson(json);
  }

  /// The window start date.
  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;

  /// The window end date.
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;

  /// The due date.
  @FlexibleDateTimeConverter()
  final DateTime dueDate;

  /// The dismissed at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? dismissedAt;

  /// Whether dismissed.
  bool get isDismissed => dismissedAt != null;

  /// The window key.
  String get windowKey {
    return '${diaryDayKey(windowStartDate)}:${diaryDayKey(windowEndDate)}';
  }

  /// Copy with.
  PendingCalorieGoalWeeklyCheckIn copyWith({Object? dismissedAt = _keepValue}) {
    return PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: dueDate,
      dismissedAt: dismissedAt == _keepValue
          ? this.dismissedAt
          : dismissedAt as DateTime?,
    );
  }

  /// To json.
  Map<String, dynamic> toJson() {
    return _$PendingCalorieGoalWeeklyCheckInToJson(this);
  }
}

/// Defines calorie goal history entry.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalHistoryEntry {
  /// The calorie goal history entry.
  const CalorieGoalHistoryEntry({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.effectiveDate,
    required this.changedAt,
    this.expectedActivityKcal,
    this.countingStartDate,
    this.source = CalorieGoalSource.manual,
    this.weeklyCheckInSnapshot,
  });

  /// Creates a [CalorieGoalHistoryEntry] for from json.
  factory CalorieGoalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalHistoryEntryFromJson(json);
  }

  /// The daily kcal goal.
  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// Expected daily activity kcal for this goal snapshot.
  @NullableFlexibleDoubleConverter()
  final double? expectedActivityKcal;

  /// The effective date.
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;

  /// The changed at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? changedAt;

  /// The official counting start date for Burn Week and weekly check-ins.
  @NullableFlexibleDateTimeConverter()
  final DateTime? countingStartDate;

  @JsonKey(
    defaultValue: CalorieGoalSource.manual,
    unknownEnumValue: CalorieGoalSource.manual,
  )
  /// The source.
  final CalorieGoalSource source;

  /// The weekly check in snapshot.
  final CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot;

  /// Whether goal.
  bool get hasGoal => dailyKcalGoal != null;

  /// The effective changed at.
  DateTime get effectiveChangedAt => changedAt ?? effectiveDate;

  /// The effective counting start date.
  DateTime get effectiveCountingStartDate {
    return _resolveNormalizedCountingStartDate(
      effectiveDate: effectiveDate,
      countingStartDate: countingStartDate,
    );
  }

  /// Whether weekly check in.
  bool get isWeeklyCheckIn => source == CalorieGoalSource.weeklyCheckIn;

  /// Whether learned tdee.
  bool get hasLearnedTdee => weeklyCheckInSnapshot != null;

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieGoalHistoryEntryToJson(this);
}

/// Defines calorie goal settings.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalSettings {
  /// The calorie goal settings.
  const CalorieGoalSettings({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.updatedAt,
    required this.goalHistory,
    required this.pendingWeeklyCheckIn,
    required this.skippedIntakeDayKeys,
    required this.calorieMathVersion,
    this.expectedActivityKcal,
    this.activityTrackingStartDate,
  });

  /// Creates a [CalorieGoalSettings] for from json.
  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  /// Creates empty calorie goal settings.
  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      calorieMathVersion = currentCalorieMathVersion,
      expectedActivityKcal = null,
      activityTrackingStartDate = null,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[],
      pendingWeeklyCheckIn = null,
      skippedIntakeDayKeys = const <String>[];

  /// Creates a [CalorieGoalSettings] for single.
  factory CalorieGoalSettings.single({
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime effectiveDate,
    double? expectedActivityKcal,
    DateTime? activityTrackingStartDate,
    DateTime? countingStartDate,
    DateTime? updatedAt,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
  }) {
    final normalizedCountingStartDate = _resolveNormalizedCountingStartDate(
      effectiveDate: effectiveDate,
      countingStartDate: countingStartDate,
    );
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: currentCalorieMathVersion,
      expectedActivityKcal: expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate == null
          ? null
          : normalizeDiaryDay(activityTrackingStartDate),
      updatedAt: updatedAt ?? effectiveDate,
      goalHistory: <CalorieGoalHistoryEntry>[
        CalorieGoalHistoryEntry(
          dailyKcalGoal: dailyKcalGoal,
          calculatorProfile: calculatorProfile,
          expectedActivityKcal: expectedActivityKcal,
          effectiveDate: normalizeDiaryDay(effectiveDate),
          changedAt: effectiveDate,
          countingStartDate: normalizedCountingStartDate,
          source: source,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        ),
      ],
      pendingWeeklyCheckIn: null,
      skippedIntakeDayKeys: const <String>[],
    );
  }

  /// The daily kcal goal.
  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// The calorie math data version.
  @JsonKey(defaultValue: legacyCalorieMathVersion)
  final int calorieMathVersion;

  /// Expected daily activity kcal from PAL or learned activity baseline.
  @NullableFlexibleDoubleConverter()
  final double? expectedActivityKcal;

  /// First day where health activity tracking should affect calorie math.
  @NullableFlexibleDateTimeConverter()
  final DateTime? activityTrackingStartDate;

  /// The updated at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;

  /// The goal history.
  @JsonKey(defaultValue: <CalorieGoalHistoryEntry>[])
  final List<CalorieGoalHistoryEntry> goalHistory;

  /// The pending weekly check in.
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;

  /// The skipped intake day keys.
  @JsonKey(defaultValue: <String>[])
  final List<String> skippedIntakeDayKeys;

  /// Whether goal.
  bool get hasGoal => dailyKcalGoal != null;

  /// Whether learned tdee.
  bool get hasLearnedTdee => latestLearnedTdeeKcal != null;

  /// The sorted goal history.
  List<CalorieGoalHistoryEntry> get sortedGoalHistory {
    final entries = List<CalorieGoalHistoryEntry>.from(goalHistory)
      ..sort((left, right) {
        final byDay = left.effectiveDate.compareTo(right.effectiveDate);
        if (byDay != 0) {
          return byDay;
        }
        return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
      });
    return List<CalorieGoalHistoryEntry>.unmodifiable(entries);
  }

  /// The latest goal entry.
  CalorieGoalHistoryEntry? get latestGoalEntry {
    for (final entry in sortedGoalHistory.reversed) {
      if (entry.hasGoal && !entry.isWeeklyCheckIn) {
        return entry;
      }
    }
    return null;
  }

  /// The latest learned tdee entry.
  CalorieGoalHistoryEntry? get latestLearnedTdeeEntry {
    for (final entry in sortedGoalHistory.reversed) {
      if (entry.hasLearnedTdee) {
        return entry;
      }
    }
    return null;
  }

  /// The latest learned tdee kcal.
  double? get latestLearnedTdeeKcal {
    return latestLearnedTdeeEntry
        ?.weeklyCheckInSnapshot
        ?.calculatedTrueTdeeKcal;
  }

  /// The latest learned tdee changed at.
  DateTime? get latestLearnedTdeeChangedAt {
    return latestLearnedTdeeEntry?.effectiveChangedAt;
  }

  /// Learned TDEE entry effective for the given day.
  CalorieGoalHistoryEntry? learnedTdeeEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? resolvedEntry;

    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.hasLearnedTdee) {
        resolvedEntry = entry;
      }
    }

    return resolvedEntry;
  }

  /// Cycle anchor entry for day.
  CalorieGoalHistoryEntry? cycleAnchorEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? anchorEntry;

    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.effectiveCountingStartDate.isAfter(normalizedDay)) {
        continue;
      }
      if (!entry.hasGoal || entry.isWeeklyCheckIn) {
        continue;
      }
      anchorEntry = entry;
    }

    return anchorEntry;
  }

  /// Goal entry for day.
  CalorieGoalHistoryEntry? goalEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    CalorieGoalHistoryEntry? resolvedEntry;

    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        break;
      }
      if (entry.isWeeklyCheckIn) {
        continue;
      }
      resolvedEntry = entry;
    }

    return resolvedEntry;
  }

  /// Active goal entry for day.
  CalorieGoalHistoryEntry? activeGoalEntryForDay(DateTime day) {
    final entry = goalEntryForDay(day);
    if (entry?.hasGoal != true) {
      return null;
    }
    return entry;
  }

  /// Goal entry that is already counted for the given day.
  CalorieGoalHistoryEntry? countingGoalEntryForDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    final entry = goalEntryForDay(normalizedDay);
    if (entry?.hasGoal != true) {
      return null;
    }
    if (entry!.effectiveCountingStartDate.isAfter(normalizedDay)) {
      return null;
    }
    return entry;
  }

  /// Whether the day is a consequence-free practice day for an active goal.
  bool isGoalPracticeDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    final entry = goalEntryForDay(normalizedDay);
    if (entry?.hasGoal != true) {
      return nextGoalStartAfterDay(normalizedDay) != null;
    }
    return entry!.effectiveCountingStartDate.isAfter(normalizedDay);
  }

  /// Next official counting start after day.
  DateTime? nextGoalStartAfterDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    for (final entry in sortedGoalHistory) {
      if (!entry.hasGoal || entry.isWeeklyCheckIn) {
        continue;
      }
      final countingStartDate = entry.effectiveCountingStartDate;
      if (countingStartDate.isAfter(normalizedDay)) {
        return countingStartDate;
      }
    }
    return null;
  }

  /// Goal kcal for day.
  double goalKcalForDay(DateTime day) {
    final entry = goalEntryForDay(day);
    if (entry != null) {
      return entry.dailyKcalGoal ?? 0.0;
    }
    return nextGoalStartAfterDay(day) == null
        ? defaultDailyCalorieGoalKcal
        : 0.0;
  }

  /// Expected activity kcal for day.
  double? expectedActivityKcalForDay(DateTime day) {
    return goalEntryForDay(day)?.expectedActivityKcal ?? expectedActivityKcal;
  }

  /// Whether health activity should be counted for day.
  bool isActivityTrackingActiveForDay(DateTime day) {
    final startDate = activityTrackingStartDate;
    if (startDate == null) {
      return false;
    }
    return !normalizeDiaryDay(day).isBefore(normalizeDiaryDay(startDate));
  }

  /// Marks the first activity tracking day without moving it forward.
  CalorieGoalSettings markActivityTrackingStarted(DateTime startedAt) {
    final normalizedStartedAt = normalizeDiaryDay(startedAt);
    final currentStartDate = activityTrackingStartDate;
    if (currentStartDate != null &&
        !normalizeDiaryDay(currentStartDate).isAfter(normalizedStartedAt)) {
      return this;
    }
    return copyWith(
      activityTrackingStartDate: normalizedStartedAt,
      updatedAt: startedAt,
    );
  }

  /// Balance start for window.
  DateTime balanceStartForWindow(Iterable<DateTime> days) {
    final normalizedDays = days.map(normalizeDiaryDay).toList(growable: false)
      ..sort();
    if (normalizedDays.isEmpty) {
      return normalizeDiaryDay(DateTime.now());
    }

    final windowStart = normalizedDays.first;
    final windowEnd = normalizedDays.last;
    DateTime? latestChangeInWindow;

    for (final entry in sortedGoalHistory) {
      if (entry.effectiveDate.isBefore(windowStart)) {
        continue;
      }
      if (entry.effectiveDate.isAfter(windowEnd)) {
        break;
      }
      if (entry.isWeeklyCheckIn) {
        continue;
      }
      final countingStartDate = entry.effectiveCountingStartDate;
      if (countingStartDate.isBefore(windowStart) ||
          countingStartDate.isAfter(windowEnd)) {
        continue;
      }
      latestChangeInWindow = countingStartDate;
    }

    if (latestChangeInWindow != null) {
      return latestChangeInWindow;
    }

    final activeEntryAtWindowEnd = countingGoalEntryForDay(windowEnd);
    if (activeEntryAtWindowEnd?.hasGoal == true) {
      return windowStart;
    }

    return nextGoalStartAfterDay(windowEnd) ?? windowStart;
  }

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

  /// Without latest goal entry.
  CalorieGoalSettings withoutLatestGoalEntry() {
    final history = sortedGoalHistory;
    final latestGoalIndex = history.lastIndexWhere((entry) => entry.hasGoal);
    if (latestGoalIndex < 0) {
      return this;
    }

    final nextHistory = List<CalorieGoalHistoryEntry>.from(history)
      ..removeAt(latestGoalIndex);
    final previousGoalIndex = nextHistory.lastIndexWhere(
      (entry) => entry.hasGoal,
    );
    final previousGoal = previousGoalIndex >= 0
        ? nextHistory[previousGoalIndex]
        : null;

    return CalorieGoalSettings(
      dailyKcalGoal: previousGoal?.dailyKcalGoal,
      calculatorProfile: previousGoal?.calculatorProfile,
      calorieMathVersion: currentCalorieMathVersion,
      expectedActivityKcal: previousGoal?.expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate,
      updatedAt: updatedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
    );
  }

  /// Apply goal change.
  CalorieGoalSettings applyGoalChange({
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    double? expectedActivityKcal,
    DateTime? countingStartDate,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    bool replaceFutureHistory = false,
  }) {
    final effectiveDate = normalizeDiaryDay(changedAt);
    final normalizedCountingStartDate = _resolveNormalizedCountingStartDate(
      effectiveDate: changedAt,
      countingStartDate: countingStartDate,
    );
    final nextHistory =
        <CalorieGoalHistoryEntry>[
          for (final entry in sortedGoalHistory)
            if (_shouldKeepGoalHistoryEntry(
              entry: entry,
              effectiveDate: effectiveDate,
              source: source,
              weeklyCheckInSnapshot: weeklyCheckInSnapshot,
              replaceFutureHistory: replaceFutureHistory,
            ))
              entry,
          CalorieGoalHistoryEntry(
            dailyKcalGoal: dailyKcalGoal,
            calculatorProfile: calculatorProfile,
            expectedActivityKcal: expectedActivityKcal,
            effectiveDate: effectiveDate,
            changedAt: changedAt,
            countingStartDate: normalizedCountingStartDate,
            source: source,
            weeklyCheckInSnapshot: weeklyCheckInSnapshot,
          ),
        ]..sort((left, right) {
          final byDay = left.effectiveDate.compareTo(right.effectiveDate);
          if (byDay != 0) {
            return byDay;
          }
          return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
        });

    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: currentCalorieMathVersion,
      expectedActivityKcal: expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate,
      updatedAt: changedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      pendingWeeklyCheckIn: null,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
    );
  }

  /// Is skipped intake day.
  bool isSkippedIntakeDay(DateTime day) {
    return skippedIntakeDayKeys.contains(_dayKey(day));
  }

  /// Copy with pending weekly check in.
  CalorieGoalSettings copyWithPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  ) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: calorieMathVersion,
      expectedActivityKcal: expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate,
      updatedAt: updatedAt,
      goalHistory: goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
    );
  }

  /// Dismiss pending weekly check in.
  CalorieGoalSettings dismissPendingWeeklyCheckIn(DateTime dismissedAt) {
    final pending = pendingWeeklyCheckIn;
    if (pending == null) {
      return this;
    }
    return copyWithPendingWeeklyCheckIn(
      pending.copyWith(dismissedAt: dismissedAt),
    );
  }

  /// Set skipped intake day.
  CalorieGoalSettings setSkippedIntakeDay({
    required DateTime day,
    required bool isSkipped,
  }) {
    final dayKey = _dayKey(day);
    final nextKeys = List<String>.from(skippedIntakeDayKeys);
    final containsKey = nextKeys.contains(dayKey);
    if (isSkipped && !containsKey) {
      nextKeys.add(dayKey);
    }
    if (!isSkipped && containsKey) {
      nextKeys.remove(dayKey);
    }
    nextKeys.sort();
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: calorieMathVersion,
      expectedActivityKcal: expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate,
      updatedAt: updatedAt,
      goalHistory: goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: List<String>.unmodifiable(nextKeys),
    );
  }

  /// Copy with.
  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    int? calorieMathVersion,
    double? expectedActivityKcal,
    DateTime? activityTrackingStartDate,
    DateTime? updatedAt,
    List<CalorieGoalHistoryEntry>? goalHistory,
    PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
    List<String>? skippedIntakeDayKeys,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      calorieMathVersion: calorieMathVersion ?? this.calorieMathVersion,
      expectedActivityKcal: expectedActivityKcal ?? this.expectedActivityKcal,
      activityTrackingStartDate: activityTrackingStartDate == null
          ? this.activityTrackingStartDate
          : normalizeDiaryDay(activityTrackingStartDate),
      updatedAt: updatedAt ?? this.updatedAt,
      goalHistory: goalHistory ?? this.goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn ?? this.pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys ?? this.skippedIntakeDayKeys,
    );
  }
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _shouldKeepGoalHistoryEntry({
  required CalorieGoalHistoryEntry entry,
  required DateTime effectiveDate,
  required CalorieGoalSource source,
  required CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
  required bool replaceFutureHistory,
}) {
  if (_isSameDay(entry.effectiveDate, effectiveDate)) {
    if (entry.isWeeklyCheckIn != (source == CalorieGoalSource.weeklyCheckIn)) {
      return true;
    }
    if (source == CalorieGoalSource.weeklyCheckIn &&
        entry.source == CalorieGoalSource.weeklyCheckIn &&
        weeklyCheckInSnapshot != null &&
        entry.weeklyCheckInSnapshot != null &&
        !_sameWeeklyCheckInWindow(
          entry.weeklyCheckInSnapshot!,
          weeklyCheckInSnapshot,
        )) {
      return true;
    }
    return false;
  }
  if (!replaceFutureHistory) {
    return true;
  }
  return entry.effectiveDate.isBefore(effectiveDate);
}

bool _sameWeeklyCheckInWindow(
  CalorieGoalWeeklyCheckInSnapshot left,
  CalorieGoalWeeklyCheckInSnapshot right,
) {
  return _isSameDay(left.windowStartDate, right.windowStartDate) &&
      _isSameDay(left.windowEndDate, right.windowEndDate);
}

DateTime _resolveNormalizedCountingStartDate({
  required DateTime effectiveDate,
  DateTime? countingStartDate,
}) {
  final normalizedEffectiveDate = normalizeDiaryDay(effectiveDate);
  final normalizedCountingStartDate = normalizeDiaryDay(
    countingStartDate ?? effectiveDate,
  );
  if (normalizedCountingStartDate.isBefore(normalizedEffectiveDate)) {
    return normalizedEffectiveDate;
  }
  return normalizedCountingStartDate;
}

String _dayKey(DateTime day) {
  return normalizeDiaryDay(day).toIso8601String().split('T').first;
}
