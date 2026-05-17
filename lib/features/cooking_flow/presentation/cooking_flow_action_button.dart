import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Primary accent button used across Cookflow screens.
class CookingFlowActionButton extends StatelessWidget {
  /// Creates primary Cookflow action button.
  const CookingFlowActionButton({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.icon,
    this.padding,
    super.key,
  });

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? leadingIcon;

  /// Optional trailing icon.
  final IconData? icon;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;

    return _CookingFlowAccentSurface(
      onPressed: onPressed,
      shadowBlurRadius: 24,
      shadowOffset: const Offset(0, 12),
      child: Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leadingIcon != null) ...<Widget>[
              Icon(
                leadingIcon,
                color: isEnabled ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isEnabled ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                icon,
                color: isEnabled ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CookingFlowAccentSurface extends StatelessWidget {
  const _CookingFlowAccentSurface({
    required this.child,
    required this.onPressed,
    required this.shadowBlurRadius,
    required this.shadowOffset,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    final isEnabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? AppEditorialSurfaces.soulGradient(colors)
            : LinearGradient(
                colors: <Color>[
                  colors.surfaceContainerHighest,
                  colors.surfaceContainerHighest,
                ],
              ),
        borderRadius: radius,
        boxShadow: isEnabled
            ? <BoxShadow>[
                AppEditorialSurfaces.ambientBoxShadow(
                  colors,
                  blurRadius: shadowBlurRadius,
                  offset: shadowOffset,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: child,
        ),
      ),
    );
  }
}

/// Secondary Cookflow action button for lower-priority actions.
class CookingFlowSecondaryActionButton extends StatelessWidget {
  /// Creates secondary Cookflow action button.
  const CookingFlowSecondaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.padding,
    super.key,
  });

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  /// Optional trailing icon.
  final IconData? icon;

  /// Optional inner padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    final isEnabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled
            ? colors.surfaceContainerLowest.withValues(alpha: 0.9)
            : colors.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: isEnabled
              ? colors.outlineVariant.withValues(alpha: 0.5)
              : colors.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isEnabled
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    icon,
                    color: isEnabled
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact accent icon button for Cookflow inline actions.
class CookingFlowActionIconButton extends StatelessWidget {
  /// Creates compact Cookflow accent icon button.
  const CookingFlowActionIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// Button icon.
  final IconData icon;

  /// Press callback.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;

    return _CookingFlowAccentSurface(
      onPressed: onPressed,
      shadowBlurRadius: 18,
      shadowOffset: const Offset(0, 10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            color: isEnabled ? colors.onPrimary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
