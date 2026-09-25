import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Small framed choice of the eat page, such as a ruler mark or a piece
/// size. The tap target reaches 48 pixels around the visible frame.
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
          vertical: AppFoodLabel.rulerMarkTapPadding,
        ),
        minimumSize: const Size.square(kMinInteractiveDimension),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? colors.ink : colors.card,
          border: Border.all(color: colors.ink, width: AppFoodLabel.outline),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppFoodLabel.rulerMark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: AppFonts.mono,
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
