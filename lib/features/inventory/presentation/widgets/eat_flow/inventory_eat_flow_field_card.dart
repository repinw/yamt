import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_flow/inventory_eat_flow_leading_icon.dart';

/// Shared field card.
class InventoryEatFlowFieldCard extends StatelessWidget {
  /// Creates field card.
  const InventoryEatFlowFieldCard({
    required this.leadingIcon,
    required this.child,
    super.key,
  });

  /// Leading icon.
  final IconData leadingIcon;

  /// Child.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppEditorialSurfaces.ghostBorder(colors),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              InventoryEatFlowLeadingIcon(icon: leadingIcon),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
