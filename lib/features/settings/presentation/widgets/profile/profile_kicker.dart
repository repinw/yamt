import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// A small caption above a value, in capitals.
class ProfileKicker extends StatelessWidget {
  /// Creates a caption.
  const new({required this.text, super.key});

  /// The caption.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: FoodLabelColors.of(context).muted,
        letterSpacing: AppFoodLabel.brandTracking,
      ),
    );
  }
}
