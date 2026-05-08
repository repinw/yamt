import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Main inventory floating action button.
class InventoryMainFabButton extends StatelessWidget {
  /// Creates main inventory floating action button.
  const InventoryMainFabButton({
    required this.isBusy,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.buttonKey,
  });

  /// Whether action flow is running.
  final bool isBusy;

  /// Icon shown when idle.
  final IconData icon;

  /// Tooltip text.
  final String tooltip;

  /// Called when user presses the button.
  final VoidCallback? onPressed;

  /// Key for the inner square button used by existing tests.
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = onPressed == null && !isBusy
        ? colors.onSurface.withValues(alpha: 0.38)
        : colors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.primary),
      ),
      child: SizedBox.square(
        key: buttonKey,
        dimension: AppInventoryEditorial.contextFabSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onPressed,
            child: Tooltip(
              message: tooltip,
              child: Center(
                child: _InventoryMainFabIcon(
                  isBusy: isBusy,
                  icon: icon,
                  foregroundColor: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryMainFabIcon extends StatelessWidget {
  const _InventoryMainFabIcon({
    required this.isBusy,
    required this.icon,
    required this.foregroundColor,
  });

  final bool isBusy;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (!isBusy) {
      return Icon(icon, color: foregroundColor, size: 36);
    }

    return SizedBox.square(
      dimension: AppSizes.inlineProgressIndicator,
      child: CircularProgressIndicator(
        color: foregroundColor,
        strokeWidth: AppSizes.progressStrokeWidth,
      ),
    );
  }
}
