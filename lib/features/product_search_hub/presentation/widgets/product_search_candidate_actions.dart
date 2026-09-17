import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared candidate action buttons.
class InventoryProductCandidateActions extends StatelessWidget {
  /// The candidate action buttons.
  const new({
    required this.inventoryLabel,
    required this.eatLabel,
    required this.onInventory,
    required this.onEat,
    super.key,
    this.inventoryButtonKey,
    this.eatButtonKey,
    this.showInventoryAction = true,
  });

  /// Inventory label.
  final String inventoryLabel;

  /// Eat label.
  final String eatLabel;

  /// Inventory action.
  final VoidCallback onInventory;

  /// Eat action.
  final VoidCallback onEat;

  /// Optional inventory button key.
  final Key? inventoryButtonKey;

  /// Optional eat button key.
  final Key? eatButtonKey;

  /// Whether inventory action is visible.
  final bool showInventoryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 86),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showInventoryAction) ...[
                  _InventoryCandidateActionButton(
                    buttonKey: inventoryButtonKey,
                    tooltip: inventoryLabel,
                    icon: Icons.inventory_2_outlined,
                    onPressed: onInventory,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _InventoryCandidateActionButton(
                  buttonKey: eatButtonKey,
                  tooltip: eatLabel,
                  icon: Icons.restaurant_menu_outlined,
                  onPressed: onEat,
                  highlighted: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCandidateActionButton extends StatelessWidget {
  const new({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.buttonKey,
    this.highlighted = false,
  });

  final Key? buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = highlighted
        ? colors.primaryContainer
        : colors.surfaceContainerHigh;
    final foregroundColor = highlighted
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final borderColor = highlighted
        ? colors.primary.withValues(alpha: 0.35)
        : colors.outlineVariant.withValues(alpha: 0.7);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(46),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          shadowColor: highlighted
              ? colors.primary.withValues(alpha: 0.22)
              : Colors.transparent,
          elevation: highlighted ? 4 : 0,
        ),
      ),
    );
  }
}
