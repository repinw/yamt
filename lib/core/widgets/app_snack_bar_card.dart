import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// The card of the app's snack bar: [icon], [message] and an optional
/// action on [background], with a handle that shows it can be swiped up.
class AppSnackBarCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
    this.actionLabel,
    this.onAction,
    this.wrapText,
    super.key,
  });

  /// The text.
  final String message;

  /// The icon before the text.
  final IconData icon;

  /// The card color.
  final Color background;

  /// The color of the text, the icon, and the action.
  final Color foreground;

  /// Label of the action beside the text, if any.
  final String? actionLabel;

  /// Called when the user taps the action.
  final VoidCallback? onAction;

  /// Wraps the text and the action's label, for example to give them their
  /// own tap in a preview.
  final Widget Function(Widget text)? wrapText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = this.actionLabel;
    final wrap = wrapText ?? (text) => text;
    return Material(
      color: background,
      elevation: AppSizes.snackBarElevation,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: foreground, size: AppSizes.snackBarIcon),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: wrap(
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: foreground),
                    onPressed: onAction,
                    child: wrap(Text(actionLabel)),
                  ),
              ],
            ),
            // Shows that the card can be swiped up.
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(
                  alpha: AppOpacities.snackBarHandle,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(
                width: AppSizes.snackBarHandleWidth,
                height: AppSizes.snackBarHandleHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
