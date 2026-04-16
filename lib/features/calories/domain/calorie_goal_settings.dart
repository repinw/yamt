import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_settings.g.dart';

/// The default daily calorie goal kcal.
const defaultDailyCalorieGoalKcal = 2500.0;

/// The default eating window start minute of day.
const int defaultEatingWindowStartMinuteOfDay = 6 * 60;

/// The default eating window end minute of day.
const int defaultEatingWindowEndMinuteOfDay = 22 * 60;
const int _minutesPerDay = 24 * 60;
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

  /// The effective date.
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;

  /// The changed at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? changedAt;
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
    required this.eatingWindowStartMinuteOfDay,
    required this.eatingWindowEndMinuteOfDay,
    required this.pendingWeeklyCheckIn,
    required this.skippedIntakeDayKeys,
  });

  /// Creates a [CalorieGoalSettings] for from json.
  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  /// The eating window start minute of day.
  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[],
      eatingWindowStartMinuteOfDay = defaultEatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay = defaultEatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn = null,
      skippedIntakeDayKeys = const <String>[];

  /// Creates a [CalorieGoalSettings] for single.
  factory CalorieGoalSettings.single({
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime effectiveDate,
    DateTime? updatedAt,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    int eatingWindowStartMinuteOfDay = defaultEatingWindowStartMinuteOfDay,
    int eatingWindowEndMinuteOfDay = defaultEatingWindowEndMinuteOfDay,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      updatedAt: updatedAt ?? effectiveDate,
      goalHistory: <CalorieGoalHistoryEntry>[
        CalorieGoalHistoryEntry(
          dailyKcalGoal: dailyKcalGoal,
          calculatorProfile: calculatorProfile,
          effectiveDate: normalizeDiaryDay(effectiveDate),
          changedAt: effectiveDate,
          source: source,
          weeklyCheckInSnapshot: weeklyCheckInSnapshot,
        ),
      ],
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn: null,
      skippedIntakeDayKeys: const <String>[],
    );
  }

  /// The daily kcal goal.
  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// The updated at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;

  /// The goal history.
  @JsonKey(defaultValue: <CalorieGoalHistoryEntry>[])
  final List<CalorieGoalHistoryEntry> goalHistory;

  /// The eating window start minute of day.
  @JsonKey(defaultValue: defaultEatingWindowStartMinuteOfDay)
  final int eatingWindowStartMinuteOfDay;

  /// The eating window end minute of day.
  @JsonKey(defaultValue: defaultEatingWindowEndMinuteOfDay)
  final int eatingWindowEndMinuteOfDay;

  /// The pending weekly check in.
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;

  /// The skipped intake day keys.
  @JsonKey(defaultValue: <String>[])
  final List<String> skippedIntakeDayKeys;

  /// Whether goal.
  bool get hasGoal => dailyKcalGoal != null;

  /// Whether calculator profile.
  bool get hasCalculatorProfile => calculatorProfile != null;

  /// Whether learned tdee.
  bool get hasLearnedTdee => latestLearnedTdeeKcal != null;

  /// The normalized eating window start minute of day.
  int get normalizedEatingWindowStartMinuteOfDay {
    return _resolveEatingWindowMinutes(
      startMinuteOfDay: eatingWindowStartMinuteOfDay,
      endMinuteOfDay: eatingWindowEndMinuteOfDay,
    ).startMinuteOfDay;
  }

  /// The normalized eating window end minute of day.
  int get normalizedEatingWindowEndMinuteOfDay {
    return _resolveEatingWindowMinutes(
      startMinuteOfDay: eatingWindowStartMinuteOfDay,
      endMinuteOfDay: eatingWindowEndMinuteOfDay,
    ).endMinuteOfDay;
  }

  /// Eating window start for day.
  DateTime eatingWindowStartForDay(DateTime day) {
    return _dateTimeForMinuteOfDay(
      day: day,
      minuteOfDay: normalizedEatingWindowStartMinuteOfDay,
    );
  }

  /// Eating window end for day.
  DateTime eatingWindowEndForDay(DateTime day) {
    return _dateTimeForMinuteOfDay(
      day: day,
      minuteOfDay: normalizedEatingWindowEndMinuteOfDay,
    );
  }

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

  /// The skipped intake days.
  Iterable<DateTime> get skippedIntakeDays sync* {
    for (final key in skippedIntakeDayKeys) {
      final parsed = _dateFromDayKeyOrNull(key);
      if (parsed != null) {
        yield parsed;
      }
    }
  }

  /// The latest goal entry.
  CalorieGoalHistoryEntry? get latestGoalEntry {
    for (final entry in sortedGoalHistory.reversed) {
      if (entry.hasGoal) {
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
      resolvedEntry = entry;
    }

    return resolvedEntry;
  }

  /// Next goal start after day.
  DateTime? nextGoalStartAfterDay(DateTime day) {
    final normalizedDay = normalizeDiaryDay(day);
    for (final entry in sortedGoalHistory) {
      if (!entry.hasGoal) {
        continue;
      }
      if (entry.effectiveDate.isAfter(normalizedDay)) {
        return entry.effectiveDate;
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
      latestChangeInWindow = entry.effectiveDate;
    }

    if (latestChangeInWindow != null) {
      return latestChangeInWindow;
    }

    final activeEntryAtWindowEnd = goalEntryForDay(windowEnd);
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
      updatedAt: updatedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
    );
  }

  /// Apply goal change.
  CalorieGoalSettings applyGoalChange({
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    bool replaceFutureHistory = false,
  }) {
    final effectiveDate = normalizeDiaryDay(changedAt);
    final nextHistory =
        <CalorieGoalHistoryEntry>[
          for (final entry in sortedGoalHistory)
            if (_shouldKeepGoalHistoryEntry(
              entry: entry,
              effectiveDate: effectiveDate,
              replaceFutureHistory: replaceFutureHistory,
            ))
              entry,
          CalorieGoalHistoryEntry(
            dailyKcalGoal: dailyKcalGoal,
            calculatorProfile: calculatorProfile,
            effectiveDate: effectiveDate,
            changedAt: changedAt,
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
      updatedAt: changedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn: null,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
    );
  }

  /// Apply eating window change.
  CalorieGoalSettings applyEatingWindowChange({
    required DateTime changedAt,
    required int startMinuteOfDay,
    required int endMinuteOfDay,
  }) {
    final resolvedWindow = _resolveEatingWindowMinutes(
      startMinuteOfDay: startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay,
    );
    return copyWith(
      updatedAt: changedAt,
      eatingWindowStartMinuteOfDay: resolvedWindow.startMinuteOfDay,
      eatingWindowEndMinuteOfDay: resolvedWindow.endMinuteOfDay,
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
      updatedAt: updatedAt,
      goalHistory: goalHistory,
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
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
      updatedAt: updatedAt,
      goalHistory: goalHistory,
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: List<String>.unmodifiable(nextKeys),
    );
  }

  /// Copy with.
  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    DateTime? updatedAt,
    List<CalorieGoalHistoryEntry>? goalHistory,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
    PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
    List<String>? skippedIntakeDayKeys,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      updatedAt: updatedAt ?? this.updatedAt,
      goalHistory: goalHistory ?? this.goalHistory,
      eatingWindowStartMinuteOfDay:
          eatingWindowStartMinuteOfDay ?? this.eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay:
          eatingWindowEndMinuteOfDay ?? this.eatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn ?? this.pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys ?? this.skippedIntakeDayKeys,
    );
  }
}

/// Is valid eating window minutes.
bool isValidEatingWindowMinutes({
  required int startMinuteOfDay,
  required int endMinuteOfDay,
}) {
  final normalizedStart = _normalizeMinuteOfDay(startMinuteOfDay);
  final normalizedEnd = _normalizeMinuteOfDay(endMinuteOfDay);
  return normalizedStart < normalizedEnd;
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _shouldKeepGoalHistoryEntry({
  required CalorieGoalHistoryEntry entry,
  required DateTime effectiveDate,
  required bool replaceFutureHistory,
}) {
  if (_isSameDay(entry.effectiveDate, effectiveDate)) {
    return false;
  }
  if (!replaceFutureHistory) {
    return true;
  }
  return entry.effectiveDate.isBefore(effectiveDate);
}

({int startMinuteOfDay, int endMinuteOfDay}) _resolveEatingWindowMinutes({
  required int startMinuteOfDay,
  required int endMinuteOfDay,
}) {
  final normalizedStart = _normalizeMinuteOfDay(startMinuteOfDay);
  final normalizedEnd = _normalizeMinuteOfDay(endMinuteOfDay);
  if (normalizedStart >= normalizedEnd) {
    return (
      startMinuteOfDay: defaultEatingWindowStartMinuteOfDay,
      endMinuteOfDay: defaultEatingWindowEndMinuteOfDay,
    );
  }
  return (startMinuteOfDay: normalizedStart, endMinuteOfDay: normalizedEnd);
}

int _normalizeMinuteOfDay(int value) {
  return value.clamp(0, _minutesPerDay - 1);
}

String _dayKey(DateTime day) {
  return normalizeDiaryDay(day).toIso8601String().split('T').first;
}

DateTime? _dateFromDayKeyOrNull(String value) {
  try {
    return normalizeDiaryDay(DateTime.parse(value));
  } on FormatException {
    return null;
  }
}

DateTime _dateTimeForMinuteOfDay({
  required DateTime day,
  required int minuteOfDay,
}) {
  final hour = minuteOfDay ~/ 60;
  final minute = minuteOfDay % 60;
  return DateTime(day.year, day.month, day.day, hour, minute);
}
