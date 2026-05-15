import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';

/// Text-only auth action button with loading state.
class AuthGhostTextButton extends StatelessWidget {
  /// Creates a ghost auth text button.
  const AuthGhostTextButton({
    required this.buttonKey,
    required this.label,
    required this.minimumHeight,
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  /// Stable key for tests.
  final Key buttonKey;

  /// Button label.
  final String label;

  /// Minimum button height.
  final double minimumHeight;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Whether loading indicator is shown.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextButton(
      key: buttonKey,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(minimumHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CredentialFormUi.buttonRadius),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: AppSizes.inlineProgressIndicator,
              height: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
                color: colors.primary,
              ),
            )
          : Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
    );
  }
}
