import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _onNotImplementedTap(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.commonNotImplementedYet)));
  }

  void _openAccountPage(BuildContext context) {
    context.push(AppRoutes.homeSettingsAccount);
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  String _seedColorLabel(AppLocalizations l10n, Color color) {
    return switch (color.toARGB32()) {
      0xFF29F006 => l10n.settingsColorLime,
      0xFF0D47A1 => l10n.settingsColorBlue,
      0xFF00695C => l10n.settingsColorTeal,
      0xFFAD1457 => l10n.settingsColorPink,
      0xFFE65100 => l10n.settingsColorOrange,
      _ => l10n.settingsColorLime,
    };
  }

  Widget _themeModeTile(
    AppLocalizations l10n,
    ThemeMode themeMode,
    WidgetRef ref,
  ) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.settingsThemeTitle),
      subtitle: Text(_themeModeLabel(l10n, themeMode)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeMode,
          onChanged: (selectedMode) {
            if (selectedMode == null) return;
            ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(selectedMode);
          },
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(l10n.settingsThemeSystem),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(l10n.settingsThemeLight),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(l10n.settingsThemeDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorTile(AppLocalizations l10n, Color seedColor, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.format_paint_outlined),
      title: Text(l10n.settingsColorTitle),
      subtitle: Text(_seedColorLabel(l10n, seedColor)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: seedColor.toARGB32(),
          onChanged: (selectedColorValue) {
            if (selectedColorValue == null) return;
            ref
                .read(seedColorControllerProvider.notifier)
                .setSeedColor(Color(selectedColorValue));
          },
          items: [
            for (final color in AppSeedColors.values)
              DropdownMenuItem<int>(
                value: color.toARGB32(),
                child: Text(_seedColorLabel(l10n, color)),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tiles(
    AppLocalizations l10n,
    BuildContext context,
    ThemeMode themeMode,
    Color seedColor,
    WidgetRef ref,
  ) {
    return [
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.settingsAccountTitle),
        subtitle: Text(l10n.settingsAccountSubtitle),
        onTap: () => _openAccountPage(context),
      ),
      _themeModeTile(l10n, themeMode, ref),
      _colorTile(l10n, seedColor, ref),
      ListTile(
        leading: const Icon(Icons.language_outlined),
        title: Text(l10n.settingsLanguageTitle),
        subtitle: Text(l10n.settingsLanguageSubtitle),
        onTap: () => _onNotImplementedTap(context, l10n),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(l10n.settingsNotificationsTitle),
        subtitle: Text(l10n.settingsNotificationsSubtitle),
        onTap: () => _onNotImplementedTap(context, l10n),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settingsAboutTitle),
        subtitle: Text(l10n.settingsAboutSubtitle),
        onTap: () => _onNotImplementedTap(context, l10n),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);
    final seedColor = ref.watch(seedColorControllerProvider);
    final tiles = _tiles(l10n, context, themeMode, seedColor, ref);

    return ListView.separated(
      padding: AppInsets.listVertical,
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }
}
