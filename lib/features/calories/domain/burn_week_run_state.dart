import 'package:json_annotation/json_annotation.dart';

part 'burn_week_run_state.g.dart';

/// Number of days in one Burn Week.
const int burnWeekDaysPerWeek = 7;

/// First week number shown for a fresh Burn Week run.
const int burnWeekLearningRunWeekNumber = 1;

/// Fresh users start with one heart.
const int burnWeekInitialHeartCount = 1;

/// Current persisted Burn Week run-state schema.
const int burnWeekRunStateSchemaVersion = 1;

/// Persistent Burn Week run state for real users.
@JsonSerializable(fieldRename: FieldRename.snake)
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
      runLimitWarningThisWeek = false;

  /// Decodes from persisted json.
  factory BurnWeekRunState.fromJson(Map<String, dynamic> json) {
    if (!hasCurrentBurnWeekRunStateSchema(json)) {
      return const BurnWeekRunState.initial();
    }
    return _$BurnWeekRunStateFromJson(json);
  }

  /// Current persisted week start day key.
  final String? currentWeekStartDayKey;

  /// Last day the user opened the Burn live loop.
  final String? lastActiveDayKey;

  /// Current run week number.
  @JsonKey(defaultValue: burnWeekLearningRunWeekNumber)
  final int runWeekNumber;

  /// Earned permanent stars.
  @JsonKey(defaultValue: 0)
  final int starCount;

  /// Current hearts.
  @JsonKey(defaultValue: burnWeekInitialHeartCount)
  final int heartCount;

  /// Heart kcal applied this week.
  @JsonKey(defaultValue: 0)
  final double heartCreditKcal;

  /// Whether a star already broke this week.
  @JsonKey(defaultValue: false)
  final bool starBrokeThisWeek;

  /// Whether tracking miss already killed perfect week.
  @JsonKey(defaultValue: false)
  final bool missedTrackingThisWeek;

  /// Whether user chose to continue an unrecoverable limit week.
  final bool runLimitWarningThisWeek;

  /// Encodes to persisted json.
  Map<String, dynamic> toJson() => {
    'schema_version': burnWeekRunStateSchemaVersion,
    ..._$BurnWeekRunStateToJson(this),
  };

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
