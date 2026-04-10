import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <Widget>[
      _HouseholdTile(l10n: l10n),
      _AccountTile(l10n: l10n),
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

    return ListView.separated(
      padding: AppInsets.listVertical,
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
      separatorBuilder: (context, index) => const Divider(height: 1),
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

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.settingsThemeTitle),
      subtitle: Text(localizedThemeModeLabel(l10n, themeMode)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeMode,
          onChanged: (selectedMode) {
            if (selectedMode == null) {
              return;
            }
            ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(selectedMode);
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

class _SeedColorTile extends ConsumerWidget {
  const _SeedColorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seedColor = ref.watch(seedColorControllerProvider);

    return ListTile(
      leading: const Icon(Icons.format_paint_outlined),
      title: Text(l10n.settingsColorTitle),
      subtitle: Text(localizedSeedColorLabel(l10n, seedColor)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: seedColor.toARGB32(),
          onChanged: (selectedColorValue) {
            if (selectedColorValue == null) {
              return;
            }
            ref
                .read(seedColorControllerProvider.notifier)
                .setSeedColor(Color(selectedColorValue));
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
