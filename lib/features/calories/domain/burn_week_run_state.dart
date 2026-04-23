/// Number of days in one Burn Week.
const int burnWeekDaysPerWeek = 7;

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
    this.lastActiveDayKey,
  });

  /// Initial real Burn Week run state.
  const BurnWeekRunState.initial()
    : currentWeekStartDayKey = null,
      lastActiveDayKey = null,
      runWeekNumber = 1,
      starCount = 0,
      heartCount = 3,
      heartCreditKcal = 0,
      starBrokeThisWeek = false,
      missedTrackingThisWeek = false;

  /// Decodes from persisted json.
  factory BurnWeekRunState.fromJson(Map<String, dynamic> json) {
    return BurnWeekRunState(
      currentWeekStartDayKey: json['current_week_start_day_key'] as String?,
      lastActiveDayKey: json['last_active_day_key'] as String?,
      runWeekNumber: (json['run_week_number'] as num?)?.toInt() ?? 1,
      starCount: (json['star_count'] as num?)?.toInt() ?? 0,
      heartCount: (json['heart_count'] as num?)?.toInt() ?? 3,
      heartCreditKcal: (json['heart_credit_kcal'] as num?)?.toDouble() ?? 0,
      starBrokeThisWeek: json['star_broke_this_week'] as bool? ?? false,
      missedTrackingThisWeek:
          json['missed_tracking_this_week'] as bool? ?? false,
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

  /// Encodes to persisted json.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current_week_start_day_key': currentWeekStartDayKey,
      'last_active_day_key': lastActiveDayKey,
      'run_week_number': runWeekNumber,
      'star_count': starCount,
      'heart_count': heartCount,
      'heart_credit_kcal': heartCreditKcal,
      'star_broke_this_week': starBrokeThisWeek,
      'missed_tracking_this_week': missedTrackingThisWeek,
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
    );
  }
}

const _keepValue = Object();
