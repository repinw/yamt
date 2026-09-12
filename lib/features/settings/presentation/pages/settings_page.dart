import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_general_tiles.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_goal_tiles.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_health_connect_tile/settings_health_connect_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_card/settings_profile_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines settings page.
class SettingsPage extends ConsumerWidget {
  /// The settings page.
  const SettingsPage({super.key, this.includeHomeShellChrome = false});

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        if (includeHomeShellChrome)
          HomeShellTabTopChrome(title: l10n.homeSettings),
        SliverPadding(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.xl,
            bottom: homeShellPageBottomPadding(context),
          ),
          sliver: SliverList.list(children: [_content(context, l10n)]),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: settingsMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsIntro(l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            const SettingsProfileCard(),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: l10n.settingsAccountHouseholdSectionTitle,
              children: [SettingsHouseholdTile(l10n: l10n)],
            ),
            SettingsSection(
              title: l10n.settingsHealthGoalsSectionTitle,
              children: const [
                SettingsHealthConnectTile(),
                SettingsCalorieGoalStartTile(),
                SettingsCalorieGoalCalculatorTile(),
                SettingsGoalArchiveTile(),
                SettingsTdeeAnalyticsTile(),
                SettingsMacroGoalsTile(),
                SettingsCalorieGoalIntroTile(),
              ],
            ),
            SettingsSection(
              title: l10n.settingsAppearanceSectionTitle,
              children: const [SettingsLanguageTile()],
            ),
            _appSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _appSection(BuildContext context, AppLocalizations l10n) {
    void notImplemented() => showNotImplementedSettingsSnackBar(
      context,
      l10n.commonNotImplementedYet,
    );
    return SettingsSection(
      title: l10n.settingsAppSectionTitle,
      children: [
        SettingsTile(
          key: SettingsPageKeys.notificationsTile,
          icon: Icons.notifications_none_rounded,
          title: l10n.settingsNotificationsTitle,
          subtitle: l10n.settingsNotificationsSubtitle,
          onTap: notImplemented,
        ),
        SettingsTile(
          key: SettingsPageKeys.privacyTile,
          icon: Icons.lock_outline_rounded,
          title: l10n.settingsPrivacyTitle,
          subtitle: l10n.settingsPrivacySubtitle,
          onTap: notImplemented,
        ),
        const SettingsAboutTile(),
      ],
    );
  }
}
