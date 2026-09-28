import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// One way out of a conflict, as a chip. The chosen one is filled with ink.
class CookingFlowConflictResolutionButton extends StatelessWidget {
  /// Creates the chip.
  const new({
    required this.label,
    required this.isActive,
    required this.onPressed,
    super.key,
  });

  /// Text of the chip.
  final String label;

  /// Whether this way out is chosen.
  final bool isActive;

  /// Chooses this way out.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final foreground = isActive ? colors.paper : colors.ink;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: isActive ? colors.ink : colors.tile,
        minimumSize: const Size(AppGraphit.chipHeight, AppGraphit.chipHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
