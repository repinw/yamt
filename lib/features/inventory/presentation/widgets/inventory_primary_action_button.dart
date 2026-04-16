import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Defines inventory primary action button.
class InventoryPrimaryActionButton extends StatelessWidget {
  /// The inventory primary action button.
  const InventoryPrimaryActionButton({
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
    super.key,
    this.useGradientWhenShowText = true,
    this.icon,
    this.iconSize = AppSpacing.xxl,
  });

  /// The tooltip.
  final String tooltip;

  /// The on pressed.
  final VoidCallback? onPressed;

  /// The show text.
  final bool showText;

  /// The label.
  final String label;

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The enabled background color.
  final Color enabledBackgroundColor;

  /// The disabled background color.
  final Color disabledBackgroundColor;

  /// The enabled border color.
  final Color enabledBorderColor;

  /// The disabled border color.
  final Color disabledBorderColor;

  /// The enabled foreground color.
  final Color enabledForegroundColor;

  /// The disabled foreground color.
  final Color disabledForegroundColor;

  /// Whether gradient when show text.
  final bool useGradientWhenShowText;

  /// The icon.
  final IconData? icon;

  /// The icon size.
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
