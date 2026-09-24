import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/debug/calorie_debug_menu_section.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Side menu of the home shell: profile card, settings, and debug actions in
/// debug builds.
class HomeMenuDrawer extends StatelessWidget {
  /// Creates the side menu.
  const new({super.key});

  /// Stable key of the settings entry.
  static const settingsTileKey = ValueKey<String>('home-menu-settings-tile');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SettingsProfileSummaryCard(),
            ),
            ListTile(
              key: settingsTileKey,
              leading: const Icon(Icons.settings_rounded),
              title: Text(l10n.homeSettings),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(context.push(AppRoutes.homeSettings));
              },
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
