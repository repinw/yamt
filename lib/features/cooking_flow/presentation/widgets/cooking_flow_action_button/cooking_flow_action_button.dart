import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_button_label.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_button_surface.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_quiet_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_secondary_action_button.dart';

/// Main button of a cooking flow screen: filled lime with dark text.
///
/// Lime marks one thing per screen, so every other action uses
/// [CookingFlowSecondaryActionButton] or [CookingFlowQuietButton].
class CookingFlowActionButton extends StatelessWidget {
  /// Creates the main button.
  const new({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.icon,
    this.padding,
    super.key,
  });

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? leadingIcon;

  /// Optional trailing icon.
  final IconData? icon;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;

    return CookingFlowButtonSurface(
      onPressed: onPressed,
      fill: isEnabled ? colors.accent : colors.tile,
      foreground: isEnabled ? colors.onAccent : colors.muted,
      padding: padding,
      child: CookingFlowButtonLabel(
        label: label,
        leadingIcon: leadingIcon,
        trailingIcon: icon,
        color: isEnabled ? colors.onAccent : colors.muted,
      ),
    );
  }
}
