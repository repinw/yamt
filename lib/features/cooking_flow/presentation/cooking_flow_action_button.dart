import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Main button of a cooking flow screen: filled lime with dark text.
///
/// Lime marks one thing per screen, so every other action uses
/// [CookingFlowSecondaryActionButton] or [CookingFlowQuietButton].
class CookingFlowActionButton extends StatelessWidget {
  /// Creates the main button.
  const new({
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
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;

    return _CookingFlowButtonSurface(
      onPressed: onPressed,
      fill: isEnabled ? colors.accent : colors.tile,
      foreground: isEnabled ? colors.onAccent : colors.muted,
      padding: padding,
      child: _CookingFlowButtonLabel(
        label: label,
        leadingIcon: leadingIcon,
        trailingIcon: icon,
        color: isEnabled ? colors.onAccent : colors.muted,
      ),
    );
  }
}

/// Secondary button of a cooking flow screen: ink text on a soft tile.
class CookingFlowSecondaryActionButton extends StatelessWidget {
  /// Creates the secondary button.
  const new({
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
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;
    final foreground = isEnabled ? colors.ink : colors.muted;

    return _CookingFlowButtonSurface(
      onPressed: onPressed,
      fill: colors.tile,
      foreground: foreground,
      padding: padding,
      child: _CookingFlowButtonLabel(
        label: label,
        trailingIcon: icon,
        color: foreground,
      ),
    );
  }
}

/// Quiet button for "Später" or "Zurücksetzen": underlined ink text, no fill.
class CookingFlowQuietButton extends StatelessWidget {
  /// Creates the quiet button.
  const new({required this.label, required this.onPressed, super.key});

  /// Button label.
  final String label;

  /// Press callback.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final isEnabled = onPressed != null;
    final foreground = isEnabled ? colors.ink : colors.muted;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(
          AppGraphit.buttonHeight,
          AppGraphit.buttonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: foreground,
        ),
      ),
    );
  }
}

class _CookingFlowButtonSurface extends StatelessWidget {
  const new({
    required this.child,
    required this.onPressed,
    required this.fill,
    required this.foreground,
    required this.padding,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color fill;
  final Color foreground;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : AppGraphit.disabledOpacity,
      child: Material(
        color: fill,
        borderRadius: radius,
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppGraphit.buttonHeight,
            ),
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              // Fills the width it is given and no more height than the
              // label needs.
              child: Align(
                heightFactor: 1,
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CookingFlowButtonLabel extends StatelessWidget {
  const new({
    required this.label,
    required this.color,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final Color color;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (leadingIcon != null) ...<Widget>[
          Icon(leadingIcon, size: AppGraphit.toolIcon),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailingIcon != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Icon(trailingIcon, size: AppGraphit.toolIcon),
        ],
      ],
    );
  }
}
