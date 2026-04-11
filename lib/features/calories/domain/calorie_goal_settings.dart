import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_settings.g.dart';

const defaultDailyCalorieGoalKcal = 2500.0;
const defaultEatingWindowStartMinuteOfDay = 6 * 60;
const defaultEatingWindowEndMinuteOfDay = 22 * 60;
const _minutesPerDay = 24 * 60;

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalHistoryEntry {
  const CalorieGoalHistoryEntry({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.effectiveDate,
    required this.changedAt,
  });

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;
  @NullableFlexibleDateTimeConverter()
  final DateTime? changedAt;

  bool get hasGoal => dailyKcalGoal != null;
  DateTime get effectiveChangedAt => changedAt ?? effectiveDate;

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
  });

  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[],
      eatingWindowStartMinuteOfDay = defaultEatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay = defaultEatingWindowEndMinuteOfDay;

  factory CalorieGoalSettings.single({
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime effectiveDate,
    DateTime? updatedAt,
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
        ),
      ],
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
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

  bool get hasGoal => dailyKcalGoal != null;
  bool get hasCalculatorProfile => calculatorProfile != null;

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
    entries.sort(
      (left, right) => left.effectiveDate.compareTo(right.effectiveDate),
    );
    return List<CalorieGoalHistoryEntry>.unmodifiable(entries);
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
    );
  }

  CalorieGoalSettings applyGoalChange({
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    bool replaceFutureHistory = false,
  }) {
    final effectiveDate = normalizeDiaryDay(changedAt);
    final nextHistory = <CalorieGoalHistoryEntry>[
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
      ),
    ]..sort((left, right) => left.effectiveDate.compareTo(right.effectiveDate));

    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      updatedAt: changedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
      eatingWindowStartMinuteOfDay: eatingWindowStartMinuteOfDay,
      eatingWindowEndMinuteOfDay: eatingWindowEndMinuteOfDay,
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

  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    DateTime? updatedAt,
    List<CalorieGoalHistoryEntry>? goalHistory,
    int? eatingWindowStartMinuteOfDay,
    int? eatingWindowEndMinuteOfDay,
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

DateTime _dateTimeForMinuteOfDay({
  required DateTime day,
  required int minuteOfDay,
}) {
  final hour = minuteOfDay ~/ 60;
  final minute = minuteOfDay % 60;
  return DateTime(day.year, day.month, day.day, hour, minute);
}
