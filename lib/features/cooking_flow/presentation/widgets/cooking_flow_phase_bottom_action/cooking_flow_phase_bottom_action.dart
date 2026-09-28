import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_phase_bottom_action/cooking_flow_phase_bottom_surface.dart';

/// Bottom action used by phase pages.
class CookingFlowPhaseBottomAction extends StatelessWidget {
  /// Creates bottom action.
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  /// Button label.
  final String label;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Optional trailing icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CookingFlowPhaseBottomSurface(
      child: SizedBox(
        width: double.infinity,
        child: CookingFlowActionButton(
          label: label,
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}
