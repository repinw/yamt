import 'package:flutter/material.dart';

const _expandIndicatorAnimationDuration = Duration(milliseconds: 220);
const _expandIndicatorSize = 32.0;
const _expandIndicatorIconSize = 20.0;

/// Defines inventory expand indicator.
class InventoryExpandIndicator extends StatelessWidget {
  /// The inventory expand indicator.
  const InventoryExpandIndicator({
    required this.isExpanded,
    super.key,
    this.rotationKey,
    this.enabled = true,
    this.width = _expandIndicatorSize,
    this.height = _expandIndicatorSize,
    this.iconSize = _expandIndicatorIconSize,
  });

  /// Whether expanded.
  final bool isExpanded;

  /// The rotation key.
  final Key? rotationKey;

  /// The enabled.
  final bool enabled;

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The icon size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = _borderColor(colors);
    final backgroundColor = _backgroundColor(colors);
    final iconColor = _iconColor(colors);

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: _expandIndicatorAnimationDuration,
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: AnimatedRotation(
            key: rotationKey,
            duration: _expandIndicatorAnimationDuration,
            curve: Curves.easeOutCubic,
            turns: isExpanded ? 0.5 : 0,
            child: Icon(
              Icons.expand_more_rounded,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _borderColor(ColorScheme colors) {
    if (!enabled) {
      return colors.outlineVariant.withValues(alpha: 0.32);
    }
    if (isExpanded) {
      return colors.primary.withValues(alpha: 0.24);
    }
    return colors.outlineVariant.withValues(alpha: 0.6);
  }

  Color _backgroundColor(ColorScheme colors) {
    if (!enabled) {
      return colors.surfaceContainerHighest.withValues(alpha: 0.5);
    }
    if (isExpanded) {
      return colors.primaryContainer.withValues(alpha: 0.72);
    }
    return colors.surfaceContainerHigh.withValues(alpha: 0.82);
  }

  Color _iconColor(ColorScheme colors) {
    if (!enabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.55);
    }
    if (isExpanded) {
      return colors.primary;
    }
    return colors.onSurfaceVariant;
  }
}
