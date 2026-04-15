import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class DiaryHealthCardFrame extends StatelessWidget {
  const DiaryHealthCardFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class DiaryHealthAccessPrompt extends StatelessWidget {
  const DiaryHealthAccessPrompt({
    super.key,
    required this.accessState,
    required this.isBusy,
    required this.permissionBody,
    required this.historyBody,
    required this.installBody,
    required this.unsupportedBody,
    required this.onGrantAccess,
    required this.onGrantHistoryAccess,
    required this.onInstallHealthConnect,
  });

  final HealthDataAccessState accessState;
  final bool isBusy;
  final String permissionBody;
  final String historyBody;
  final String installBody;
  final String unsupportedBody;
  final Future<Object?> Function() onGrantAccess;
  final Future<Object?> Function() onGrantHistoryAccess;
  final Future<Object?> Function() onInstallHealthConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = switch (accessState) {
      HealthDataAccessState.ready => permissionBody,
      HealthDataAccessState.permissionRequired => permissionBody,
      HealthDataAccessState.historyRequired => historyBody,
      HealthDataAccessState.installRequired => installBody,
      HealthDataAccessState.unsupported => unsupportedBody,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        if (isBusy) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(),
        ],
        if (accessState == HealthDataAccessState.permissionRequired ||
            accessState == HealthDataAccessState.historyRequired ||
            accessState == HealthDataAccessState.installRequired) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: isBusy
                ? null
                : switch (accessState) {
                    HealthDataAccessState.installRequired =>
                      onInstallHealthConnect,
                    HealthDataAccessState.historyRequired =>
                      onGrantHistoryAccess,
                    HealthDataAccessState.permissionRequired ||
                    HealthDataAccessState.ready ||
                    HealthDataAccessState.unsupported => onGrantAccess,
                  },
            child: Text(switch (accessState) {
              HealthDataAccessState.installRequired => l10n.healthInstallAction,
              HealthDataAccessState.historyRequired => l10n.healthHistoryAction,
              HealthDataAccessState.permissionRequired ||
              HealthDataAccessState.ready ||
              HealthDataAccessState.unsupported =>
                l10n.settingsHealthConnectTitle,
            }),
          ),
        ],
      ],
    );
  }
}

class DiaryHealthConnectionPrompt extends ConsumerWidget {
  const DiaryHealthConnectionPrompt({
    super.key,
    required this.accessState,
    required this.androidPermissionBody,
    required this.iosPermissionBody,
    required this.historyBody,
    required this.installBody,
    required this.unsupportedBody,
  });

  final HealthDataAccessState accessState;
  final String androidPermissionBody;
  final String iosPermissionBody;
  final String historyBody;
  final String installBody;
  final String unsupportedBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(healthConnectionControllerProvider);
    final status = statusAsync.asData?.value;
    final controller = ref.read(healthConnectionControllerProvider.notifier);

    return DiaryHealthAccessPrompt(
      accessState: accessState,
      isBusy: statusAsync.isLoading,
      permissionBody: switch (status?.platform) {
        HealthPlatform.ios => iosPermissionBody,
        _ => androidPermissionBody,
      },
      historyBody: historyBody,
      installBody: installBody,
      unsupportedBody: unsupportedBody,
      onGrantAccess: () => controller.requestAuthorization(),
      onGrantHistoryAccess: () => controller.requestHistoryAuthorization(),
      onInstallHealthConnect: () => controller.installHealthConnect(),
    );
  }
}
