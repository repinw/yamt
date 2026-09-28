import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_button_label.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_button_surface.dart';

/// Secondary button of a cooking flow screen: ink text on a soft tile.
class CookingFlowSecondaryActionButton extends StatelessWidget {
  /// Creates the secondary button.
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.padding,
    super.key,
  });

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  /// Optional trailing icon.
  final IconData? icon;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;
    final foreground = isEnabled ? colors.ink : colors.muted;

    return CookingFlowButtonSurface(
      onPressed: onPressed,
      fill: colors.tile,
      foreground: foreground,
      padding: padding,
      child: CookingFlowButtonLabel(
        label: label,
        trailingIcon: icon,
        color: foreground,
      ),
    );
  }
}
