import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/core/theme/theme_option_labels.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
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
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: AppQuietSurfaces.pageBackground(colors),
      child: CustomScrollView(
        slivers: [
          if (includeHomeShellChrome)
            HomeShellTabTopChrome(title: l10n.homeSettings),
          SliverPadding(
            padding: responsivePagePadding(
              context,
              top: AppSpacing.xl,
              bottom: homeShellPageBottomPadding(context),
            ),
            sliver: SliverList.list(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: settingsMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SettingsIntro(l10n: l10n),
                        const SizedBox(height: AppSpacing.lg),
                        const SettingsProfileCard(),
                        const SizedBox(height: AppSpacing.lg),
                        SettingsSection(
                          title: l10n.settingsAccountHouseholdSectionTitle,
                          children: [_HouseholdTile(l10n: l10n)],
                        ),
                        SettingsSection(
                          title: l10n.settingsHealthGoalsSectionTitle,
                          children: const [
                            SettingsHealthConnectTile(),
                            _CalorieGoalStartTile(),
                            _CalorieGoalCalculatorTile(),
                          ],
                        ),
                        SettingsSection(
                          title: l10n.settingsAppearanceSectionTitle,
                          children: const [
                            _ThemeModeTile(),
                            _SeedColorTile(),
                            _LanguageTile(),
                          ],
                        ),
                        SettingsSection(
                          title: l10n.settingsAppSectionTitle,
                          children: [
                            SettingsTile(
                              key: SettingsPageKeys.notificationsTile,
                              icon: Icons.notifications_none_rounded,
                              title: l10n.settingsNotificationsTitle,
                              subtitle: l10n.settingsNotificationsSubtitle,
                              onTap: () => _showNotImplementedSnackBar(
                                context,
                                l10n.commonNotImplementedYet,
                              ),
                            ),
                            SettingsTile(
                              key: SettingsPageKeys.privacyTile,
                              icon: Icons.lock_outline_rounded,
                              title: l10n.settingsPrivacyTitle,
                              subtitle: l10n.settingsPrivacySubtitle,
                              onTap: () => _showNotImplementedSnackBar(
                                context,
                                l10n.commonNotImplementedYet,
                              ),
                            ),
                            const _AboutTile(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsManagePreferencesSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CalorieGoalStartTile extends ConsumerWidget {
  const _CalorieGoalStartTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(calorieGoalControllerProvider);
    final settings = settingsState.asData?.value;
    final latestGoal = settings?.latestGoalEntry;
    final hasGoal = latestGoal != null;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final initialGoalStartDate =
        latestGoal?.effectiveCountingStartDate ?? DateTime.now();

    return SettingsTile(
      key: SettingsPageKeys.calorieGoalStartTile,
      icon: Icons.event_note_rounded,
      title: l10n.caloriesShiftGoalStartAction,
      subtitle: hasGoal
          ? dateFormat.format(initialGoalStartDate)
          : l10n.settingsDiaryGoalSetGoalFirst,
      enabled: hasGoal && !settingsState.isLoading,
      onTap: !hasGoal || settingsState.isLoading
          ? null
          : () => unawaited(
              showCalorieGoalStartDialog(
                context: context,
                initialGoalStartDate: initialGoalStartDate,
                onSaveGoalStart: (goalStartDate) {
                  return ref
                      .read(calorieGoalControllerProvider.notifier)
                      .shiftGoalStart(goalStartDate: goalStartDate);
                },
              ),
            ),
    );
  }
}

class _CalorieGoalCalculatorTile extends ConsumerWidget {
  const _CalorieGoalCalculatorTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(calorieGoalControllerProvider);
    final settings = settingsState.asData?.value;

    return SettingsTile(
      key: SettingsPageKeys.calorieGoalCalculatorTile,
      icon: Icons.track_changes_rounded,
      title: l10n.caloriesCalculatorAction,
      subtitle: l10n.caloriesCalculatorOnboardingSubtitle,
      enabled: settings != null && !settingsState.isLoading,
      onTap: settings == null || settingsState.isLoading
          ? null
          : () => unawaited(
              showCalorieGoalCalculatorSheet(
                context,
                initialSettings: settings,
              ),
            ),
    );
  }
}

class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider);

    return SettingsTile(
      key: SettingsPageKeys.aboutTile,
      icon: Icons.info_outline_rounded,
      title: l10n.settingsAboutTitle,
      subtitle: l10n.settingsAboutSubtitle,
      trailing: switch (version) {
        AsyncData(:final value) => KeyedSubtree(
          key: SettingsPageKeys.aboutTrailing,
          child: SettingsTrailingValue(value: value),
        ),
        AsyncLoading() => const KeyedSubtree(
          key: SettingsPageKeys.aboutTrailing,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        AsyncError() => null,
      },
      showChevron: version is! AsyncLoading,
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const _HouseholdTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      key: SettingsPageKeys.householdTile,
      icon: Icons.groups_2_outlined,
      title: l10n.settingsHouseholdTitle,
      subtitle: l10n.settingsHouseholdSubtitle,
      onTap: () => context.push(AppRoutes.homeSettingsHousehold),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeControllerProvider);

    return SettingsTile(
      key: SettingsPageKeys.themeTile,
      icon: Icons.palette_outlined,
      title: l10n.settingsThemeTitle,
      subtitle: localizedThemeModeLabel(l10n, themeMode),
      trailing: SettingsTrailingValue(
        value: localizedThemeModeLabel(l10n, themeMode),
      ),
      onTap: () => _showThemeModeSheet(context, ref, themeMode),
    );
  }

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode selectedMode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: RadioGroup<ThemeMode>(
              groupValue: selectedMode,
              onChanged: (mode) {
                if (mode == null) {
                  return;
                }
                unawaited(
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(mode),
                );
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ThemeMode.values)
                    AppRadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(localizedThemeModeLabel(l10n, mode)),
                    ),
                ],
              ),
            ),
          );
        },
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

    return SettingsTile(
      key: SettingsPageKeys.colorTile,
      icon: Icons.format_paint_outlined,
      title: l10n.settingsColorTitle,
      subtitle: localizedSeedColorLabel(l10n, seedColor),
      trailing: SettingsTrailingValue(
        value: localizedSeedColorLabel(l10n, seedColor),
        swatchColor: seedColor,
      ),
      iconColor: seedColor,
      onTap: () => _showSeedColorSheet(context, ref, seedColor),
    );
  }

  void _showSeedColorSheet(
    BuildContext context,
    WidgetRef ref,
    Color selectedColor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: RadioGroup<int>(
              groupValue: selectedColor.toARGB32(),
              onChanged: (colorValue) {
                if (colorValue == null) {
                  return;
                }
                unawaited(
                  ref
                      .read(seedColorControllerProvider.notifier)
                      .setSeedColor(Color(colorValue)),
                );
                Navigator.of(sheetContext).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in AppSeedColors.values)
                    AppRadioListTile<int>(
                      value: color.toARGB32(),
                      title: Text(localizedSeedColorLabel(l10n, color)),
                      secondary: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final languageLabels = <String, String>{
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode: _localizedLanguageLabel(l10n, locale),
    };
    final language = languageLabels[languageCode] ?? languageCode;

    return SettingsTile(
      key: SettingsPageKeys.languageTile,
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      subtitle: language,
      onTap: () =>
          _showNotImplementedSnackBar(context, l10n.commonNotImplementedYet),
    );
  }
}

String _localizedLanguageLabel(AppLocalizations l10n, Locale locale) {
  return switch (locale.languageCode) {
    'de' => l10n.settingsLanguageGerman,
    'en' => l10n.settingsLanguageEnglish,
    _ => locale.languageCode,
  };
}

void _showNotImplementedSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
