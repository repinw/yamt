import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Visual tone of an app snack bar.
enum AppSnackBarTone {
  /// An action completed.
  success,

  /// An action failed.
  error,

  /// A neutral notice.
  info,
}

/// Label and callback of a snack bar action other than undo.
typedef AppSnackBarAction = ({String label, VoidCallback onPressed});

/// Shows the one snack bar design of the app.
extension AppSnackBar on ScaffoldMessengerState {
  /// Replaces the current snack bar with [message].
  ///
  /// The snack bar hides itself after the default four seconds, also when it
  /// has an action. [onUndo] adds the undo action; when it completes with
  /// false, a failure snack bar follows. [action] adds a different action;
  /// pass at most one of them. The returned controller tells how the
  /// snack bar closed, for example whether the user tapped undo.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.success,
    Future<bool> Function()? onUndo,
    AppSnackBarAction? action,
  }) {
    assert(
      onUndo == null || action == null,
      'Pass either onUndo or action, not both.',
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground, icon) = switch (tone) {
      AppSnackBarTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle,
      ),
      AppSnackBarTone.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      AppSnackBarTone.info => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.info_outline_rounded,
      ),
    };
    final AppSnackBarAction? effectiveAction;
    if (onUndo == null) {
      effectiveAction = action;
    } else {
      final l10n = AppLocalizations.of(context)!;
      effectiveAction = (
        label: l10n.commonUndoAction,
        onPressed: () => unawaited(_undo(onUndo, l10n.commonUndoFailed)),
      );
    }

    hideCurrentSnackBar();
    return showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: AppInsets.snackBarMargin,
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        persist: false,
        // Keeps the action beside the message, so the snack bar stays one
        // row high.
        actionOverflowThreshold: 1,
        content: Row(
          children: [
            Icon(icon, color: foreground, size: AppSizes.snackBarIcon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: effectiveAction == null
            ? null
            : SnackBarAction(
                label: effectiveAction.label,
                textColor: foreground,
                onPressed: effectiveAction.onPressed,
              ),
      ),
    );
  }

  Future<void> _undo(
    Future<bool> Function() onUndo,
    String failureMessage,
  ) async {
    if (await onUndo() || !mounted) {
      return;
    }
    showAppSnackBar(failureMessage, tone: AppSnackBarTone.error);
  }
}
