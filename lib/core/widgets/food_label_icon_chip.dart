import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Small top bar button of the food label look: a lime icon in a thick ink
/// frame.
class FoodLabelIconChip extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  /// Icon inside the frame.
  final IconData icon;

  /// Tooltip and semantics label.
  final String tooltip;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Tooltip(
      message: tooltip,
      child: AppInkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTapTarget,
            minHeight: AppSizes.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.ink,
                  width: AppFoodLabel.outline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                child: Icon(icon, color: colors.accentText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
