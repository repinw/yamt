enum CalorieActivityLevelOption {
  none(1.2),
  low(1.4),
  medium(1.6),
  high(1.8);

  const CalorieActivityLevelOption(this.palValue);

  final double palValue;

  static CalorieActivityLevelOption fromActivityLevel(double activityLevel) {
    var closestOption = CalorieActivityLevelOption.low;
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
