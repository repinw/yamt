import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

void showAccountStatusSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final theme = Theme.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final backgroundColor = isError
      ? theme.colorScheme.errorContainer
      : theme.colorScheme.primaryContainer;
  final foregroundColor = isError
      ? theme.colorScheme.onErrorContainer
      : theme.colorScheme.onPrimaryContainer;
  final icon = isError ? Icons.error_outline_rounded : Icons.check_circle;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: AppInsets.snackBarMargin,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: Row(
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
