import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_field_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_leading_icon.dart';

/// Shared field card.
class InventoryEatFlowFieldCard extends StatelessWidget {
  /// Creates field card.
  const new({required this.leadingIcon, required this.child, super.key});

  /// Leading icon.
  final IconData leadingIcon;

  /// Child.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppFieldCard(
      child: Row(
        children: [
          InventoryEatFlowLeadingIcon(icon: leadingIcon),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}
