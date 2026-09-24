import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/debug/calorie_debug_menu_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Side menu of the home shell: profile, settings, and debug actions in debug
/// builds.
class HomeMenuDrawer extends StatelessWidget {
  /// Creates the side menu.
  const new({super.key});

  /// Stable key of the profile entry.
  static const profileTileKey = ValueKey<String>('home-menu-profile-tile');

  /// Stable key of the settings entry.
  static const settingsTileKey = ValueKey<String>('home-menu-settings-tile');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            _MenuRouteTile(
              key: profileTileKey,
              icon: Icons.person_rounded,
              title: l10n.homeProfile,
              route: AppRoutes.homeProfile,
            ),
            _MenuRouteTile(
              key: settingsTileKey,
              icon: Icons.settings_rounded,
              title: l10n.homeSettings,
              route: AppRoutes.homeSettings,
            ),
            if (kDebugMode) ...[
              const Divider(),
              const CalorieDebugMenuSection(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Menu entry that closes the menu and pushes [route].
class _MenuRouteTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();
        unawaited(context.push(route));
      },
    );
  }
}
