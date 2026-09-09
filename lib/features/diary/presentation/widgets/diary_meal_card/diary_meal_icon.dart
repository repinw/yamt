import 'package:flutter/material.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

/// Renders the circular icon badge for a meal type.
class DiaryMealIcon extends StatelessWidget {
  /// Creates a meal icon badge.
  const DiaryMealIcon({required this.mealType, super.key});

  /// The meal type represented.
  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColors = MetricAccentColors.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: Icon(
        resolveMealIcon(mealType),
        color: accentColors.meal,
        size: 18,
      ),
    );
  }
}

/// Resolves an icon for the given meal type.
IconData resolveMealIcon(MealType mealType) {
  return switch (mealType) {
    MealType.breakfast => Icons.coffee_rounded,
    MealType.lunch => Icons.restaurant_rounded,
    MealType.dinner => Icons.local_fire_department_rounded,
    MealType.snack => Icons.cookie_rounded,
  };
}
