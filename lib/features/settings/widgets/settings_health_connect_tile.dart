import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/application/'
    'calorie_health_connection_actions.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'health_connection_controller.dart';
import 'package:yamt/features/settings/settings_page_keys.dart';
import 'package:yamt/features/settings/widgets/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Health Connect/Apple Health settings row.
class SettingsHealthConnectTile extends ConsumerWidget {
  /// Creates the health connection settings row.
  const SettingsHealthConnectTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(healthConnectionControllerProvider);
    final status = statusAsync.asData?.value;
    final accessState = status?.accessState;
    final isUnsupported = accessState == HealthDataAccessState.unsupported;
    final showsInstall = accessState == HealthDataAccessState.installRequired;
    final showsConnect =
        status == null ||
        accessState == HealthDataAccessState.permissionRequired ||
        accessState == HealthDataAccessState.historyRequired;
    final needsHistoryOnly = status?.needsHistoryOnly ?? false;
    final shouldOpenPermissionSettings =
        showsConnect && status?.errorMessage != null;
    final shouldOpenAppPermissionSettings =
        status?.errorMessage == healthActivityRecognitionPermissionErrorMessage;

    return SettingsTile(
      key: SettingsPageKeys.healthConnectTile,
      icon: isUnsupported
          ? Icons.block_outlined
          : showsInstall
          ? Icons.download_for_offline_outlined
          : showsConnect
          ? Icons.favorite_border_rounded
          : Icons.link_off_rounded,
      title: _tileTitle(l10n, status),
      subtitle: isUnsupported
          ? l10n.healthUnsupportedHint
          : showsInstall
          ? l10n.settingsHealthInstallSubtitle
          : showsConnect
          ? needsHistoryOnly
                ? l10n.settingsHealthHistorySubtitle
                : _connectSubtitle(l10n, status)
          : _disconnectSubtitle(l10n, status),
      trailing: statusAsync.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: !statusAsync.isLoading && !isUnsupported,
      onTap: statusAsync.isLoading || isUnsupported
          ? null
          : showsInstall
          ? () => _installHealthConnect(ref)
          : showsConnect
          ? shouldOpenPermissionSettings
                ? shouldOpenAppPermissionSettings
                      ? () => unawaited(
                          ref
                              .read(calorieHealthConnectionActionsProvider)
                              .openAppPermissionSettings(),
                        )
                      : () => unawaited(
                          ref
                              .read(calorieHealthConnectionActionsProvider)
                              .openHealthPermissionSettings(),
                        )
                : () => _connectHealth(context, ref)
          : () => _confirmDisconnect(context, status),
    );
  }

  Future<void> _connectHealth(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await ref
        .read(calorieHealthConnectionActionsProvider)
        .connect();
    if (!context.mounted) {
      return;
    }
    if (_shouldShowConnectFailure(status)) {
      _showSnackBar(context, l10n.settingsHealthConnectFailed);
    }
  }

  Future<void> _installHealthConnect(WidgetRef ref) async {
    await ref
        .read(calorieHealthConnectionActionsProvider)
        .installHealthConnect();
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    HealthConnectionStatus? status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsHealthDisconnectDialogTitle),
          content: Text(_disconnectDialogBody(l10n, status)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settingsHealthDisconnectAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final result = await container
        .read(calorieHealthConnectionActionsProvider)
        .disconnect();
    if (!context.mounted) {
      return;
    }
    final nextStatus = container
        .read(healthConnectionControllerProvider)
        .asData
        ?.value;
    _showSnackBar(context, _disconnectMessage(l10n, result, nextStatus));
  }

  bool _shouldShowConnectFailure(HealthConnectionStatus status) {
    return status.errorMessage != null ||
        status.accessState == HealthDataAccessState.permissionRequired ||
        status.accessState == HealthDataAccessState.historyRequired ||
        status.accessState == HealthDataAccessState.installRequired ||
        status.accessState == HealthDataAccessState.unsupported;
  }

  String _disconnectMessage(
    AppLocalizations l10n,
    HealthDisconnectResult result,
    HealthConnectionStatus? status,
  ) {
    return switch (result) {
      HealthDisconnectResult.disconnected => switch (status?.platform) {
        HealthPlatform.ios => l10n.settingsAppleHealthDisconnectSuccess,
        _ => l10n.settingsHealthDisconnectSuccess,
      },
      HealthDisconnectResult.openedSettings =>
        l10n.settingsHealthDisconnectOpenedSettings,
      HealthDisconnectResult.unsupported =>
        status?.errorMessage != null
            ? l10n.settingsHealthDisconnectFailed
            : l10n.healthUnsupportedHint,
    };
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _tileTitle(AppLocalizations l10n, HealthConnectionStatus? status) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthTitle,
      _ => l10n.settingsHealthConnectPlatformTitle,
    };
  }

  String _connectSubtitle(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthConnectSubtitle,
      _ => l10n.settingsHealthConnectSubtitle,
    };
  }

  String _disconnectSubtitle(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthDisconnectSubtitle,
      _ => l10n.settingsHealthDisconnectSubtitle,
    };
  }

  String _disconnectDialogBody(
    AppLocalizations l10n,
    HealthConnectionStatus? status,
  ) {
    return switch (status?.platform) {
      HealthPlatform.ios => l10n.settingsAppleHealthDisconnectDialogBody,
      _ => l10n.settingsHealthDisconnectDialogBody,
    };
  }
}
