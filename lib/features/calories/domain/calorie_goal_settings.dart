import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_settings.g.dart';

const defaultDailyCalorieGoalKcal = 2500.0;

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalHistoryEntry {
  const CalorieGoalHistoryEntry({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.effectiveDate,
  });

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;

  bool get hasGoal => dailyKcalGoal != null;

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
  });

  const CalorieGoalSettings.empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[];

  factory CalorieGoalSettings.single({
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime effectiveDate,
    DateTime? updatedAt,
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
        ),
      ],
    );
  }

  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;
  final CalorieCalculatorProfile? calculatorProfile;
  @NullableFlexibleDateTimeConverter()
  final DateTime? updatedAt;
  @JsonKey(defaultValue: <CalorieGoalHistoryEntry>[])
  final List<CalorieGoalHistoryEntry> goalHistory;

  bool get hasGoal => dailyKcalGoal != null;
  bool get hasCalculatorProfile => calculatorProfile != null;

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

  double goalKcalForDay(DateTime day) {
    return goalEntryForDay(day)?.dailyKcalGoal ?? defaultDailyCalorieGoalKcal;
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

    return latestChangeInWindow ?? windowStart;
  }

  factory CalorieGoalSettings.fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

  CalorieGoalSettings applyGoalChange({
    required DateTime changedAt,
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
  }) {
    final effectiveDate = normalizeDiaryDay(changedAt);
    final nextHistory = <CalorieGoalHistoryEntry>[
      for (final entry in sortedGoalHistory)
        if (!_isSameDay(entry.effectiveDate, effectiveDate)) entry,
      CalorieGoalHistoryEntry(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: calculatorProfile,
        effectiveDate: effectiveDate,
      ),
    ]..sort((left, right) => left.effectiveDate.compareTo(right.effectiveDate));

    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      updatedAt: changedAt,
      goalHistory: List<CalorieGoalHistoryEntry>.unmodifiable(nextHistory),
    );
  }

  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    DateTime? updatedAt,
    List<CalorieGoalHistoryEntry>? goalHistory,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      updatedAt: updatedAt ?? this.updatedAt,
      goalHistory: goalHistory ?? this.goalHistory,
    );
  }
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
