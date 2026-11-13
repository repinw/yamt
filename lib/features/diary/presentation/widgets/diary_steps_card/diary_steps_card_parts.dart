import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_steps_card_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/steps_fire_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card/diary_steps_card_fire.dart';

/// A line as wide as the card that fills up to the steps goal; at the goal
/// it takes the accent, and [burning] it is on fire.
class DiaryStepsGoalLine extends StatelessWidget {
  /// Creates the line.
  const new({
    required this.steps,
    required this.goal,
    this.burning = false,
    super.key,
  });

  /// Steps of the day.
  final int steps;

  /// The steps goal.
  final int goal;

  /// Whether fire runs through the line.
  final bool burning;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final radius = BorderRadius.circular(AppStepsCard.goalLine / 2);
    if (burning) {
      return DecoratedBox(
        decoration: BoxDecoration(color: colors.track, borderRadius: radius),
        child: const DiaryStepsFireLine(),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: colors.track, borderRadius: radius),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: math.min(1, steps / goal),
        child: Container(
          height: AppStepsCard.goalLine,
          decoration: BoxDecoration(
            color: steps >= goal ? colors.accent : colors.ink,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}

/// One slot per day of the run week, filled from the bottom with the day's
/// share of the [goal], or of the best day without a goal. The card's day,
/// at [dayIndex], fills in ink and never lower than a visible stub; another
/// day at the goal takes the accent. With [burning] the card's day and every
/// day at twice the goal take the color of the fire.
class DiaryStepsWeekBars extends StatelessWidget {
  /// Creates the bars.
  const new({
    required this.days,
    required this.dayIndex,
    required this.goal,
    this.burning = false,
    super.key,
  });

  /// Whether the card is on fire.
  final bool burning;

  /// Steps of each day of the run week, first day first.
  final List<int?> days;

  /// Index of the card's day in [days].
  final int dayIndex;

  /// The steps goal, when there is one.
  final int? goal;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final dayGoal = goal;
    final full =
        dayGoal ?? days.fold<int>(0, (top, day) => math.max(top, day ?? 0));
    final radius = BorderRadius.circular(AppStepsCard.barRadius);

    return Row(
      spacing: AppStepsCard.barGap,
      children: [
        for (final (index, steps) in days.indexed)
          Container(
            width: AppStepsCard.barWidth,
            height: AppStepsCard.barsHeight,
            alignment: AlignmentDirectional.bottomCenter,
            decoration: BoxDecoration(
              color: colors.track,
              borderRadius: radius,
            ),
            child: Container(
              height: _fill(steps ?? 0, full, isDay: index == dayIndex),
              decoration: BoxDecoration(
                color: _color(colors, steps ?? 0, isDay: index == dayIndex),
                borderRadius: radius,
              ),
            ),
          ),
      ],
    );
  }

  Color _color(FoodLabelColors colors, int steps, {required bool isDay}) {
    final dayGoal = goal;
    if (burning &&
        (isDay ||
            dayGoal != null &&
                steps >= dayGoal * AppStepsCard.fireGoalFactor)) {
      return StepsFireColors.flame;
    }
    // The card's day stays in ink; its goal shows on the line.
    if (isDay) {
      return colors.ink;
    }
    return dayGoal != null && steps >= dayGoal ? colors.accent : colors.muted;
  }

  double _fill(int steps, int full, {required bool isDay}) {
    final share = full == 0 ? 0.0 : math.min(1, steps / full);
    return math.max(
      isDay ? AppStepsCard.barDayMinHeight : 0,
      AppStepsCard.barsHeight * share,
    );
  }
}
