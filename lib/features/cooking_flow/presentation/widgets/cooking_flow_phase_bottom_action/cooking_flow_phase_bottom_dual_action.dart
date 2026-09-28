import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_quiet_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_phase_bottom_action/cooking_flow_phase_bottom_surface.dart';

/// Bottom action with secondary and primary button.
class CookingFlowPhaseBottomDualAction extends StatelessWidget {
  /// Creates dual action.
  const new({
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.primaryLeadingIcon,
    this.primaryTrailingIcon,
    super.key,
  });

  /// Secondary label.
  final String secondaryLabel;

  /// Secondary tap callback.
  final VoidCallback? onSecondaryPressed;

  /// Primary label.
  final String primaryLabel;

  /// Primary tap callback.
  final VoidCallback? onPrimaryPressed;

  /// Optional leading icon.
  final IconData? primaryLeadingIcon;

  /// Optional trailing icon.
  final IconData? primaryTrailingIcon;

  @override
  Widget build(BuildContext context) {
    return CookingFlowPhaseBottomSurface(
      child: Row(
        children: <Widget>[
          CookingFlowQuietButton(
            label: secondaryLabel,
            onPressed: onSecondaryPressed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: CookingFlowActionButton(
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              leadingIcon: primaryLeadingIcon,
              icon: primaryTrailingIcon,
            ),
          ),
        ],
      ),
    );
  }
}
