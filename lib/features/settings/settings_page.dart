import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l10n.settingsAccountTitle),
          subtitle: Text(l10n.settingsAccountSubtitle),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: Text(l10n.settingsLanguageTitle),
          subtitle: Text(l10n.settingsLanguageSubtitle),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l10n.settingsNotificationsTitle),
          subtitle: Text(l10n.settingsNotificationsSubtitle),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.settingsAboutTitle),
          subtitle: Text(l10n.settingsAboutSubtitle),
        ),
      ],
    );
  }
}
