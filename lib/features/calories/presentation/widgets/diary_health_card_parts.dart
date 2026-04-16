import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines diary health card frame.
class DiaryHealthCardFrame extends StatelessWidget {
  /// The diary health card frame.
  const DiaryHealthCardFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  /// The title.
  final String title;

  /// The subtitle.
  final String subtitle;

  /// The child.
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

/// Defines diary health access prompt.
class DiaryHealthAccessPrompt extends StatelessWidget {
  /// The diary health access prompt.
  const DiaryHealthAccessPrompt({
    required this.accessState,
    required this.isBusy,
    required this.permissionBody,
    required this.historyBody,
    required this.installBody,
    required this.unsupportedBody,
    required this.onGrantAccess,
    required this.onGrantHistoryAccess,
    required this.onInstallHealthConnect,
    super.key,
  });

  /// The access state.
  final HealthDataAccessState accessState;

  /// Whether busy.
  final bool isBusy;

  /// The permission body.
  final String permissionBody;

  /// The history body.
  final String historyBody;

  /// The install body.
  final String installBody;

  /// The unsupported body.
  final String unsupportedBody;

  /// The on grant access.
  final Future<Object?> Function() onGrantAccess;

  /// The on grant history access.
  final Future<Object?> Function() onGrantHistoryAccess;

  /// The on install health connect.
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

/// Defines diary health connection prompt.
class DiaryHealthConnectionPrompt extends ConsumerWidget {
  /// The diary health connection prompt.
  const DiaryHealthConnectionPrompt({
    required this.accessState,
    required this.androidPermissionBody,
    required this.iosPermissionBody,
    required this.historyBody,
    required this.installBody,
    required this.unsupportedBody,
    super.key,
  });

  /// The access state.
  final HealthDataAccessState accessState;

  /// The android permission body.
  final String androidPermissionBody;

  /// The ios permission body.
  final String iosPermissionBody;

  /// The history body.
  final String historyBody;

  /// The install body.
  final String installBody;

  /// The unsupported body.
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
      onGrantAccess: controller.requestAuthorization,
      onGrantHistoryAccess: controller.requestHistoryAuthorization,
      onInstallHealthConnect: controller.installHealthConnect,
    );
  }
}
