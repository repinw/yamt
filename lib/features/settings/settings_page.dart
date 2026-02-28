import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/features/settings/provider/ai_processing_level_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <Widget>[
      _AccountTile(l10n: l10n),
      const _ThemeModeTile(),
      const _SeedColorTile(),
      const _AiProcessingLevelTile(),
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
      _NotImplementedTile(
        icon: Icons.info_outline,
        title: l10n.settingsAboutTitle,
        subtitle: l10n.settingsAboutSubtitle,
        message: l10n.commonNotImplementedYet,
      ),
    ];

    return ListView.separated(
      padding: AppInsets.listVertical,
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
      separatorBuilder: (context, index) => const Divider(height: 1),
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

class _AiProcessingLevelTile extends ConsumerWidget {
  const _AiProcessingLevelTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final aiProcessingLevel = ref.watch(aiProcessingLevelControllerProvider);

    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(l10n.settingsAiProcessingTitle),
      subtitle: Text(l10n.settingsAiProcessingSubtitle),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.settingsAiProcessingInfoLabel,
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAiProcessingInfo(context, l10n),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<AiProcessingLevel>(
              value: aiProcessingLevel,
              onChanged: (selectedLevel) {
                if (selectedLevel == null) {
                  return;
                }
                ref
                    .read(aiProcessingLevelControllerProvider.notifier)
                    .setLevel(selectedLevel);
              },
              items: [
                for (final option in AiProcessingLevel.values)
                  DropdownMenuItem<AiProcessingLevel>(
                    value: option,
                    child: Text(_aiProcessingLevelLabel(l10n, option)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _aiProcessingLevelLabel(
    AppLocalizations l10n,
    AiProcessingLevel level,
  ) {
    return switch (level) {
      AiProcessingLevel.minimal => l10n.settingsAiProcessingMinimal,
      AiProcessingLevel.low => l10n.settingsAiProcessingLow,
      AiProcessingLevel.balanced => l10n.settingsAiProcessingBalanced,
      AiProcessingLevel.high => l10n.settingsAiProcessingHigh,
    };
  }

  Future<void> _showAiProcessingInfo(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final material = MaterialLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.settingsAiProcessingInfoTitle),
          content: Text(l10n.settingsAiProcessingInfoMessage),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(material.okButtonLabel),
            ),
          ],
        );
      },
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
