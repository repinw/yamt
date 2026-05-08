import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class InventoryMainFabButton extends StatelessWidget {
  const InventoryMainFabButton({
    required this.isBusy,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.buttonKey,
  });

  final bool isBusy;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
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
