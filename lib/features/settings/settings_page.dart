import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onNotImplementedTap(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
  }

  void _openAccountPage(BuildContext context) {
    context.push(AppRoutes.homeSettingsAccount);
  }

  List<Widget> _tiles(AppLocalizations l10n, BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(l10n.settingsAccountTitle),
        subtitle: Text(l10n.settingsAccountSubtitle),
        onTap: () => _openAccountPage(context),
      ),
      ListTile(
        leading: const Icon(Icons.language_outlined),
        title: Text(l10n.settingsLanguageTitle),
        subtitle: Text(l10n.settingsLanguageSubtitle),
        onTap: () => _onNotImplementedTap(context),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(l10n.settingsNotificationsTitle),
        subtitle: Text(l10n.settingsNotificationsSubtitle),
        onTap: () => _onNotImplementedTap(context),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.settingsAboutTitle),
        subtitle: Text(l10n.settingsAboutSubtitle),
        onTap: () => _onNotImplementedTap(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = _tiles(l10n, context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }
}
