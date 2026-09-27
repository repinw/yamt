import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Small round choice of the eat page, such as a ruler mark or a piece
/// size: a pill on the tile surface, filled with ink when selected. The tap
/// target reaches 48 pixels around the visible pill.
class EatChip extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    super.key,
  });

  /// Text of the chip.
  final String label;

  /// Draws the chip filled.
  final bool isSelected;

  /// Called when the chip is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppFoodLabel.chipTapPadding,
        ),
        minimumSize: const Size.square(kMinInteractiveDimension),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? colors.ink : colors.tile,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppFoodLabel.chip),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                  color: isSelected ? colors.paper : colors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
