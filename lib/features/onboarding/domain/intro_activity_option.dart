import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';

/// Activity levels of a typical week offered during onboarding.
///
/// Each level covers everyday movement and training together, like the
/// calculator levels in the calorie settings. The training page afterwards
/// only spreads the weekly budget over training and rest days. The extreme
/// calculator level is not offered here; it stays reachable from the calorie
/// settings.
enum IntroActivityOption {
  /// Sitting all day, barely any walking or training.
  sitting(CalorieActivityLevelOption.none),

  /// Mostly sitting, with daily walks or one or two easy workouts.
  light(CalorieActivityLevelOption.low),

  /// On the feet most of the day, or three to four workouts a week.
  onFeet(CalorieActivityLevelOption.medium),

  /// Physically demanding work, or training on most days.
  hardLabour(CalorieActivityLevelOption.high);

  new(this.calorieOption);

  /// Calculator level this option maps to.
  final CalorieActivityLevelOption calorieOption;

  /// Returns the option that matches [level].
  ///
  /// Levels onboarding does not offer, such as the extreme one, map to the
  /// option with the closest activity factor.
  static IntroActivityOption fromCalorieOption(
    CalorieActivityLevelOption level,
  ) {
    var closest = IntroActivityOption.sitting;
    var smallestDistance = double.infinity;
    for (final option in IntroActivityOption.values) {
      final distance = (option.calorieOption.palValue - level.palValue).abs();
      if (distance < smallestDistance) {
        closest = option;
        smallestDistance = distance;
      }
    }
    return closest;
  }
}
