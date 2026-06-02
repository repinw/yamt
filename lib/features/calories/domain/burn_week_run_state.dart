import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Number of days in one Burn Week.
const int burnWeekDaysPerWeek = 7;

/// First week number shown for a fresh Burn Week run.
const int burnWeekLearningRunWeekNumber = 1;

/// Fresh users start with one heart.
const int burnWeekInitialHeartCount = 1;

/// Current persisted Burn Week run-state schema.
const int burnWeekRunStateSchemaVersion = 1;

/// Persistent Burn Week run state for real users.
class BurnWeekRunState {
  /// Creates Burn Week run state.
  const BurnWeekRunState({
    required this.currentWeekStartDayKey,
    required this.runWeekNumber,
    required this.starCount,
    required this.heartCount,
    required this.heartCreditKcal,
    required this.starBrokeThisWeek,
    required this.missedTrackingThisWeek,
    this.heartDayKeys = const <String>[],
    this.heartStarBreakDayKeys = const <String>[],
    this.runLimitWarningThisWeek = false,
    this.lastActiveDayKey,
  });

  /// Initial real Burn Week run state.
  const BurnWeekRunState.initial()
    : currentWeekStartDayKey = null,
      lastActiveDayKey = null,
      runWeekNumber = burnWeekLearningRunWeekNumber,
      starCount = 0,
      heartCount = burnWeekInitialHeartCount,
      heartCreditKcal = 0,
      starBrokeThisWeek = false,
      missedTrackingThisWeek = false,
      heartDayKeys = const <String>[],
      heartStarBreakDayKeys = const <String>[],
      runLimitWarningThisWeek = false;

  /// Decodes from persisted json.
  factory BurnWeekRunState.fromJson(Map<String, dynamic> json) {
    if (!hasCurrentBurnWeekRunStateSchema(json)) {
      return const BurnWeekRunState.initial();
    }
    return BurnWeekRunState(
      currentWeekStartDayKey: json['current_week_start_day_key'] as String?,
      lastActiveDayKey: json['last_active_day_key'] as String?,
      runWeekNumber:
          (json['run_week_number'] as num?)?.toInt() ??
          burnWeekLearningRunWeekNumber,
      starCount: (json['star_count'] as num?)?.toInt() ?? 0,
      heartCount:
          (json['heart_count'] as num?)?.toInt() ?? burnWeekInitialHeartCount,
      heartCreditKcal: (json['heart_credit_kcal'] as num?)?.toDouble() ?? 0,
      starBrokeThisWeek: json['star_broke_this_week'] as bool? ?? false,
      missedTrackingThisWeek:
          json['missed_tracking_this_week'] as bool? ?? false,
      heartDayKeys: _decodeHeartDayKeys(json['heart_day_keys']),
      heartStarBreakDayKeys: _decodeHeartDayKeys(
        json['heart_star_break_day_keys'],
      ),
      runLimitWarningThisWeek:
          json['run_limit_warning_this_week'] as bool? ?? false,
    );
  }

  /// Current persisted week start day key.
  final String? currentWeekStartDayKey;

  /// Last day the user opened the Burn live loop.
  final String? lastActiveDayKey;

  /// Current run week number.
  final int runWeekNumber;

  /// Earned permanent stars.
  final int starCount;

  /// Current hearts.
  final int heartCount;

  /// Heart kcal applied this week.
  final double heartCreditKcal;

  /// Whether a star already broke this week.
  final bool starBrokeThisWeek;

  /// Whether tracking miss already killed perfect week.
  final bool missedTrackingThisWeek;

  /// Diary days protected by a spent heart.
  final List<String> heartDayKeys;

  /// Heart days that spent the last heart and broke one star.
  final List<String> heartStarBreakDayKeys;

  /// Whether user chose to continue an unrecoverable limit week.
  final bool runLimitWarningThisWeek;

  /// Whether [day] is protected by a spent heart.
  bool isHeartDay(DateTime day) {
    return heartDayKeys.contains(diaryDayKey(day));
  }

  /// Whether [day] can spend a heart in the current active run week.
  bool canUseHeartForDay(DateTime day, {DateTime? today}) {
    if (heartCount <= 0 || isHeartDay(day)) {
      return false;
    }
    final weekStartDate = _parseBurnWeekDayKey(currentWeekStartDayKey);
    if (weekStartDate == null) {
      return false;
    }
    final normalizedToday = normalizeDiaryDay(today ?? DateTime.now());
    if (weekStartDate.isAfter(normalizedToday)) {
      return false;
    }
    final normalizedDay = normalizeDiaryDay(day);
    final weekEndDate = addDiaryDays(weekStartDate, burnWeekDaysPerWeek);
    return !normalizedDay.isBefore(weekStartDate) &&
        normalizedDay.isBefore(weekEndDate);
  }

  /// Whether [day] can still be reverted and refunded.
  bool canUnmarkHeartDay(DateTime day) {
    if (!isHeartDay(day)) {
      return false;
    }
    final weekStartDate = _parseBurnWeekDayKey(currentWeekStartDayKey);
    if (weekStartDate == null) {
      return false;
    }
    final normalizedDay = normalizeDiaryDay(day);
    final weekEndDate = addDiaryDays(weekStartDate, burnWeekDaysPerWeek);
    return !normalizedDay.isBefore(weekStartDate) &&
        normalizedDay.isBefore(weekEndDate);
  }

  /// Encodes to persisted json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': burnWeekRunStateSchemaVersion,
      'current_week_start_day_key': currentWeekStartDayKey,
      'last_active_day_key': lastActiveDayKey,
      'run_week_number': runWeekNumber,
      'star_count': starCount,
      'heart_count': heartCount,
      'heart_credit_kcal': heartCreditKcal,
      'star_broke_this_week': starBrokeThisWeek,
      'missed_tracking_this_week': missedTrackingThisWeek,
      'heart_day_keys': heartDayKeys,
      'heart_star_break_day_keys': heartStarBreakDayKeys,
      'run_limit_warning_this_week': runLimitWarningThisWeek,
    };
  }

  /// Copies current state with overrides.
  BurnWeekRunState copyWith({
    Object? currentWeekStartDayKey = _keepValue,
    Object? lastActiveDayKey = _keepValue,
    int? runWeekNumber,
    int? starCount,
    int? heartCount,
    double? heartCreditKcal,
    bool? starBrokeThisWeek,
    bool? missedTrackingThisWeek,
    List<String>? heartDayKeys,
    List<String>? heartStarBreakDayKeys,
    bool? runLimitWarningThisWeek,
  }) {
    return BurnWeekRunState(
      currentWeekStartDayKey: currentWeekStartDayKey == _keepValue
          ? this.currentWeekStartDayKey
          : currentWeekStartDayKey as String?,
      lastActiveDayKey: lastActiveDayKey == _keepValue
          ? this.lastActiveDayKey
          : lastActiveDayKey as String?,
      runWeekNumber: runWeekNumber ?? this.runWeekNumber,
      starCount: starCount ?? this.starCount,
      heartCount: heartCount ?? this.heartCount,
      heartCreditKcal: heartCreditKcal ?? this.heartCreditKcal,
      starBrokeThisWeek: starBrokeThisWeek ?? this.starBrokeThisWeek,
      missedTrackingThisWeek:
          missedTrackingThisWeek ?? this.missedTrackingThisWeek,
      heartDayKeys: heartDayKeys ?? this.heartDayKeys,
      heartStarBreakDayKeys:
          heartStarBreakDayKeys ?? this.heartStarBreakDayKeys,
      runLimitWarningThisWeek:
          runLimitWarningThisWeek ?? this.runLimitWarningThisWeek,
    );
  }
}

/// Whether persisted json belongs to the current Burn Week schema.
bool hasCurrentBurnWeekRunStateSchema(Map<String, dynamic> json) {
  return json['schema_version'] == burnWeekRunStateSchemaVersion;
}

const _keepValue = Object();

List<String> _decodeHeartDayKeys(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  final keys = <String>{};
  for (final item in value) {
    if (item case final String key when key.trim().isNotEmpty) {
      keys.add(key.trim());
    }
  }
  return List<String>.unmodifiable(keys.toList()..sort());
}

DateTime? _parseBurnWeekDayKey(String? dayKey) {
  final normalizedDayKey = dayKey?.trim();
  if (normalizedDayKey == null || normalizedDayKey.isEmpty) {
    return null;
  }
  final parts = normalizedDayKey.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return normalizeDiaryDay(DateTime(year, month, day));
}
