/// Defines calorie activity level option.
enum CalorieActivityLevelOption {
  /// None.
  none(1.2),

  /// Low.
  low(1.375),

  /// Medium.
  medium(1.55),

  /// High.
  high(1.725),

  /// Extreme.
  extreme(1.9)
  ;

  const CalorieActivityLevelOption(this.palValue);

  /// The pal value.
  final double palValue;

  /// From activity level.
  static CalorieActivityLevelOption fromActivityLevel(double activityLevel) {
    var closestOption = CalorieActivityLevelOption.values.first;
    var smallestDistance = double.infinity;

    for (final option in CalorieActivityLevelOption.values) {
      final distance = (option.palValue - activityLevel).abs();
      if (distance < smallestDistance) {
        closestOption = option;
        smallestDistance = distance;
      }
    }

    return closestOption;
  }
}
