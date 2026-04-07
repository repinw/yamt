import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

const _expandIndicatorAnimationDuration = Duration(milliseconds: 220);
const _expandIndicatorSize = 32.0;
const _expandIndicatorIconSize = 20.0;

class InventoryExpandIndicator extends StatelessWidget {
  const InventoryExpandIndicator({
    super.key,
    required this.isExpanded,
    this.rotationKey,
    this.enabled = true,
  });

  final bool isExpanded;
  final Key? rotationKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = enabled
        ? isExpanded
              ? colors.primary.withValues(alpha: 0.24)
              : colors.outlineVariant.withValues(alpha: 0.6)
        : colors.outlineVariant.withValues(alpha: 0.32);
    final backgroundColor = enabled
        ? isExpanded
              ? colors.primaryContainer.withValues(alpha: 0.72)
              : colors.surfaceContainerHigh.withValues(alpha: 0.82)
        : colors.surfaceContainerHighest.withValues(alpha: 0.5);
    final iconColor = enabled
        ? isExpanded
              ? colors.primary
              : colors.onSurfaceVariant
        : colors.onSurfaceVariant.withValues(alpha: 0.55);

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: _expandIndicatorAnimationDuration,
        curve: Curves.easeOutCubic,
        width: _expandIndicatorSize,
        height: _expandIndicatorSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
              size: _expandIndicatorIconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
