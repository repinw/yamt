import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/widgets/initial_tile.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_debug_menu_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_preview_tiles.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_entry.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content of the home side menu: who is signed in, the app-wide
/// destinations, and in debug builds the Calories debug actions.
class HomeMenuPanel extends ConsumerWidget {
  /// Creates the menu content.
  const new({required this.onClose, super.key});

  /// Closes the menu.
  final VoidCallback onClose;

  /// Stable key of the close button.
  static const closeButtonKey = ValueKey<String>('home-menu-close');

  /// Stable key of the profile entry.
  static const profileTileKey = ValueKey<String>('home-menu-profile-tile');

  /// Stable key of the goal archive entry.
  static const goalArchiveTileKey = ValueKey<String>('home-menu-goals-tile');

  /// Stable key of the household entry.
  static const householdTileKey = ValueKey<String>('home-menu-household-tile');

  /// Stable key of the kitchen utensils entry.
  static const kitchenUtensilsTileKey = ValueKey<String>(
    'home-menu-kitchen-utensils-tile',
  );

  /// Stable key of the shopping list entry.
  static const shoppingTileKey = ValueKey<String>('home-menu-shopping-tile');

  /// Stable key of the settings entry.
  static const settingsTileKey = ValueKey<String>('home-menu-settings-tile');

  /// Stable key of the appearance entry.
  static const appearanceTileKey = ValueKey<String>(
    'home-menu-appearance-tile',
  );

  /// Stable key of the about entry.
  static const aboutTileKey = ValueKey<String>('home-menu-about-tile');

  /// Stable key of the account entry.
  static const accountTileKey = ValueKey<String>('home-menu-account-tile');

  /// Stable key of the collapsible debug section.
  static const debugSectionKey = ValueKey<String>('home-menu-debug-section');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isGuest = ref.watch(
      userProfileProvider.select((profile) => profile.value?.isAnonymous),
    );

    void open(String route) {
      onClose();
      unawaited(context.push(route));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _MenuIdentity()),
                IconButton.filled(
                  key: closeButtonKey,
                  tooltip: l10n.homeMenuClose,
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    foregroundColor: colors.onSurface,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Expanded(
              child: FractionallySizedBox(
                widthFactor: AppSizes.homeSlideMenuContentWidth,
                alignment: Alignment.topLeft,
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                  children: [
                    HomeMenuSection(
                      title: l10n.homeMenuSectionYou,
                      entries: [
                        HomeMenuEntry(
                          key: profileTileKey,
                          icon: Icons.person_outline_rounded,
                          label: l10n.homeProfile,
                          onTap: () => open(AppRoutes.homeProfile),
                        ),
                        HomeMenuEntry(
                          key: goalArchiveTileKey,
                          icon: Icons.flag_outlined,
                          label: l10n.settingsGoalArchiveTitle,
                          onTap: () => open(AppRoutes.homeSettingsGoalArchive),
                        ),
                        HomeMenuEntry(
                          key: householdTileKey,
                          icon: Icons.home_outlined,
                          label: l10n.settingsHouseholdTitle,
                          onTap: () => open(AppRoutes.homeSettingsHousehold),
                        ),
                      ],
                    ),
                    HomeMenuSection(
                      title: l10n.homeMenuSectionKitchen,
                      entries: [
                        HomeMenuEntry(
                          key: kitchenUtensilsTileKey,
                          icon: Icons.soup_kitchen_outlined,
                          label: l10n.kitchenUtensilsPageTitle,
                          onTap: () => open(AppRoutes.homeKitchenUtensils),
                        ),
                        HomeMenuEntry(
                          key: shoppingTileKey,
                          icon: Icons.shopping_cart_outlined,
                          label: l10n.homeShopping,
                          onTap: () => open(AppRoutes.homeShopping),
                        ),
                      ],
                    ),
                    HomeMenuSection(
                      title: l10n.homeMenuSectionApp,
                      entries: [
                        HomeMenuEntry(
                          key: settingsTileKey,
                          icon: Icons.tune_rounded,
                          label: l10n.homeSettings,
                          onTap: () => open(AppRoutes.homeSettings),
                        ),
                        HomeMenuEntry(
                          key: appearanceTileKey,
                          icon: Icons.palette_outlined,
                          label: l10n.settingsAppearanceSectionTitle,
                          onTap: () => open(AppRoutes.homeSettingsAppearance),
                        ),
                        HomeMenuEntry(
                          key: aboutTileKey,
                          icon: Icons.info_outline_rounded,
                          label: l10n.settingsAboutTitle,
                          onTap: () => _showAbout(context, ref),
                        ),
                      ],
                    ),
                    if (kDebugMode)
                      ExpansionTile(
                        key: HomeMenuPanel.debugSectionKey,
                        title: Text(l10n.homeMenuDebugSection),
                        leading: const Icon(Icons.bug_report_outlined),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        children: const [
                          CalorieDebugMenuSection(),
                          DiaryWeeklyCheckInPreviewTiles(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: AppSizes.homeSlideMenuContentWidth,
              child: HomeMenuEntry(
                key: accountTileKey,
                icon: isGuest ?? true
                    ? Icons.link_rounded
                    : Icons.account_circle_outlined,
                label: isGuest ?? true
                    ? l10n.homeMenuLinkAccount
                    : l10n.settingsAccountTitle,
                onTap: () => open(AppRoutes.homeSettingsAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: ref.read(appVersionProvider).value,
    );
  }
}

/// The signed-in user at the top of the menu: a tilted initial, the name,
/// and whether the user is a guest.
class _MenuIdentity extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final account = ref.watch(
      userProfileProvider.select(
        (profile) => (
          name: profile.value?.displayName,
          email: profile.value?.email,
          isGuest: profile.value?.isAnonymous ?? true,
        ),
      ),
    );
    final title = account.name ?? account.email ?? l10n.homeMenuGuest;
    final subtitle = account.isGuest
        ? l10n.homeMenuGuest
        : account.name == null
        ? null
        : account.email;

    return Row(
      children: [
        InitialTile(text: title),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle != title)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
