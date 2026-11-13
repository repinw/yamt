import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/health/application/daily_steps_provider.dart';
import 'package:yamt/features/health/application/health_steps_goal_controller.dart';

part 'health_steps_goal_raise.g.dart';

const _answeredKey = 'health_steps_goal_raise_answered_v1';

/// Steps a day that a met week offers to add to the goal.
const healthStepsGoalRaise = 100;

/// The week before [weekStart], as the number yyyymmdd of its first day.
int _weekBeforeKey(DateTime weekStart) =>
    healthStepsDayKey(_weekBefore(weekStart));

// Counts calendar days, so a clock change never moves the week.
DateTime _weekBefore(DateTime weekStart) {
  final start = dateOnly(weekStart);
  return DateTime(start.year, start.month, start.day - weekDailyStepsDays);
}

/// The goal that the week starting at [weekStart] offers to move up to, or
/// null without an offer. A week offers [healthStepsGoalRaise] more once the
/// week before it met the goal on average, a day without steps counting as
/// zero, until the user answers. A goal set or changed in the running week
/// asks nothing in that week. From the week after, the whole week before
/// is measured against the goal as it stands now, also the days before it
/// was set: its steps either reach the new goal on average or they do not.
@riverpod
Future<int?> healthStepsGoalRaiseOffer(Ref ref, DateTime weekStart) async {
  final goal = ref.watch(healthStepsGoalControllerProvider);
  final answered = ref.watch(healthStepsGoalRaiseAnswerProvider);
  final since = ref.watch(healthStepsGoalSinceProvider);
  if (goal == null ||
      since == null ||
      since >= healthStepsDayKey(dateOnly(weekStart)) ||
      goal + healthStepsGoalRaise > healthStepsGoalMax ||
      answered == _weekBeforeKey(weekStart)) {
    return null;
  }
  final days = await ref.watch(
    weekDailyStepsProvider(_weekBefore(weekStart)).future,
  );
  final total = days.fold<int>(0, (sum, steps) => sum + (steps ?? 0));
  return total >= goal * weekDailyStepsDays
      ? goal + healthStepsGoalRaise
      : null;
}

/// The last met week the user answered the offer for, as yyyymmdd of its
/// first day, saved on the device.
@riverpod
class HealthStepsGoalRaiseAnswer extends _$HealthStepsGoalRaiseAnswer {
  @override
  int? build() => ref.watch(appPreferencesProvider).getIntSync(_answeredKey);

  /// Answers the offer of the week starting at [weekStart]: with [raise] the
  /// goal goes up by [healthStepsGoalRaise], either way the offer is gone
  /// until the next met week.
  Future<void> answer(DateTime weekStart, {required bool raise}) async {
    final preferences = ref.read(appPreferencesProvider);
    final goals = ref.read(healthStepsGoalControllerProvider.notifier);
    final goal = ref.read(healthStepsGoalControllerProvider);
    final week = _weekBeforeKey(weekStart);
    // A second tap finds the week answered, so the goal rises only once.
    if (state == week) {
      return;
    }
    final before = state;
    state = week;
    try {
      await preferences.setInt(_answeredKey, week);
    } on Object {
      if (ref.mounted && state == week) {
        state = before;
      }
      rethrow;
    }
    if (!raise || goal == null) {
      return;
    }
    try {
      await goals.save(goal + healthStepsGoalRaise);
    } on Object {
      // The goal did not rise, so the question comes back.
      if (before == null) {
        await preferences.remove(_answeredKey);
      } else {
        await preferences.setInt(_answeredKey, before);
      }
      if (ref.mounted && state == week) {
        state = before;
      }
      rethrow;
    }
  }
}
