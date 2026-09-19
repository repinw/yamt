import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_start_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_health_connect_tile/settings_health_connect_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_language_tile/settings_language_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_card/settings_profile_card.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines settings page.
class SettingsPage extends ConsumerWidget {
  /// The settings page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeSettings)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: responsivePagePadding(
              context,
              top: AppSpacing.xl,
              bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
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
                            _MacroGoalsTile(),
                          ],
                        ),
                        SettingsSection(
                          title: l10n.settingsAppearanceSectionTitle,
                          children: const [SettingsLanguageTile()],
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
  const new({required this.l10n});

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
  const new();

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
        latestGoal?.effectiveCountingStartDate ?? ref.watch(clockProvider)();

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
  const new();

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

class _MacroGoalsTile extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsTile(
      key: SettingsPageKeys.macroGoalsTile,
      icon: Icons.pie_chart_outline_rounded,
      title: l10n.settingsMacroGoalsTitle,
      subtitle: l10n.settingsMacroGoalsSubtitle,
      onTap: () => unawaited(showSettingsMacroGoalsSheet(context)),
    );
  }
}

class _AboutTile extends ConsumerWidget {
  const new();

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
          child: SizedBox.square(
            dimension: AppSizes.smallProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
        AsyncError() => null,
      },
      showChevron: version is! AsyncLoading,
    );
  }
}

class _HouseholdTile extends StatelessWidget {
  const new({required this.l10n});

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

void _showNotImplementedSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
