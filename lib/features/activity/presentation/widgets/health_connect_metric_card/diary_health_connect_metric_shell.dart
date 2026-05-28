import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Visual shell for the compact Health Connect metric card.
class DiaryHealthConnectMetricShell extends StatelessWidget {
  /// Creates a Health Connect metric shell.
  const DiaryHealthConnectMetricShell({
    required this.accessState,
    required this.hasConnectionError,
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  /// Resolved health data access state.
  final HealthDataAccessState accessState;

  /// Whether the latest connection attempt failed.
  final bool hasConnectionError;

  /// Whether a Health Connect action is in flight.
  final bool isBusy;

  /// Action for the shell and button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accentColor = colors.primary;
    final title = switch (accessState) {
      HealthDataAccessState.installRequired => l10n.diaryHealthInstallTitle,
      HealthDataAccessState.historyRequired => l10n.diaryHealthHistoryTitle,
      HealthDataAccessState.unsupported => l10n.diaryHealthUnsupportedTitle,
      HealthDataAccessState.ready ||
      HealthDataAccessState.permissionRequired => l10n.diaryHealthConnectTitle,
    };
    final body = hasConnectionError
        ? l10n.diaryHealthPermissionDenied
        : switch (accessState) {
            HealthDataAccessState.installRequired =>
              l10n.diaryHealthInstallBody,
            HealthDataAccessState.historyRequired =>
              l10n.diaryHealthHistoryBody,
            HealthDataAccessState.unsupported =>
              l10n.diaryHealthUnsupportedBody,
            HealthDataAccessState.ready ||
            HealthDataAccessState.permissionRequired =>
              l10n.diaryHealthConnectBody,
          };
    final buttonLabel = hasConnectionError
        ? l10n.diaryHealthSettingsAction
        : switch (accessState) {
            HealthDataAccessState.installRequired =>
              l10n.diaryHealthInstallAction,
            HealthDataAccessState.historyRequired =>
              l10n.diaryHealthAllowAction,
            HealthDataAccessState.unsupported =>
              l10n.diaryHealthUnavailableAction,
            HealthDataAccessState.ready ||
            HealthDataAccessState.permissionRequired =>
              l10n.diaryHealthConnectAction,
          };

    return MetricCardFrame(
      clip: false,
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety_rounded, color: accentColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.diaryHealthLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonal(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          buttonLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
