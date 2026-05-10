import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Defines credential conflict action.
enum CredentialConflictAction {
  /// Documented member.
  overwriteWithGuest,

  /// Documented member.
  deleteGuestAndSignInWithGoogle,
}

/// Defines credential conflict dialog.
class CredentialConflictDialog extends StatelessWidget {
  /// The credential conflict dialog.
  const CredentialConflictDialog({
    required this.title,
    required this.description,
    required this.overwriteAction,
    required this.overwriteSubtitle,
    required this.deleteGuestAction,
    required this.deleteGuestSubtitle,
    required this.cancelLabel,
    required this.onCancel,
    required this.onOverwrite,
    required this.onDeleteGuestAndContinue,
    super.key,
  });

  /// The title.
  final String title;

  /// The description.
  final String description;

  /// The overwrite action.
  final String overwriteAction;

  /// The overwrite subtitle.
  final String overwriteSubtitle;

  /// The delete guest action.
  final String deleteGuestAction;

  /// The delete guest subtitle.
  final String deleteGuestSubtitle;

  /// The cancel label.
  final String cancelLabel;

  /// The on cancel.
  final VoidCallback onCancel;

  /// The on overwrite.
  final VoidCallback onOverwrite;

  /// The on delete guest and continue.
  final VoidCallback onDeleteGuestAndContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: AppInsets.dialogInset,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: AppSizes.dialogIconContainer,
                height: AppSizes.dialogIconContainer,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_off_rounded,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _ConflictActionTile(
              icon: Icons.swap_horiz_rounded,
              title: overwriteAction,
              subtitle: overwriteSubtitle,
              onTap: onOverwrite,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ConflictActionTile(
              icon: Icons.delete_outline_rounded,
              title: deleteGuestAction,
              subtitle: deleteGuestSubtitle,
              onTap: onDeleteGuestAndContinue,
              destructive: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onCancel, child: Text(cancelLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictActionTile extends StatelessWidget {
  const _ConflictActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final containerColor = destructive
        ? colorScheme.errorContainer.withValues(alpha: 0.55)
        : colorScheme.secondaryContainer.withValues(alpha: 0.45);
    final iconColor = destructive
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;
    final borderColor = destructive
        ? colorScheme.error.withValues(alpha: 0.35)
        : colorScheme.outline.withValues(alpha: 0.35);

    return Material(
      color: containerColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          padding: AppInsets.actionTilePadding,
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppSizes.actionChevron,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
