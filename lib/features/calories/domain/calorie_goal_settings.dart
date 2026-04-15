import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_settings.g.dart';

const defaultDailyCalorieGoalKcal = 2500.0;
const defaultEatingWindowStartMinuteOfDay = 6 * 60;
const defaultEatingWindowEndMinuteOfDay = 22 * 60;
const _minutesPerDay = 24 * 60;
const _keepValue = Object();

@JsonEnum(valueField: 'jsonValue')
enum CalorieGoalSource {
  manual('manual'),
  calculator('calculator'),
  weeklyCheckIn('weekly_checkin');

  const CalorieGoalSource(this.jsonValue);

  final String jsonValue;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieGoalWeeklyCheckInSnapshot {
  const CalorieGoalWeeklyCheckInSnapshot({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.trendWeightChangePerDay,
    required this.calculatedTrueTdeeKcal,
    required this.averageActiveKcal,
    required this.lowConfidence,
  });

  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;
  @FlexibleDoubleConverter()
  final double trendWeightChangePerDay;
  @FlexibleDoubleConverter()
  final double calculatedTrueTdeeKcal;
  @FlexibleDoubleConverter()
  final double averageActiveKcal;
  final bool lowConfidence;

  factory CalorieGoalWeeklyCheckInSnapshot.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalWeeklyCheckInSnapshotFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$CalorieGoalWeeklyCheckInSnapshotToJson(this);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PendingCalorieGoalWeeklyCheckIn {
  const PendingCalorieGoalWeeklyCheckIn({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    this.dismissedAt,
  });

  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;
  @FlexibleDateTimeConverter()
  final DateTime dueDate;
  @NullableFlexibleDateTimeConverter()
  final DateTime? dismissedAt;

  bool get isDismissed => dismissedAt != null;

  String get windowKey {
    return '${diaryDayKey(windowStartDate)}:${diaryDayKey(windowEndDate)}';
  }

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

  factory PendingCalorieGoalWeeklyCheckIn.fromJson(Map<String, dynamic> json) {
    return _$PendingCalorieGoalWeeklyCheckInFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$PendingCalorieGoalWeeklyCheckInToJson(this);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalHistoryEntry {
  const CalorieGoalHistoryEntry({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.effectiveDate,
    required this.changedAt,
    this.source = CalorieGoalSource.manual,
    this.weeklyCheckInSnapshot,
  });

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;
  @NullableFlexibleDateTimeConverter()
  final DateTime? changedAt;
  @JsonKey(
    defaultValue: CalorieGoalSource.manual,
    unknownEnumValue: CalorieGoalSource.manual,
  )
  final CalorieGoalSource source;
  final CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot;

  bool get hasGoal => dailyKcalGoal != null;
  DateTime get effectiveChangedAt => changedAt ?? effectiveDate;
  bool get isWeeklyCheckIn => source == CalorieGoalSource.weeklyCheckIn;
  bool get hasLearnedTdee => weeklyCheckInSnapshot != null;

  factory CalorieGoalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalHistoryEntryFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieGoalHistoryEntryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalSettings {
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

  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[],
      eatingWindowStartMinuteOfDay = defaultEatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay = defaultEatingWindowEndMinuteOfDay,
      pendingWeeklyCheckIn = null,
      skippedIntakeDayKeys = const <String>[];

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

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;
  @JsonKey(defaultValue: <CalorieGoalHistoryEntry>[])
  final List<CalorieGoalHistoryEntry> goalHistory;
  @JsonKey(defaultValue: defaultEatingWindowStartMinuteOfDay)
  final int eatingWindowStartMinuteOfDay;
  @JsonKey(defaultValue: defaultEatingWindowEndMinuteOfDay)
  final int eatingWindowEndMinuteOfDay;
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;
  @JsonKey(defaultValue: <String>[])
  final List<String> skippedIntakeDayKeys;

  bool get hasGoal => dailyKcalGoal != null;
  bool get hasCalculatorProfile => calculatorProfile != null;
  bool get hasLearnedTdee => latestLearnedTdeeKcal != null;

  int get normalizedEatingWindowStartMinuteOfDay {
    return _resolveEatingWindowMinutes(
      startMinuteOfDay: eatingWindowStartMinuteOfDay,
      endMinuteOfDay: eatingWindowEndMinuteOfDay,
    ).startMinuteOfDay;
  }

  int get normalizedEatingWindowEndMinuteOfDay {
    return _resolveEatingWindowMinutes(
      startMinuteOfDay: eatingWindowStartMinuteOfDay,
      endMinuteOfDay: eatingWindowEndMinuteOfDay,
    ).endMinuteOfDay;
  }

  DateTime eatingWindowStartForDay(DateTime day) {
    return _dateTimeForMinuteOfDay(
      day: day,
      minuteOfDay: normalizedEatingWindowStartMinuteOfDay,
    );
  }

  DateTime eatingWindowEndForDay(DateTime day) {
    return _dateTimeForMinuteOfDay(
      day: day,
      minuteOfDay: normalizedEatingWindowEndMinuteOfDay,
    );
  }

  List<CalorieGoalHistoryEntry> get sortedGoalHistory {
    final entries = List<CalorieGoalHistoryEntry>.from(goalHistory);
    entries.sort((left, right) {
      final byDay = left.effectiveDate.compareTo(right.effectiveDate);
      if (byDay != 0) {
        return byDay;
      }
      return left.effectiveChangedAt.compareTo(right.effectiveChangedAt);
    });
    return List<CalorieGoalHistoryEntry>.unmodifiable(entries);
  }

  Iterable<DateTime> get skippedIntakeDays sync* {
    for (final key in skippedIntakeDayKeys) {
      final parsed = _dateFromDayKeyOrNull(key);
      if (parsed != null) {
        yield parsed;
      }
    }
  }

  CalorieGoalHistoryEntry? get latestGoalEntry {
    for (final entry in sortedGoalHistory.reversed) {
      if (entry.hasGoal) {
        return entry;
      }
    }
    return null;
  }

  CalorieGoalHistoryEntry? get latestLearnedTdeeEntry {
    for (final entry in sortedGoalHistory.reversed) {
      if (entry.hasLearnedTdee) {
        return entry;
      }
    }
    return null;
  }

  double? get latestLearnedTdeeKcal {
    return latestLearnedTdeeEntry
        ?.weeklyCheckInSnapshot
        ?.calculatedTrueTdeeKcal;
  }

  DateTime? get latestLearnedTdeeChangedAt {
    return latestLearnedTdeeEntry?.effectiveChangedAt;
  }

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

  double goalKcalForDay(DateTime day) {
    final entry = goalEntryForDay(day);
    if (entry != null) {
      return entry.dailyKcalGoal ?? 0.0;
    }
    return nextGoalStartAfterDay(day) == null
        ? defaultDailyCalorieGoalKcal
        : 0.0;
  }

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

  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

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

  bool isSkippedIntakeDay(DateTime day) {
    return skippedIntakeDayKeys.contains(_dayKey(day));
  }

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

  CalorieGoalSettings dismissPendingWeeklyCheckIn(DateTime dismissedAt) {
    final pending = pendingWeeklyCheckIn;
    if (pending == null) {
      return this;
    }
    return copyWithPendingWeeklyCheckIn(
      pending.copyWith(dismissedAt: dismissedAt),
    );
  }

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
  return value.clamp(0, _minutesPerDay - 1).toInt();
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
