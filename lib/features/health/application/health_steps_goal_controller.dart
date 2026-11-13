import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';

part 'health_steps_goal_controller.g.dart';

const _stepsGoalKey = 'health_steps_goal_v1';
const _stepsGoalSinceKey = 'health_steps_goal_since_v1';

/// [day] as the number yyyymmdd.
int healthStepsDayKey(DateTime day) =>
    day.year * 10000 + day.month * 100 + day.day;

/// The most steps a day's goal may ask for.
const healthStepsGoalMax = 50000;

/// The user's steps goal per day, saved on the device, or null without a
/// goal. Only for display: it never enters a calorie calculation.
@riverpod
class HealthStepsGoalController extends _$HealthStepsGoalController {
  @override
  int? build() {
    final goal = ref.watch(appPreferencesProvider).getIntSync(_stepsGoalKey);
    return goal != null && goal > 0 ? goal : null;
  }

  /// Saves [goal] steps per day, at most [healthStepsGoalMax]; null or less
  /// than one step removes the goal.
  Future<void> save(int? goal) async {
    final preferences = ref.read(appPreferencesProvider);
    final next = goal == null || goal < 1
        ? null
        : (goal > healthStepsGoalMax ? healthStepsGoalMax : goal);
    // Shown at once, so quick taps on a plus build on each other; a failed
    // save takes it back, so no goal shows that is gone after the next start.
    final previous = state;
    if (next == previous) {
      // The same goal keeps the day it was set.
      return;
    }
    final since = ref.read(healthStepsGoalSinceProvider.notifier);
    final previousSince = ref.read(healthStepsGoalSinceProvider);
    state = next;
    final marked = since.mark(
      next == null
          ? null
          : healthStepsDayKey(dateOnly(ref.read(clockProvider)())),
    );
    try {
      await marked;
      if (next == null) {
        await preferences.remove(_stepsGoalKey);
      } else {
        await preferences.setInt(_stepsGoalKey, next);
      }
    } on Object {
      if (ref.mounted && state == next) {
        state = previous;
        // The goal that is back keeps its own day.
        await since.mark(previousSince);
      }
      rethrow;
    }
  }
}

/// The day the steps goal was last set, as yyyymmdd, or null without one.
/// The run week of that day does not ask to raise the goal.
@riverpod
class HealthStepsGoalSince extends _$HealthStepsGoalSince {
  @override
  int? build() =>
      ref.watch(appPreferencesProvider).getIntSync(_stepsGoalSinceKey);

  /// Remembers [day] as the day the goal was set; null forgets it.
  Future<void> mark(int? day) async {
    final preferences = ref.read(appPreferencesProvider);
    state = day;
    if (day == null) {
      await preferences.remove(_stepsGoalSinceKey);
    } else {
      await preferences.setInt(_stepsGoalSinceKey, day);
    }
  }
}
