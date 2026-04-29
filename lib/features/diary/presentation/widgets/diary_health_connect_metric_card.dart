part of 'diary_activity_weight_cards.dart';

class _HealthConnectMetricCard extends ConsumerWidget {
  const _HealthConnectMetricCard({required this.accessState});

  final HealthDataAccessState accessState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(healthConnectionControllerProvider);
    final controller = ref.read(healthConnectionControllerProvider.notifier);
    final status = statusState.asData?.value;
    final latestAccessState = statusState.asData?.value.accessState;
    final hasConnectionError = status?.errorMessage != null;
    final needsAppPermissionSettings =
        status?.errorMessage == healthActivityRecognitionPermissionErrorMessage;
    final resolvedAccessState = switch (latestAccessState) {
      HealthDataAccessState.ready => HealthDataAccessState.ready,
      HealthDataAccessState.unsupported => accessState,
      null => accessState,
      _ => latestAccessState,
    };
    final isBusy = statusState.isLoading;
    final action = switch (resolvedAccessState) {
      HealthDataAccessState.permissionRequired ||
      HealthDataAccessState.historyRequired =>
        hasConnectionError
            ? needsAppPermissionSettings
                  ? controller.openAppPermissionSettings
                  : controller.openHealthPermissionSettings
            : controller.connect,
      HealthDataAccessState.installRequired => controller.installHealthConnect,
      HealthDataAccessState.ready || HealthDataAccessState.unsupported => null,
    };
    final effectiveAction = isBusy ? null : action;

    return _HealthConnectCardShell(
      accessState: resolvedAccessState,
      hasConnectionError: hasConnectionError,
      isBusy: isBusy,
      onPressed: effectiveAction == null
          ? null
          : () => unawaited(effectiveAction()),
    );
  }
}

class _HealthConnectCardShell extends StatelessWidget {
  const _HealthConnectCardShell({
    required this.accessState,
    required this.hasConnectionError,
    required this.isBusy,
    required this.onPressed,
  });

  final HealthDataAccessState accessState;
  final bool hasConnectionError;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = colors.primary;
    final title = switch (accessState) {
      HealthDataAccessState.installRequired => 'Health installieren',
      HealthDataAccessState.historyRequired => 'Verlauf erlauben',
      HealthDataAccessState.unsupported => 'Health nicht verfügbar',
      HealthDataAccessState.ready ||
      HealthDataAccessState.permissionRequired => 'Health verbinden',
    };
    final body = hasConnectionError
        ? 'Berechtigung wurde nicht erteilt.'
        : switch (accessState) {
            HealthDataAccessState.installRequired =>
              'Für Schritte und Aktivität.',
            HealthDataAccessState.historyRequired =>
              'Für ältere Tage erlauben.',
            HealthDataAccessState.unsupported =>
              'Auf diesem Gerät nicht verfügbar.',
            HealthDataAccessState.ready ||
            HealthDataAccessState.permissionRequired =>
              'Schritte und Aktivität verbinden.',
          };
    final buttonLabel = hasConnectionError
        ? 'Einstellungen'
        : switch (accessState) {
            HealthDataAccessState.installRequired => 'Installieren',
            HealthDataAccessState.historyRequired => 'Erlauben',
            HealthDataAccessState.unsupported => 'Nicht verfügbar',
            HealthDataAccessState.ready ||
            HealthDataAccessState.permissionRequired => 'Verbinden',
          };

    return DiaryMetricCardFrame(
      clip: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
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
                        'HEALTH',
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
