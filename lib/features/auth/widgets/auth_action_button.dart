import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/auth_ui_constants.dart';

/// Outlined auth action button with loading state.
class AuthActionButton extends StatelessWidget {
  /// Creates an auth action button.
  const AuthActionButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.minimumHeight,
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  /// Stable key for tests.
  final Key buttonKey;

  /// Button label.
  final String label;

  /// Button icon.
  final Widget icon;

  /// Minimum button height.
  final double minimumHeight;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Whether loading indicator is shown.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(minimumHeight),
        backgroundColor: colors.surfaceContainerLowest,
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppAuthUi.buttonRadius),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: AppSizes.inlineProgressIndicator,
              height: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
                color: colors.primary,
              ),
            )
          : icon,
      label: Text(label),
    );
  }
}
