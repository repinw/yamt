import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

part 'calorie_goal_settings.g.dart';

/// The default daily calorie goal kcal.
const defaultDailyCalorieGoalKcal = 2500.0;

/// Default kcal of one training session.
///
/// A session adds this much to the energy use of its week, and a training day
/// gets this much more than a rest day. It is a fixed estimate on purpose;
/// the learned TDEE corrects it for people who train a lot more or less.
const defaultTrainingDayKcalOffset = 250.0;

/// The current calorie math data version.
const currentCalorieMathVersion = 3;

/// Defines calorie goal settings.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalSettings {
  /// The calorie goal settings.
  const new({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.updatedAt,
    required this.goalHistory,
    required this.pendingWeeklyCheckIn,
    required this.skippedIntakeDayKeys,
    required this.calorieMathVersion,
    this.trainingWeekdays = const <int>[],
    this.trainingDayKcalOffset = 0.0,
    this.trainingDayOverrides = const <String, bool>{},
    this.pauseDayKeys = const <String>[],
  });

  /// Creates a [CalorieGoalSettings] for from json.
  factory fromJson(Map<String, dynamic> json) {
    return _$CalorieGoalSettingsFromJson(json);
  }

  /// Creates empty calorie goal settings.
  const new empty()
    : dailyKcalGoal = null,
      calculatorProfile = null,
      calorieMathVersion = currentCalorieMathVersion,
      updatedAt = null,
      goalHistory = const <CalorieGoalHistoryEntry>[],
      pendingWeeklyCheckIn = null,
      skippedIntakeDayKeys = const <String>[],
      trainingWeekdays = const <int>[],
      trainingDayKcalOffset = 0.0,
      trainingDayOverrides = const <String, bool>{},
      pauseDayKeys = const <String>[];

  /// Creates a [CalorieGoalSettings] for single.
  factory single({
    required double? dailyKcalGoal,
    required CalorieCalculatorProfile? calculatorProfile,
    required DateTime effectiveDate,
    DateTime? countingStartDate,
    DateTime? updatedAt,
    CalorieGoalSource source = CalorieGoalSource.manual,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
    Map<String, bool>? trainingDayOverrides,
    List<String>? pauseDayKeys,
  }) {
    final normalizedCountingStartDate = resolveNormalizedCountingStartDate(
      effectiveDate: effectiveDate,
      countingStartDate: countingStartDate,
    );
    final resolvedWeekdays =
        trainingWeekdays ??
        calculatorProfile?.trainingWeekdays ??
        const <int>[];
    final resolvedOffset =
        trainingDayKcalOffset ??
        calculatorProfile?.trainingDayKcalOffset ??
        0.0;
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: currentCalorieMathVersion,
      updatedAt: updatedAt ?? effectiveDate,
      trainingWeekdays: resolvedWeekdays,
      trainingDayKcalOffset: resolvedOffset,
      trainingDayOverrides: trainingDayOverrides ?? const <String, bool>{},
      pauseDayKeys: pauseDayKeys ?? const <String>[],
      goalHistory: <CalorieGoalHistoryEntry>[
        CalorieGoalHistoryEntry(
          dailyKcalGoal: dailyKcalGoal,
          calculatorProfile: calculatorProfile,
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
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// The calorie math data version.
  final int calorieMathVersion;

  /// The updated at.
  @DateTimeJsonConverter()
  final DateTime? updatedAt;

  /// The goal history.
  final List<CalorieGoalHistoryEntry> goalHistory;

  /// The pending weekly check in.
  final PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn;

  /// The skipped intake day keys.
  final List<String> skippedIntakeDayKeys;

  /// Configured weekdays for training (1 = Monday, 7 = Sunday).
  final List<int> trainingWeekdays;

  /// kcal of one training session: added to the energy use of the week and
  /// the gap between a training day and a rest day.
  final double trainingDayKcalOffset;

  /// Manual per-day training overrides (dayKey -> isTrainingDay).
  final Map<String, bool> trainingDayOverrides;

  /// Days marked as pause/exception days (Urlaub, Krankheit, Wettkampf).
  final List<String> pauseDayKeys;

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
    return latestLearnedTdeeEntry?.learnedTdeeSnapshot?.calculatedTdeeKcal;
  }

  /// The latest learned tdee changed at.
  DateTime? get latestLearnedTdeeChangedAt {
    return latestLearnedTdeeEntry?.effectiveChangedAt;
  }

  /// Copy with pending weekly check in.
  CalorieGoalSettings copyWithPendingWeeklyCheckIn(
    PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  ) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      calculatorProfile: calculatorProfile,
      calorieMathVersion: calorieMathVersion,
      updatedAt: updatedAt,
      goalHistory: goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: trainingDayKcalOffset,
      trainingDayOverrides: trainingDayOverrides,
      pauseDayKeys: pauseDayKeys,
    );
  }

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieGoalSettingsToJson(this);

  /// Copy with.
  CalorieGoalSettings copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    int? calorieMathVersion,
    DateTime? updatedAt,
    List<CalorieGoalHistoryEntry>? goalHistory,
    PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
    List<String>? skippedIntakeDayKeys,
    List<int>? trainingWeekdays,
    double? trainingDayKcalOffset,
    Map<String, bool>? trainingDayOverrides,
    List<String>? pauseDayKeys,
  }) {
    return CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      calorieMathVersion: calorieMathVersion ?? this.calorieMathVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      goalHistory: goalHistory ?? this.goalHistory,
      pendingWeeklyCheckIn: pendingWeeklyCheckIn ?? this.pendingWeeklyCheckIn,
      skippedIntakeDayKeys: skippedIntakeDayKeys ?? this.skippedIntakeDayKeys,
      trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
      trainingDayKcalOffset:
          trainingDayKcalOffset ?? this.trainingDayKcalOffset,
      trainingDayOverrides: trainingDayOverrides ?? this.trainingDayOverrides,
      pauseDayKeys: pauseDayKeys ?? this.pauseDayKeys,
    );
  }
}
