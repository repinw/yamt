import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onTileTap(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
  }

  List<Widget> _tiles(AppLocalizations l10n, BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.settingsAccountTitle),
        subtitle: Text(l10n.settingsAccountSubtitle),
        onTap: () => _onTileTap(context),
      ),
      ListTile(
        leading: const Icon(Icons.language_outlined),
        title: Text(l10n.settingsLanguageTitle),
        subtitle: Text(l10n.settingsLanguageSubtitle),
        onTap: () => _onTileTap(context),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(l10n.settingsNotificationsTitle),
        subtitle: Text(l10n.settingsNotificationsSubtitle),
        onTap: () => _onTileTap(context),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settingsAboutTitle),
        subtitle: Text(l10n.settingsAboutSubtitle),
        onTap: () => _onTileTap(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = _tiles(l10n, context);

    return Material(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: tiles.length,
        itemBuilder: (context, index) => tiles[index],
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }
}
