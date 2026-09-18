import 'package:yamt/features/calories/domain/calorie_activity_level_option.dart';

/// Daily-life activity levels offered during onboarding.
///
/// Onboarding asks only about everyday movement, because training days are
/// collected on their own page. The extreme calculator level is therefore not
/// offered here; it stays reachable from the calorie settings.
enum IntroActivityOption {
  /// Sitting all day, barely any walking.
  sitting(CalorieActivityLevelOption.none),

  /// Mostly sitting, but walking or cycling every day.
  light(CalorieActivityLevelOption.low),

  /// On the feet for most of the day.
  onFeet(CalorieActivityLevelOption.medium),

  /// Physically demanding work.
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
