import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

/// Footer prompt that switches between login and registration.
class AuthFooterPrompt extends StatelessWidget {
  /// Creates an auth footer prompt.
  const AuthFooterPrompt({
    required this.prefixText,
    required this.actionText,
    required this.buttonKey,
    required this.onPressed,
    super.key,
  });

  /// Text before the action.
  final String prefixText;

  /// Action text.
  final String actionText;

  /// Action button key.
  final Key buttonKey;

  /// Action callback.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefixText,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        TextButton(
          key: buttonKey,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}
