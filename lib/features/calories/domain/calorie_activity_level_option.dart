enum CalorieActivityLevelOption {
  none(1.2),
  low(1.375),
  medium(1.55),
  high(1.725),
  extreme(1.9);

  const CalorieActivityLevelOption(this.palValue);

  final double palValue;

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
