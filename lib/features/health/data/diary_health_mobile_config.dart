import 'package:health/health.dart';

/// Log name shared by mobile diary health data components.
const diaryHealthLogName = 'DiaryHealthService';

/// Freshness window for today's health data.
const diaryHealthTodayCacheTtl = Duration(minutes: 5);

/// Freshness window for historical health data.
const diaryHealthHistoricalCacheTtl = Duration(hours: 12);

/// Maximum age for stale health cache reuse.
const diaryHealthMaxStaleCacheAge = Duration(days: 7);

/// Maximum cached derived diary health days.
const maxDiaryHealthCacheEntries = 30;

/// Maximum cached activity trend ranges or days.
const maxActivityTrendCacheEntries = 30;

/// Workout data requested from Health.
const workoutQueryTypes = <HealthDataType>[HealthDataType.WORKOUT];

/// Active energy data requested from Health.
const activeEnergyQueryTypes = <HealthDataType>[
  HealthDataType.ACTIVE_ENERGY_BURNED,
];

/// Aggregate activity trend data requested from Health.
const activityTrendQueryTypes = <HealthDataType>[
  HealthDataType.STEPS,
  HealthDataType.ACTIVE_ENERGY_BURNED,
];

/// Aggregate trend interval size in seconds.
const int activityTrendIntervalSeconds = Duration.secondsPerDay;

/// Default height used for distance-to-step estimates.
const defaultCalculatorProfileHeightCm = 180.0;

/// Minimum personalized height accepted for estimates.
const minPersonalizedHeightCm = 120.0;

/// Maximum personalized height accepted for estimates.
const maxPersonalizedHeightCm = 250.0;

/// Minimum calories per minute for non-step active energy segments.
const minimumUnassignedActivityKcalPerMinute = 3.0;

/// Workouts where distance can reasonably backfill missing steps.
const stepBasedWorkoutTypes = <HealthWorkoutActivityType>{
  HealthWorkoutActivityType.HIKING,
  HealthWorkoutActivityType.RUNNING,
  HealthWorkoutActivityType.RUNNING_TREADMILL,
  HealthWorkoutActivityType.STAIRS,
  HealthWorkoutActivityType.STAIR_CLIMBING,
  HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE,
  HealthWorkoutActivityType.STEP_TRAINING,
  HealthWorkoutActivityType.TRACK_AND_FIELD,
  HealthWorkoutActivityType.WALKING,
  HealthWorkoutActivityType.WALKING_TREADMILL,
  HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE,
  HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE,
};
