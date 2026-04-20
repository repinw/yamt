import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_eating_window_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

TextStyle? _settingsDropdownTextStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return Theme.of(
    context,
  ).textTheme.labelLarge?.copyWith(color: colors.primary);
}

/// Defines settings page.
class SettingsPage extends StatelessWidget {
  /// The settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final panelRadius = BorderRadius.circular(AppInventoryEditorial.cardRadius);
    final tiles = <Widget>[
      _HouseholdTile(l10n: l10n),
      _AccountTile(l10n: l10n),
      const _DiaryTile(),
      const _HealthConnectTile(),
      const _ThemeModeTile(),
      const _SeedColorTile(),
      _NotImplementedTile(
        icon: Icons.language_outlined,
        title: l10n.settingsLanguageTitle,
        subtitle: l10n.settingsLanguageSubtitle,
        message: l10n.commonNotImplementedYet,
      ),
      _NotImplementedTile(
        icon: Icons.notifications_outlined,
        title: l10n.settingsNotificationsTitle,
        subtitle: l10n.settingsNotificationsSubtitle,
        message: l10n.commonNotImplementedYet,
      ),
      const _AboutTile(),
    ];

    return Padding(
      padding: responsivePagePadding(
        context,
        top: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: DecoratedBox(
        decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
          colors,
          borderRadius: panelRadius,
        ),
        child: ClipRRect(
          borderRadius: panelRadius,
          child: Material(
            color: Colors.transparent,
            child: ListTileTheme(
              iconColor: colors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: tiles.length,
                itemBuilder: (context, index) => tiles[index],
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppInventoryEditorialSurfaces.ghostBorder(colors),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider);
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.settingsAboutTitle),
      subtitle: Text(l10n.settingsAboutSubtitle),
      trailing: switch (version) {
        AsyncData(:final value) => Text(
          value,
          style: theme.textTheme.bodySmall,
        ),
        AsyncLoading() => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        AsyncError() => null,
      },
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.group_outlined),
      title: Text(l10n.settingsHouseholdTitle),
      subtitle: Text(l10n.settingsHouseholdSubtitle),
      onTap: () => context.push(AppRoutes.homeSettingsHousehold),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(l10n.settingsAccountTitle),
      subtitle: Text(l10n.settingsAccountSubtitle),
      onTap: () => context.push(AppRoutes.homeSettingsAccount),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);
    final dropdownTextStyle = _settingsDropdownTextStyle(context);

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.settingsThemeTitle),
      subtitle: Text(localizedThemeModeLabel(l10n, themeMode)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeMode,
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          style: dropdownTextStyle,
          onChanged: (selectedMode) {
            if (selectedMode == null) {
              return;
            }
            unawaited(
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(selectedMode),
            );
          },
          items: [
            for (final mode in ThemeMode.values)
              DropdownMenuItem<ThemeMode>(
                value: mode,
                child: Text(localizedThemeModeLabel(l10n, mode)),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiaryTile extends ConsumerWidget {
  const _DiaryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings =
        ref.watch(calorieGoalControllerProvider).asData?.value ??
        const CalorieGoalSettings.empty();
    final eatingWindowLabel = formatEatingWindowLabel(
      context,
      startMinuteOfDay: settings.normalizedEatingWindowStartMinuteOfDay,
      endMinuteOfDay: settings.normalizedEatingWindowEndMinuteOfDay,
    );

    return ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(l10n.settingsDiaryTitle),
      subtitle: Text(l10n.settingsDiarySubtitle(eatingWindowLabel)),
      onTap: () {
        unawaited(
          showCalorieEatingWindowDialog(
            context: context,
            initialStartMinuteOfDay:
                settings.normalizedEatingWindowStartMinuteOfDay,
            initialEndMinuteOfDay:
                settings.normalizedEatingWindowEndMinuteOfDay,
            onSaveEatingWindow: (startMinuteOfDay, endMinuteOfDay) {
              return ref
                  .read(calorieGoalControllerProvider.notifier)
                  .setEatingWindow(
                    startMinuteOfDay: startMinuteOfDay,
                    endMinuteOfDay: endMinuteOfDay,
                  );
            },
          ),
        );
      },
    );
  }
}

class _SeedColorTile extends ConsumerWidget {
  const _SeedColorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seedColor = ref.watch(seedColorControllerProvider);
    final dropdownTextStyle = _settingsDropdownTextStyle(context);

    return ListTile(
      leading: const Icon(Icons.format_paint_outlined),
      title: Text(l10n.settingsColorTitle),
      subtitle: Text(localizedSeedColorLabel(l10n, seedColor)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: seedColor.toARGB32(),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          style: dropdownTextStyle,
          onChanged: (selectedColorValue) {
            if (selectedColorValue == null) {
              return;
            }
            unawaited(
              ref
                  .read(seedColorControllerProvider.notifier)
                  .setSeedColor(Color(selectedColorValue)),
            );
          },
          items: [
            for (final color in AppSeedColors.values)
              DropdownMenuItem<int>(
                value: color.toARGB32(),
                child: Text(localizedSeedColorLabel(l10n, color)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthConnectTile extends ConsumerWidget {
  const _HealthConnectTile();

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

    return ListTile(
      leading: Icon(
        isUnsupported
            ? Icons.block_outlined
            : showsInstall
            ? Icons.download_for_offline_outlined
            : showsConnect
            ? Icons.favorite_outline
            : Icons.link_off,
      ),
      title: Text(_tileTitle(l10n, status)),
      subtitle: Text(
        isUnsupported
            ? l10n.healthUnsupportedHint
            : showsInstall
            ? l10n.settingsHealthInstallSubtitle
            : showsConnect
            ? needsHistoryOnly
                  ? l10n.settingsHealthHistorySubtitle
                  : _connectSubtitle(l10n, status)
            : _disconnectSubtitle(l10n, status),
      ),
      trailing: statusAsync.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: !statusAsync.isLoading,
      onTap: statusAsync.isLoading
          ? null
          : isUnsupported
          ? null
          : showsInstall
          ? () => _installHealthConnect(ref)
          : showsConnect
          ? () => _connectHealth(context, ref)
          : () => _confirmDisconnect(context, ref),
    );
  }

  Future<void> _connectHealth(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final status = await ref
        .read(healthConnectionControllerProvider.notifier)
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
        .read(healthConnectionControllerProvider.notifier)
        .installHealthConnect();
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsHealthDisconnectDialogTitle),
          content: Text(l10n.settingsHealthDisconnectDialogBody),
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

    final result = await ref
        .read(healthConnectionControllerProvider.notifier)
        .disconnect();
    if (!context.mounted) {
      return;
    }
    final status = ref.read(healthConnectionControllerProvider).asData?.value;
    _showSnackBar(context, _disconnectMessage(l10n, result, status));
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
      HealthDisconnectResult.disconnected =>
        l10n.settingsHealthDisconnectSuccess,
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
}

class _NotImplementedTile extends StatelessWidget {
  const _NotImplementedTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => _showNotImplementedSnackBar(context),
    );
  }

  void _showNotImplementedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
