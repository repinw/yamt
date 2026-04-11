import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

class InventoryPrimaryActionButton extends StatelessWidget {
  const InventoryPrimaryActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.showText,
    required this.label,
    required this.width,
    required this.height,
    required this.enabledBackgroundColor,
    required this.disabledBackgroundColor,
    required this.enabledBorderColor,
    required this.disabledBorderColor,
    required this.enabledForegroundColor,
    required this.disabledForegroundColor,
    this.useGradientWhenShowText = true,
    this.icon,
    this.iconSize = AppSpacing.xxl,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final bool showText;
  final String label;
  final double width;
  final double height;
  final Color enabledBackgroundColor;
  final Color disabledBackgroundColor;
  final Color enabledBorderColor;
  final Color disabledBorderColor;
  final Color enabledForegroundColor;
  final Color disabledForegroundColor;
  final bool useGradientWhenShowText;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    final usesSoulGradient = isEnabled && showText && useGradientWhenShowText;
    final backgroundColor = usesSoulGradient
        ? null
        : isEnabled
        ? enabledBackgroundColor
        : disabledBackgroundColor;
    final borderColor = usesSoulGradient
        ? Colors.transparent
        : isEnabled
        ? enabledBorderColor
        : disabledBorderColor;
    final foregroundColor = usesSoulGradient
        ? colors.onPrimary
        : isEnabled
        ? enabledForegroundColor
        : disabledForegroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: usesSoulGradient
            ? AppInventoryEditorialSurfaces.soulGradient(colors)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor),
        boxShadow: [
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 24,
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          splashRadius: AppSpacing.xxl,
          tooltip: tooltip,
          onPressed: onPressed,
          icon: showText
              ? Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontSize: 12,
                  ),
                )
              : Icon(icon, size: iconSize),
          color: foregroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: showText ? AppSpacing.sm : AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}
